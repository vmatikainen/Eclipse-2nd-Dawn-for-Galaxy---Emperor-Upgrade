"""Draw reference sheets of everything that can go on a ship, for browsing what exists.

Usage (run from the repository root):
    python tools/reference_sheets.py            write reference/*.svg
    python tools/reference_sheets.py --embed    embed the images (large; don't commit)

Writes (committed):
    reference/ship-parts.svg    every ship part tile in the mod (tag ShipPart)
    reference/ancient-tech.svg  every Discovery tile: the ship parts (ancient technology), then the
                                others (resources, Ancient ..., scoring tiles)
    reference/npc-ships.svg     every Ancient, Guardian and GCDS variant
    reference/homeworlds.svg    every faction's homeworld tile, with its VP and artifacts
                                (SECTOR_VP in scripts/include/ScoreData.ttslua)

Each card shows the tile and, under it, the stats recorded for it in
scripts/include/ShipData.ttslua (Discovery tiles that aren't ship parts: what
scripts/include/ScoreData.ttslua records), so the printed tile and our data can be compared at a glance.
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
SCORE_DATA = os.path.join(ROOT, 'scripts', 'include', 'ScoreData.ttslua')
OUT = os.path.join(ROOT, 'reference')

COLUMNS, CARD_W, CARD_H, IMAGE = 5, 300, 330, 220


def lua_table(text, name, path=SHIP_DATA):
    """The body of a top-level `NAME = { ... }` table in a data file (up to its closing line)."""
    match = re.search(r'^' + name + r'\s*=\s*\{\n(.*?)^\}', text, re.M | re.S)
    if not match:
        sys.exit(f'{name} not found in {path}')
    return match.group(1)


# what each kind of Discovery tile (ScoreData's DISCOVERY_TILES `type`) does, for the card
DISCOVERY_EFFECTS = {
    'artifact_codex': 'kept front up: 1 VP per artifact in your sectors',
    'ancient_might': 'kept front up: 1 VP per 3 VP of your Reputation tiles',
    'ancient_warp_portal': 'placed in its sector: {vp} VP to the sector\'s holder',
    'ancient_monolith': 'places a Monolith',
    'ancient_orbital': 'places an Orbital',
    'ancient_cruiser': 'places a Cruiser',
    'ancient_tech': 'cheapest tech for free',
    'resources': 'resources',
}


def read_discovery_tiles():
    """texture URL -> (name, effect text) of each Discovery tile in ScoreData that isn't a ship part."""
    text = open(SCORE_DATA, encoding='utf-8').read()
    kept = re.search(r'^DISCOVERY_KEPT_VP\s*=\s*(\d+)', text, re.M)
    tiles = {}
    for url, body in re.findall(r'^\s*\["(https?://[^"]+)"\]\s*=\s*\{(.*)\},?\s*$',
                                lua_table(text, 'DISCOVERY_TILES', SCORE_DATA), re.M):
        fields = {key: quoted or bare for key, quoted, bare
                  in re.findall(r'(\w+)\s*=\s*(?:"([^"]*)"|([^,\s]+))', body)}
        effect = DISCOVERY_EFFECTS.get(fields.get('type'), fields.get('type', '?')).format(vp=fields.get('vp', '?'))
        tiles[url] = (fields.get('name', '?'), effect)
    return tiles, int(kept.group(1)) if kept else None


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


def read_sector_vp():
    """(sector number -> (vp, artifacts), Description -> sector number) from ScoreData."""
    text = open(SCORE_DATA, encoding='utf-8').read()
    vp = {int(n): (int(v), int(a)) for n, v, a in re.findall(
        r'\[(\d+)\]\s*=\s*\{\s*vp\s*=\s*(\d+),\s*artifacts\s*=\s*(\d+)\s*\}',
        lua_table(text, 'SECTOR_VP', SCORE_DATA))}
    by_description = {d: int(n) for d, n in re.findall(
        r'\["([^"]+)"\]\s*=\s*(\d+)', lua_table(text, 'SECTOR_NUMBER_BY_DESCRIPTION', SCORE_DATA))}
    return vp, by_description


def with_bags(objects, bag=''):
    """(object, nickname of the bag it is in) for every object, nested ones included."""
    for obj in objects:
        yield obj, bag
        yield from with_bags(obj.get('ContainedObjects') or [], obj.get('Nickname', ''))


def homeworld_cards(mod):
    """One card per homeworld tile in the mod (Pyxis Unity left out: deprecated), named after
    the faction's bag ("The Exiles Tiles"), since some Descriptions are only a number."""
    vp, by_description = read_sector_vp()
    cards = []
    for obj, bag in with_bags(mod['ObjectStates']):
        if obj.get('Name') != 'Custom_Tile' or 'Homeworld' not in obj.get('Nickname', ''):
            continue
        description = (obj.get('Description') or '').strip()
        if description.startswith('Pyxis Unity'):
            continue
        match = re.search(r'(\d+)$', description)
        number = int(match.group(1)) if match else by_description.get(description)
        faction = re.sub(r'\s+Tiles$', '', bag) or re.sub(r'\s*\d+$', '', description) or obj['Nickname']
        if number in vp:
            points, artifacts = vp[number]
            stats = f'{points} VP · {artifacts} artifact' + ('' if artifacts == 1 else 's')
        else:
            stats = 'NOT IN ScoreData'
        title = f'{number:03d} {faction}' if number is not None else faction
        cards.append((number or 0, title, stats, (obj.get('CustomImage') or {}).get('ImageURL')))
    return [(title, stats, url, False) for _, title, stats, url in sorted(cards)]


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
    # the other Discovery tiles (ScoreData), then any texture neither file knows
    others, kept_vp = read_discovery_tiles()
    other_cards = sorted(((name, effect, url, True) for url, (name, effect) in others.items() if url in textures),
                         key=lambda card: (card[1] == 'resources', card[0]))
    missing = sorted(set(others) - textures)
    if missing:
        print('warning: DISCOVERY_TILES textures not found in the mod: ' + ', '.join(missing), file=sys.stderr)
    unknown = sorted(textures - set(discoveries) - set(others))
    other_cards += [('UNKNOWN', 'not in ShipData or ScoreData', url, True) for url in unknown]
    discovery_cards = ancient_cards + other_cards

    # NPC textures: the miniature's top is the top-left quarter, like Discovery tiles
    mod_textures = {(obj.get('CustomMesh') or {}).get('DiffuseURL') for obj in objects}
    order = list(npcs)  # ShipData order: plain variant first, NPC by NPC
    npc_cards = sorted(((name, describe(npcs[name]) if name in npcs else 'NOT IN ShipData', url, True)
                        for url, name in npc_textures.items() if url in mod_textures),
                       key=lambda card: order.index(card[0]) if card[0] in order else len(order))
    missing = sorted(set(npc_textures) - mod_textures)
    if missing:
        print('warning: NPC_TEXTURES not found in the mod: ' + ', '.join(missing), file=sys.stderr)

    homeworlds = homeworld_cards(mod)

    os.makedirs(args.out, exist_ok=True)
    cache = {}
    for file_name, title, cards in (
            ('ship-parts.svg', f'Ship parts ({len(ship_cards)} tiles)', ship_cards),
            ('ancient-tech.svg', f'Discovery tiles: {len(ancient_cards)} ship parts, {len(other_cards)} others'
                                 f' (every back: {kept_vp} VP when kept)', discovery_cards),
            ('npc-ships.svg', f'NPC ships: Ancients, Guardians, GCDS ({len(npc_cards)} variants)', npc_cards),
            ('homeworlds.svg', f'Homeworlds ({len(homeworlds)}): VP and artifacts recorded in ScoreData', homeworlds)):
        with open(os.path.join(args.out, file_name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(sheet(title, cards, args.embed, cache))
        print(f'{file_name:<18} {len(cards)} cards')


if __name__ == '__main__':
    main()
