"""Put every Player Board's snap points into one canonical order (see CLAUDE.md, "Snap point
convention").

Usage (run from the repository root):
    python tools/normalize_board_snaps.py           rewrite the boards in the mod file
    python tools/normalize_board_snaps.py --check   exit code 1 if any board is not normalized

What it does to each board (Pyxis Unity is skipped, it is deprecated):
  - orders the existing snap points into the fixed ranges below; positions, rotations and tags
    of existing points are kept as they are
  - adds the Muon Source points, and any missing tech track spaces (printed start techs)
  - fills slots the race doesn't have with placeholder points tagged "Unused"; nothing has
    that tag, so nothing snaps to them
  - keeps anything it doesn't recognise (e.g. Lyra's points for its secondary board) at 74+

Only the boards' AttachedSnapPoints arrays change; the rest of the mod file stays byte-for-byte
identical. Running it again on a normalized board changes nothing.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from annotate_boards import DEFAULT_MOD, player_boards, race_name  # noqa: E402

UNUSED = 'Unused'
SKIP_RACES = {'Pyxis Unity'}
MATCH = 0.06  # max distance (board-local units) between a snap point and its canonical spot

# ---- canonical layout, board-local (x, z); measured on the Terran Directorate board ----------
# Blueprint cells go column by column, top to bottom, as printed on a standard board.
CELLS = {
    'Interceptor': [(1.608, -0.537), (1.379, -0.720), (1.378, -0.489), (1.151, -0.536)],
    'Cruiser': [(0.785, -0.626), (0.786, -0.398), (0.556, -0.720), (0.557, -0.489),
                (0.328, -0.627), (0.327, -0.396)],
    'Dreadnought': [(-0.062, -0.626), (-0.063, -0.396), (-0.292, -0.719), (-0.293, -0.489),
                    (-0.521, -0.719), (-0.521, -0.490), (-0.750, -0.625), (-0.749, -0.396)],
    'Starbase': [(-1.112, -0.720), (-1.111, -0.489), (-1.340, -0.606), (-1.569, -0.719),
                 (-1.568, -0.490)],
}
MUON = {
    'Interceptor': (1.083, -0.857),
    'Cruiser': (0.269, -0.866),
    'Dreadnought': (-0.806, -0.866),
    'Starbase': (-1.343, -0.821),
}
SHIPS = ['Interceptor', 'Cruiser', 'Dreadnought', 'Starbase']
TECH_COLUMNS = [0.466, 0.176, -0.109, -0.392, -0.676, -0.961, -1.245]  # space 1..7, left to right
TECH_ROWS = [-0.049, 0.262, 0.574]                                      # Military, Grid, Nano
REPUTATION = [(-1.625, -0.22), (-1.625, 0.04), (-1.625, 0.31), (-1.625, 0.57), (-1.625, 0.84)]
DISCOVERY = (-0.463, -0.206)


def race_layout(race):
    """Per ship: list of (x, z, real) for its cells, and the Muon Source spot (x, z, real)."""
    layout = {}
    for ship in SHIPS:
        layout[ship] = {'cells': [(x, z, True) for x, z in CELLS[ship]], 'muon': (*MUON[ship], True)}

    def missing(ship, *cells):  # 1-based cell numbers the race doesn't have
        layout[ship]['cells'] = [(x, z, real and (i + 1) not in cells)
                                 for i, (x, z, real) in enumerate(layout[ship]['cells'])]

    if race == 'Planta':  # printed bonus boxes where other races have a slot
        missing('Interceptor', 3)
        missing('Cruiser', 2)
        missing('Dreadnought', 2)
        missing('Starbase', 2)
    elif race == 'The Exiles':  # Orbital: Hull (2), Ion Turret (3), Electron Computer (4)
        missing('Starbase', 1, 5)
    elif race == 'Rho Indi':  # Cruiser printed in the middle of the board, no Dreadnought
        layout['Cruiser'] = {'cells': [(x - 0.557, z, True) for x, z in CELLS['Cruiser']],
                             'muon': (-0.295, -0.866, True)}
        missing('Dreadnought', *range(1, 9))
        layout['Dreadnought']['muon'] = (*MUON['Dreadnought'], False)
    return layout


# ---- helpers ------------------------------------------------------------------------------------
def tags(snap):
    return snap.get('Tags') or []


def xz(snap):
    return snap['Position']['x'], snap['Position']['z']


def dist(a, b):
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5


def new_point(x, z, y, point_tags=None):
    snap = {'Position': {'x': round(x, 4), 'y': y, 'z': round(z, 4)}}
    if point_tags:
        snap['Tags'] = list(point_tags)
    return snap


def take_nearest(pool, spot):
    """Remove and return the point in pool closest to spot, if within MATCH."""
    best = min(pool, key=lambda s: dist(xz(s), spot), default=None)
    if best is not None and dist(xz(best), spot) <= MATCH:
        pool.remove(best)
        return best
    return None


# ---- normalization ------------------------------------------------------------------------------
def normalize(board):
    """Return (new snap point list, report lines) for one board."""
    race = race_name(board)
    old = [s for s in board.get('AttachedSnapPoints') or [] if UNUSED not in tags(s)]
    ys = sorted(s['Position']['y'] for s in old)
    y = ys[len(ys) // 2] if ys else 0.3
    report = []
    out = []

    def placeholder(x, z):
        out.append(new_point(x, z, y, [UNUSED]))

    influence = [s for s in old if 'Influence' in tags(s)]
    actions = sorted((s for s in influence if s['Position']['z'] < 0.82), key=lambda s: -s['Position']['x'])
    track = sorted((s for s in influence if s['Position']['z'] >= 0.82), key=lambda s: -s['Position']['x'])
    if len(actions) != 6 or len(track) != 13:
        raise ValueError(f'{race}: expected 6 action + 13 influence track points, '
                         f'found {len(actions)} + {len(track)}')
    reputation = sorted((s for s in old if {'Reputation', 'Ambassador'} & set(tags(s))),
                        key=lambda s: s['Position']['z'])
    if len(reputation) > 5:
        raise ValueError(f'{race}: {len(reputation)} reputation/ambassador points, at most 5 expected')
    discovery = [s for s in old if 'Discovery' in tags(s)]
    if len(discovery) > 1:
        raise ValueError(f'{race}: {len(discovery)} discovery points, at most 1 expected')

    claimed = {id(s) for s in actions + track + reputation + discovery}
    rest = [s for s in old if id(s) not in claimed]
    # blueprint cells and Muon Source spots take untagged points only
    blueprint_pool = [s for s in rest if not tags(s) and s['Position']['z'] < -0.3]
    tech_pool = [s for s in rest if set(tags(s)) <= {'TechTile'} and s['Position']['z'] >= -0.3]
    tech_tags = ['TechTile'] if tech_pool and all('TechTile' in tags(s) for s in tech_pool) else None

    # 1-6 actions
    out.extend(actions)

    # 7-33 blueprints: per ship its cells, then its Muon Source spot
    layout = race_layout(race)
    for ship in SHIPS:
        for number, (cx, cz, real) in enumerate(layout[ship]['cells'] + [layout[ship]['muon']], start=1):
            label = f'{ship} {"Muon Source" if number > len(layout[ship]["cells"]) else f"cell {number}"}'
            found = take_nearest(blueprint_pool, (cx, cz))
            if found is not None:
                out.append(found)
                if not real:
                    report.append(f'kept a real point at {label}, which the layout marks as missing')
            elif real:
                out.append(new_point(cx, cz, y))
                report.append(f'added {label}')
            else:
                placeholder(cx, cz)

    # 34-46 influence track
    out.extend(track)

    # 47-67 tech tracks, row by row, space 1-7 left to right
    for row_name, rz in zip(('Military', 'Grid', 'Nano'), TECH_ROWS):
        for column, cx in enumerate(TECH_COLUMNS, start=1):
            found = take_nearest(tech_pool, (cx, rz))
            if found is not None:
                out.append(found)
            else:
                out.append(new_point(cx, rz, y, tech_tags))
                report.append(f'added {row_name} tech space {column}')

    # 68-72 reputation / ambassador column, top to bottom
    out.extend(reputation)
    for x, z in REPUTATION[len(reputation):]:
        placeholder(x, z)

    # 73 discovery
    if discovery:
        out.extend(discovery)
    else:
        placeholder(*DISCOVERY)

    # 74+ anything else, in its original order
    leftover = [s for s in old if id(s) not in {id(o) for o in out}]
    if leftover:
        report.append(f'kept {len(leftover)} unrecognised point(s) at 74+')
    out.extend(leftover)
    assert len(out) >= 73
    return out, report


# ---- writing back into the mod file -------------------------------------------------------------
def snap_span(raw, guid):
    """(start, end) of the board's AttachedSnapPoints array value in the raw mod text."""
    key = f'"GUID": "{guid}"'
    if raw.count(key) != 1:
        raise ValueError(f'GUID {guid} found {raw.count(key)} times in the mod file')
    at = raw.index(key)
    start = raw.index('"AttachedSnapPoints": [', at) + len('"AttachedSnapPoints": ')
    next_guid = raw.find('"GUID": "', at + len(key))
    if next_guid != -1 and start > next_guid:
        raise ValueError(f'board {guid} has no AttachedSnapPoints of its own')
    depth = 0
    for end in range(start, len(raw)):
        if raw[end] == '[':
            depth += 1
        elif raw[end] == ']':
            depth -= 1
            if depth == 0:
                return start, end + 1
    raise ValueError(f'unterminated AttachedSnapPoints for board {guid}')


def element_texts(array_text):
    """Raw text of each top-level {...} element of a JSON array, verbatim."""
    texts, depth, begin = [], 0, None
    for i, char in enumerate(array_text):
        if char == '{':
            if depth == 0:
                begin = i
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0:
                texts.append(array_text[begin:i + 1])
    return texts


def point_text(point, indent, newline):
    """Text for a new snap point, in the mod file's style (2-space JSON, upper-case exponent)."""
    text = json.dumps(point, indent=2, ensure_ascii=False).replace('e-', 'E-').replace('e+', 'E+')
    return text.replace('\n', newline + ' ' * indent)


def array_text(elements, indent, newline):
    inner = ' ' * (indent + 2)
    if not elements:
        return '[]'
    return '[' + newline + inner + (',' + newline + inner).join(elements) + newline + ' ' * indent + ']'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--mod', default=DEFAULT_MOD, help='mod JSON file (default: %(default)s)')
    parser.add_argument('--check', action='store_true', help="don't write, exit 1 if a board needs changes")
    args = parser.parse_args()

    with open(args.mod, encoding='utf-8', newline='') as f:
        raw = f.read()
    mod = json.loads(raw)

    edits = []
    for board in player_boards(mod):
        race = race_name(board)
        if race in SKIP_RACES:
            continue
        start, end = snap_span(raw, board['GUID'])
        indent = start - raw.rfind('\n', 0, start) - 1 - len('"AttachedSnapPoints": ')
        original = raw[start:end]
        newline = '\r\n' if '\r\n' in original else '\n'  # the mod file mixes line endings
        # existing points are copied as their original text, so their numbers stay exactly as written
        verbatim = element_texts(original)
        if len(verbatim) != len(board['AttachedSnapPoints']) or \
                [json.loads(t) for t in verbatim] != board['AttachedSnapPoints']:
            raise ValueError(f'{race}: cannot split the snap point text; refusing to edit')
        by_id = {id(p): t for p, t in zip(board['AttachedSnapPoints'], verbatim)}
        points, report = normalize(board)
        text = array_text([by_id.get(id(p)) or point_text(p, indent + 2, newline) for p in points],
                          indent, newline)
        if json.loads(text) != points:
            raise ValueError(f'{race}: generated text does not match the new snap points')
        changed = json.loads(original) != points
        placeholders = sum(UNUSED in tags(s) for s in points)
        print(f'{race:<22} {board["GUID"]}  {len(board["AttachedSnapPoints"]):>3} -> {len(points):>3} points, '
              f'{placeholders:>2} placeholders  {"changed" if changed else "already normalized"}')
        for line in report:
            print(f'    {line}')
        if changed:
            edits.append((start, end, text))

    if args.check:
        sys.exit(1 if edits else 0)
    for start, end, text in sorted(edits, reverse=True):
        raw = raw[:start] + text + raw[end:]
    json.loads(raw)  # still valid JSON
    with open(args.mod, 'w', encoding='utf-8', newline='') as f:
        f.write(raw)
    print(f'\n{len(edits)} board(s) rewritten in {args.mod}' if edits else '\nnothing to do')


if __name__ == '__main__':
    main()
