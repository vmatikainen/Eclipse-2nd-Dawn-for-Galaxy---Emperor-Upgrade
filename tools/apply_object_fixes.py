"""Apply our changes to objects in the mod JSON (changes that are not scripts or snap points).

The mod JSON is not in git, so every change we make to its objects has to be reproducible
from the repository. Each fix below is a rule; tools/rebuild_mod.py runs this file.

Usage (run from the repository root):
    python tools/apply_object_fixes.py           apply the fixes to the mod file
    python tools/apply_object_fixes.py --check   exit code 1 if a fix still needs applying

Fixes:
  sector-tiles-aligned   Every tile stored in the sector, galactic events and guardian sector
                         bags lies level at a yaw of 0, aligned to the board's hex grid, and keeps
                         the side it shows. Most were stored at a yaw of 270, so they came out of
                         the bags turned 30 degrees off the grid.
  reputation-bag-random  The Reputation Tiles bag draws in random order (Bag.Order = 2). It was
                         last in, first out, so a just-returned tile was drawn next.
  setup-background       The setup popup's background (UI asset "SetupOptions") is our
                         emperor_background.jpg: SETUP_BACKGROUND_URL once it is uploaded, until
                         then the image in the repository root as a local file:/// URL (only on
                         a computer that has the file; without it the original stays).

Only the values these rules touch change; the rest of the mod file stays byte-for-byte identical.
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from annotate_boards import DEFAULT_MOD  # noqa: E402

SECTOR_BAGS = {'Sector I Tiles', 'Sector II Tiles', 'Sector III Tiles', 'Galactic Events', 'Guardian Sectors'}
REPUTATION_BAG_GUID = '3c5d08'
RANDOM_ORDER = 2
SETUP_ASSET = 'SetupOptions'
SETUP_BACKGROUND_URL = None  # the uploaded image's Steam Cloud URL, once there is one
SETUP_BACKGROUND_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                     'emperor_background.jpg')


def walk(objects):
    for obj in objects:
        yield obj
        yield from walk(obj.get('ContainedObjects') or [])


def object_span(raw, guid):
    """(start, end) of the raw text from the object's GUID key up to the next GUID key."""
    key = f'"GUID": "{guid}"'
    if raw.count(key) != 1:
        raise ValueError(f'GUID {guid} found {raw.count(key)} times in the mod file')
    start = raw.index(key)
    end = raw.find('"GUID": "', start + len(key))
    return start, (end if end != -1 else len(raw))


def set_number(raw, guid, block, field, value):
    """Set "field": <number> inside the object's first "block": {...}; return the new raw text."""
    start, end = object_span(raw, guid)
    block_at = raw.find(f'"{block}": {{', start, end)
    if block_at == -1:
        raise ValueError(f'{guid}: no "{block}" block')
    block_end = raw.index('}', block_at)
    pattern = re.compile(rf'"{field}": (-?[0-9.Ee+-]+)')
    match = pattern.search(raw, block_at, block_end)
    if match is None:
        raise ValueError(f'{guid}: no "{field}" in "{block}"')
    return raw[:match.start(1)] + value + raw[match.end(1):]


def sector_tiles_aligned(mod):
    """(guid, block, field, value) edits for the sector tiles."""
    edits = []
    for bag in walk(mod['ObjectStates']):
        if bag.get('Nickname') not in SECTOR_BAGS or 'Bag' not in bag.get('Name', ''):
            continue
        for tile in bag.get('ContainedObjects') or []:
            t = tile['Transform']
            face_down = abs(((t['rotZ'] + 180) % 360) - 180) > 90  # rotZ near 180
            for field, value in (('rotX', 0.0), ('rotY', 0.0), ('rotZ', 180.0 if face_down else 0.0)):
                if t[field] != value:
                    edits.append((tile['GUID'], 'Transform', field, repr(value)))
    return edits


def reputation_bag_random(mod):
    bag = next(o for o in walk(mod['ObjectStates']) if o.get('GUID') == REPUTATION_BAG_GUID)
    if (bag.get('Bag') or {}).get('Order') != RANDOM_ORDER:
        return [(REPUTATION_BAG_GUID, 'Bag', 'Order', str(RANDOM_ORDER))]
    return []


def setup_background_url():
    if SETUP_BACKGROUND_URL:
        return SETUP_BACKGROUND_URL
    if os.path.exists(SETUP_BACKGROUND_FILE):
        return 'file:///' + SETUP_BACKGROUND_FILE.replace(os.sep, '/')
    return None


def setup_background(mod):
    url = setup_background_url()
    if url is None:
        return []
    asset = next((a for a in mod.get('CustomUIAssets') or [] if a.get('Name') == SETUP_ASSET), None)
    if asset is None:
        raise ValueError(f'no UI asset named {SETUP_ASSET}')
    if asset.get('URL') == url:
        return []
    return [('ui-asset-url', SETUP_ASSET, asset.get('URL'), url)]


def set_asset_url(raw, name, old, new):
    """Point the UI asset `name` at a new URL; return the new raw text."""
    key = f'"Name": {json.dumps(name)}'
    start = raw.index('"CustomUIAssets"')
    at = raw.index(key, start)
    old_text = f'"URL": {json.dumps(old)}'
    url_at = raw.index(old_text, at)
    return raw[:url_at] + f'"URL": {json.dumps(new)}' + raw[url_at + len(old_text):]


def apply_edit(raw, edit):
    if edit[0] == 'ui-asset-url':
        return set_asset_url(raw, *edit[1:])
    return set_number(raw, *edit)


FIXES = [('sector-tiles-aligned', sector_tiles_aligned), ('reputation-bag-random', reputation_bag_random),
         ('setup-background', setup_background)]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--mod', default=DEFAULT_MOD, help='mod JSON file (default: %(default)s)')
    parser.add_argument('--check', action='store_true', help="don't write, exit 1 if a fix needs applying")
    args = parser.parse_args()

    with open(args.mod, encoding='utf-8', newline='') as f:
        raw = f.read()
    mod = json.loads(raw)

    total = 0
    for name, fix in FIXES:
        edits = fix(mod)
        print(f'{name:<24} {len(edits):>3} value(s) to change' if edits else f'{name:<24} already applied')
        for edit in edits:
            raw = apply_edit(raw, edit)
        total += len(edits)

    if args.check:
        sys.exit(1 if total else 0)
    if total:
        json.loads(raw)  # still valid JSON
        with open(args.mod, 'w', encoding='utf-8', newline='') as f:
            f.write(raw)


if __name__ == '__main__':
    main()
