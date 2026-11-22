"""Draw reference sheets of everything that can go on a ship, for browsing what exists.

Usage (run from the repository root):
    python tools/reference_sheets.py            write reference/*.svg
    python tools/reference_sheets.py --embed    embed the images (large; don't commit)

Writes (committed):
    reference/ship-parts.svg    every ship part tile in the mod (tag ShipPart)
    reference/ancient-tech.svg  every Discovery tile that is a ship part (ancient technology)
    reference/npc-ships.svg     every Ancient, Guardian and GCDS variant

Each card shows the tile and, under it, the stats recorded for it in
scripts/include/ShipData.ttslua, so the printed tile and our data can be compared at a glance.
Like board-maps/, the images are linked from Steam's servers (viewing needs internet).
"""
import argparse
import base64
import html
import json
import os
import re
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from annotate_boards import DEFAULT_MOD, walk  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHIP_DATA = os.path.join(ROOT, 'scripts', 'include', 'ShipData.ttslua')
OUT = os.path.join(ROOT, 'reference')

COLUMNS, CARD_W, CARD_H, IMAGE = 5, 300, 330, 220


def lua_table(text, name):
    """The body of a top-level `NAME = { ... }` table in ShipData.ttslua (up to its closing line)."""
    match = re.search(r'^' + name + r'\s*=\s*\{\n(.*?)^\}', text, re.M | re.S)
    if not match:
        sys.exit(f'{name} not found in {SHIP_DATA}')
    return match.group(1)


def entries(body):
    """name -> one-line `{...}` value of each `["name"] = {...}` line."""
    return dict(re.findall(r'^\s*\["([^"]+)"\]\s*=\s*(\{.*\}),?\s*(?:--.*)?$', body, re.M))


def textures(body):
    """texture URL -> name of each `["url"] = "name"` line."""
    return dict(re.findall(r'^\s*\["(https?://[^"]+)"\]\s*=\s*"([^"]+)"', body, re.M))


def read_ship_data():
    """(part name -> stats, discovery texture -> part name, NPC variant -> stats, NPC texture -> variant)."""
    text = open(SHIP_DATA, encoding='utf-8').read()
    return (entries(lua_table(text, 'SHIP_PARTS')), textures(lua_table(text, 'DISCOVERY_PARTS')),
            entries(lua_table(text, 'NPC_SHIPS')), textures(lua_table(text, 'NPC_TEXTURES')))


def describe(body):
    """Short stats text from a SHIP_PARTS entry, e.g. '1 orange die (2 dmg) · energy -2'."""
    pieces = []
    for kind in ('missiles', 'cannons'):
        match = re.search(kind + r'\s*=\s*\{(.*?\})\s*\}', body)
        if match:
            for die in re.findall(r'\{([^{}]*)\}', match.group(1)):
                fields = dict(re.findall(r'(\w+)\s*=\s*"?([\w.-]+)"?', die))
                count = int(fields.get('count', 1))
                dmg = 'rift' if fields.get('rift') == 'true' else f'{fields.get("damage")} dmg'
                if kind == 'missiles':
                    label = 'missile' if count == 1 else 'missiles'
                else:
                    label = 'die' if count == 1 else 'dice'
                pieces.append(f'{count} {fields["color"]} {label} ({dmg})')
    for field, label in (('initiative', 'init'), ('computer', 'computer'), ('shield', 'shield'),
                         ('hull', 'hull'), ('movement', 'move'), ('energy', 'energy')):
        match = re.search(r'\b' + field + r'\s*=\s*(-?\d+)', body)
        if match:
            value = int(match.group(1))
            sign = '+' if value > 0 and field in ('initiative', 'computer', 'energy') else ''
            pieces.append(f'{label} {sign}{value}')
    for flag, label in (('jump', 'jump drive'), ('regenerate', 'regenerates')):
        if re.search(r'\b' + flag + r'\s*=\s*true', body):
            pieces.append(label)
    return ' · '.join(pieces) or '(no stats)'


def image_href(url, embed, cache):
    if not embed:
        return html.escape(url)
    if url not in cache:
        request = urllib.request.Request(url, headers={'User-Agent': 'tts-reference-sheets'})
        data = urllib.request.urlopen(request, timeout=60).read()
        cache[url] = 'data:image/jpeg;base64,' + base64.b64encode(data).decode('ascii')
    return cache[url]


def wrap(text, width=34):
    lines, line = [], ''
    for word in text.split(' '):
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = word
        else:
            line = f'{line} {word}' if line else word
    return lines + [line] if line else lines


def sheet(title, cards, embed, cache):
    """cards: list of (name, stats text, image url, texture quarter or None)."""
    rows = (len(cards) + COLUMNS - 1) // COLUMNS
    width, height = COLUMNS * CARD_W, 60 + rows * CARD_H
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">',
           f'<rect width="100%" height="100%" fill="#222"/>',
           f'<text x="20" y="40" font-family="Arial, sans-serif" font-size="28" font-weight="bold" fill="#fff">'
           f'{html.escape(title)}</text>']
    for i, (name, stats, url, quarter) in enumerate(cards):
        x = (i % COLUMNS) * CARD_W + (CARD_W - IMAGE) // 2
        y = 60 + (i // COLUMNS) * CARD_H + 10
        href = image_href(url, embed, cache)
        if quarter:  # Discovery textures: the tile front is the top-left quarter of the texture
            out.append(f'<svg x="{x}" y="{y}" width="{IMAGE}" height="{IMAGE}" viewBox="0 0 1 1">'
                       f'<image href="{href}" x="0" y="0" width="2" height="2"/></svg>')
        else:
            out.append(f'<image href="{href}" x="{x}" y="{y}" width="{IMAGE}" height="{IMAGE}"/>')
        cx = x + IMAGE // 2
        out.append(f'<text x="{cx}" y="{y + IMAGE + 28}" font-family="Arial, sans-serif" font-size="20" '
                   f'font-weight="bold" fill="#ffeb3b" text-anchor="middle">{html.escape(name)}</text>')
        for n, line in enumerate(wrap(stats)):
            out.append(f'<text x="{cx}" y="{y + IMAGE + 52 + n * 20}" font-family="Arial, sans-serif" '
                       f'font-size="16" fill="#ddd" text-anchor="middle">{html.escape(line)}</text>')
    out.append('</svg>')
    return '\n'.join(out) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--mod', default=DEFAULT_MOD, help='mod JSON file (default: %(default)s)')
    parser.add_argument('--out', default=OUT, help='output folder (default: %(default)s)')
    parser.add_argument('--embed', action='store_true', help='embed the images instead of linking them')
    args = parser.parse_args()

    with open(args.mod, encoding='utf-8') as f:
        mod = json.load(f)
    parts, discoveries, npcs, npc_textures = read_ship_data()
    objects = list(walk(mod['ObjectStates']))

    tiles = {}
    for obj in objects:
        if 'ShipPart' in (obj.get('Tags') or []):
            tiles.setdefault(obj['Nickname'], (obj.get('CustomImage') or {}).get('ImageURL'))
    ship_cards = [(name, describe(parts[name]) if name in parts else 'NOT IN ShipData', url, False)
                  for name, url in sorted(tiles.items())]

    textures = {(obj.get('CustomMesh') or {}).get('DiffuseURL') for obj in objects if obj.get('Nickname') == 'Discovery'}
    ancient_cards = sorted((name, describe(parts[name]) if name in parts else 'NOT IN ShipData', url, True)
                           for url, name in discoveries.items() if url in textures)
    missing = sorted(set(discoveries) - textures)
    if missing:
        print('warning: DISCOVERY_PARTS textures not found in the mod: ' + ', '.join(missing), file=sys.stderr)

    # NPC textures: the miniature's top is the top-left quarter, like Discovery tiles
    mod_textures = {(obj.get('CustomMesh') or {}).get('DiffuseURL') for obj in objects}
    order = list(npcs)  # ShipData order: plain variant first, NPC by NPC
    npc_cards = sorted(((name, describe(npcs[name]) if name in npcs else 'NOT IN ShipData', url, True)
                        for url, name in npc_textures.items() if url in mod_textures),
                       key=lambda card: order.index(card[0]) if card[0] in order else len(order))
    missing = sorted(set(npc_textures) - mod_textures)
    if missing:
        print('warning: NPC_TEXTURES not found in the mod: ' + ', '.join(missing), file=sys.stderr)

    os.makedirs(args.out, exist_ok=True)
    cache = {}
    for file_name, title, cards in (
            ('ship-parts.svg', f'Ship parts ({len(ship_cards)} tiles)', ship_cards),
            ('ancient-tech.svg', f'Ancient technology: Discovery tiles that are ship parts ({len(ancient_cards)})',
             ancient_cards),
            ('npc-ships.svg', f'NPC ships: Ancients, Guardians, GCDS ({len(npc_cards)} variants)', npc_cards)):
        with open(os.path.join(args.out, file_name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(sheet(title, cards, args.embed, cache))
        print(f'{file_name:<18} {len(cards)} cards')


if __name__ == '__main__':
    main()
