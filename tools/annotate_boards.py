"""Draw every Player Board's snap points on top of its image, numbered, for checking by eye.

Usage (run from the repository root):
    python tools/annotate_boards.py                  all boards
    python tools/annotate_boards.py --only Exiles    boards whose race name contains "Exiles"

Writes to board-maps/ (committed, except images/):
    index.html             all boards on one page, with a table of snap points per board
    <race>.svg             one board with its snap points drawn and numbered
    images/<guid>.<ext>    downloaded board images, used to read their size (git-ignored cache)

The SVGs link to the board images on Steam's servers rather than embedding them, so the
committed files stay small and don't copy the board artwork. Viewing needs an internet
connection. Pass --embed for self-contained SVGs (large; don't commit those).

Numbers are the Lua snap point index: board.getSnapPoints()[n] in game (1-based,
same order as AttachedSnapPoints in the mod file).
Every snap point is drawn and numbered. The colour shows its first tag (see TAG_COLOURS,
and the legend in index.html): cyan for untagged points (blueprint slots, tech tracks),
orange for Influence, and so on. Hover a point for its position and all its tags.
Dashed hollow circles are "Unused" placeholders (slots a race doesn't have).

Mapping from board-local coordinates to image pixels, measured on the boards:
local z runs -1..1 over the image height, local x is mirrored (+x is the image's left),
and one local unit is half the image height in pixels.
"""
import argparse
import base64
import html
import json
import os
import re
import struct
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_MOD = os.path.join(ROOT, '2348417296.json')
DEFAULT_OUT = os.path.join(ROOT, 'board-maps')


def walk(objects):
    for obj in objects:
        yield obj
        yield from walk(obj.get('ContainedObjects') or [])


def player_boards(mod):
    boards = [o for o in walk(mod['ObjectStates'])
              if 'PlayerBoard' in (o.get('Tags') or []) or o.get('Nickname') == 'Player Board']
    return sorted(boards, key=lambda o: race_name(o).lower())


def race_name(board):
    return (board.get('Description') or board.get('GUID')).strip()


def image_size(data):
    """(width, height) of a PNG or JPEG, from its header."""
    if data[:8] == b'\x89PNG\r\n\x1a\n':
        return struct.unpack('>II', data[16:24])
    if data[:2] == b'\xff\xd8':
        i = 2
        while i < len(data):
            if data[i] != 0xFF:
                i += 1
                continue
            marker = data[i + 1]
            if marker in (0xD8, 0x01) or 0xD0 <= marker <= 0xD7:
                i += 2
                continue
            length = struct.unpack('>H', data[i + 2:i + 4])[0]
            if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
                height, width = struct.unpack('>HH', data[i + 5:i + 9])
                return width, height
            i += 2 + length
    raise ValueError('not a PNG or JPEG image')


def fetch_image(url, cache_dir, guid):
    for ext in ('jpg', 'png'):
        path = os.path.join(cache_dir, f'{guid}.{ext}')
        if os.path.exists(path):
            with open(path, 'rb') as f:
                return f.read(), ext
    request = urllib.request.Request(url, headers={'User-Agent': 'tts-board-annotator'})
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()
    ext = 'png' if data[:4] == b'\x89PNG' else 'jpg'
    image_size(data)  # refuse anything that is not an image
    with open(os.path.join(cache_dir, f'{guid}.{ext}'), 'wb') as f:
        f.write(data)
    return data, ext


# fill colour by a snap point's first tag; None = untagged
TAG_COLOURS = {
    None: '#00e5ff',
    'Influence': '#ffa726',
    'Reputation': '#ff6ec7',
    'Ambassador': '#b388ff',
    'TechTile': '#ffee58',
    'Discovery': '#ff5252',
    'Population': '#76ff03',
}
UNUSED = 'Unused'  # placeholder for a slot the race doesn't have; drawn hollow
OTHER_COLOUR = '#bdbdbd'

# snap point groups, by Lua index (see CLAUDE.md, "Snap point convention")
SNAP_GROUPS = [
    (1, 6, 'Action (EXP, RES, UPG, BUI, MOV, INF)'),
    (7, 10, 'Interceptor slot'), (11, 11, 'Interceptor Muon Source'),
    (12, 17, 'Cruiser slot'), (18, 18, 'Cruiser Muon Source'),
    (19, 26, 'Dreadnought slot'), (27, 27, 'Dreadnought Muon Source'),
    (28, 32, 'Starbase / Orbital slot'), (33, 33, 'Starbase / Orbital Muon Source'),
    (34, 46, 'Influence track'),
    (47, 53, 'Military tech'), (54, 60, 'Grid tech'), (61, 67, 'Nano tech'),
    (68, 72, 'Reputation / ambassador'), (73, 73, 'Discovery'),
]


def snap_group(index):
    for first, last, name in SNAP_GROUPS:
        if first <= index <= last:
            return f'{name} {index - first + 1}' if last > first else name
    return 'race-specific extra'


def tag_colour(tags):
    key = tags[0] if tags else None
    return TAG_COLOURS.get(key, OTHER_COLOUR)


def to_pixels(position, width, height):
    half = height / 2
    return width / 2 - position['x'] * half, height / 2 + position['z'] * half


def board_svg(board, data, ext, url, embed):
    width, height = image_size(data)
    radius = height * 0.018
    font = height * 0.022
    if embed:
        href = f'data:image/{"png" if ext == "png" else "jpeg"};base64,' + base64.b64encode(data).decode('ascii')
    else:
        href = html.escape(url)
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'width="{width}" height="{height}">',
        f'<title>{html.escape(race_name(board))} ({board["GUID"]})</title>',
        f'<image href="{href}" x="0" y="0" width="{width}" height="{height}"/>',
    ]
    for index, snap in enumerate(board.get('AttachedSnapPoints') or [], start=1):
        x, y = to_pixels(snap['Position'], width, height)
        tags = snap.get('Tags') or []
        tip = (f'#{index} {snap_group(index)}  '
               f'x={snap["Position"]["x"]:.3f} z={snap["Position"]["z"]:.3f}')
        if tags:
            tip += '  tags: ' + ', '.join(tags)
        if UNUSED in tags:
            parts.append(
                f'<g><title>{html.escape(tip)} (placeholder)</title>'
                f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{radius * 0.8:.1f}" fill="none" stroke="#bdbdbd" '
                f'stroke-width="{radius * 0.12:.1f}" stroke-dasharray="{radius * 0.3:.1f} {radius * 0.2:.1f}"/>'
                f'<text x="{x:.1f}" y="{y:.1f}" font-family="Arial, sans-serif" font-weight="bold" '
                f'font-size="{font * 0.75:.1f}" text-anchor="middle" dominant-baseline="central" '
                f'fill="#e0e0e0" stroke="#000" stroke-width="{font * 0.05:.1f}">{index}</text></g>')
            continue
        parts.append(
            f'<g><title>{html.escape(tip)}</title>'
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{radius:.1f}" fill="{tag_colour(tags)}" fill-opacity="0.85" '
            f'stroke="#000" stroke-width="{radius * 0.12:.1f}"/>'
            f'<text x="{x:.1f}" y="{y:.1f}" font-family="Arial, sans-serif" font-weight="bold" '
            f'font-size="{font:.1f}" text-anchor="middle" dominant-baseline="central" '
            f'fill="#000">{index}</text></g>')
    parts.append('</svg>')
    return '\n'.join(parts)


def snap_table(board):
    rows = []
    for index, snap in enumerate(board.get('AttachedSnapPoints') or [], start=1):
        p = snap['Position']
        rows.append(f'<tr><td>{index}</td><td>{html.escape(snap_group(index))}</td>'
                    f'<td>{p["x"]:.3f}</td><td>{p["z"]:.3f}</td>'
                    f'<td>{html.escape(", ".join(snap.get("Tags") or []))}</td></tr>')
    return ('<table><tr><th>#</th><th>group</th><th>x</th><th>z</th><th>tags</th></tr>' + ''.join(rows) + '</table>')


def legend(seen_tags):
    keys = [None] + sorted(t for t in seen_tags if t not in (None, UNUSED))
    items = ''.join(
        f'<span class="key"><span class="dot" style="background:{tag_colour([key] if key else [])}"></span>'
        f'{html.escape(key or "untagged")}</span>' for key in keys)
    items += ('<span class="key"><span class="dot" style="background:none;border:2px dashed #bdbdbd">'
              '</span>Unused (placeholder for a slot this race doesn\'t have)</span>')
    return f'<p class="legend">{items}</p>'


def safe_name(name):
    return re.sub(r'[^A-Za-z0-9]+', '_', name).strip('_')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--mod', default=DEFAULT_MOD, help='mod JSON file (default: %(default)s)')
    parser.add_argument('--out', default=DEFAULT_OUT, help='output folder (default: %(default)s)')
    parser.add_argument('--only', help='only boards whose race name contains this text')
    parser.add_argument('--embed', action='store_true',
                        help='embed the images in the SVGs instead of linking to them (large files)')
    args = parser.parse_args()

    with open(args.mod, encoding='utf-8') as f:
        mod = json.load(f)
    image_dir = os.path.join(args.out, 'images')
    os.makedirs(image_dir, exist_ok=True)

    sections = []
    seen_tags = set()
    for board in player_boards(mod):
        name = race_name(board)
        if args.only and args.only.lower() not in name.lower():
            continue
        url = (board.get('CustomImage') or {}).get('ImageURL')
        if not url:
            print(f'skip {name} ({board["GUID"]}): no image URL', file=sys.stderr)
            continue
        try:
            data, ext = fetch_image(url, image_dir, board['GUID'])
        except Exception as error:  # keep going with the other boards
            print(f'skip {name} ({board["GUID"]}): {error}', file=sys.stderr)
            continue
        svg_name = f'{safe_name(name)}.svg'
        svg = board_svg(board, data, ext, url, args.embed)
        with open(os.path.join(args.out, svg_name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg)
        count = len(board.get('AttachedSnapPoints') or [])
        seen_tags.update((snap.get('Tags') or [None])[0] for snap in board.get('AttachedSnapPoints') or [])
        print(f'{name:<24} {board["GUID"]}  {count:>3} snap points  -> {svg_name}')
        sections.append(
            f'<section id="{board["GUID"]}"><h2>{html.escape(name)} <small>{board["GUID"]}</small></h2>'
            f'<a class="board" href="{svg_name}">{svg[svg.index("<svg"):]}</a>'
            f'<details><summary>Snap points ({count})</summary>{snap_table(board)}</details></section>')

    page = ('<!doctype html><html><head><meta charset="utf-8"><title>Player board snap points</title>'
            '<style>body{font-family:sans-serif;background:#222;color:#eee;margin:1em}'
            '.board svg{width:100%;max-width:1600px;height:auto;display:block}section{margin-bottom:3em}small{color:#999}'
            'table{border-collapse:collapse;font-size:13px}td,th{border:1px solid #555;padding:2px 8px}'
            'a{color:#7df}.key{margin-right:1.5em;white-space:nowrap}'
            '.dot{display:inline-block;width:1em;height:1em;border-radius:50%;border:1px solid #000;'
            'vertical-align:middle;margin-right:.4em}</style></head><body><h1>Player board snap points</h1>'
            '<p>Numbers are <code>getSnapPoints()[n]</code>. Colour = first tag of the snap point '
            '(hover a point for all its tags). Click a board to open it full size.</p>'
            + legend(seen_tags) + ''.join(sections) + '</body></html>')
    with open(os.path.join(args.out, 'index.html'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(page)
    print(f'\nOpen {os.path.join(args.out, "index.html")}')


if __name__ == '__main__':
    main()
