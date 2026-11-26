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
                         assets/emperor_background.jpg, uploaded to Steam Cloud
                         (SETUP_BACKGROUND_URL). Without a URL it would be the image in the
                         repository as a local file:/// URL, and without the image the asset is
                         left out and the popup is black.
  mod-name               The mod's name (SaveName, shown in TTS) is our Workshop item's,
                         MOD_NAME, not the original mod's.
  traitor-spots          Each seat has a Traitor spot: a table snap point tagged "Traitor",
                         beside where the Start Player tile goes (TRAITOR_OFFSET from the seat's
                         hand, mirrored for the far side of the table). The Traitor tile is tagged
                         "Traitor" and snaps to snap points, so it only snaps to these spots.
                         Snap points show no text, so each spot gets a locked 3D text "Traitor"
                         lying on the table in the middle of it, under the tile (TRAITOR_LABEL_GUIDS, GMNotes
                         "TraitorLabel <Color>"), readable from that seat.
  muon-source-labels     Every player board (except deprecated Pyxis Unity) shows a small, faint
                         "Muon source" text on each ship's Muon Source spot (snap points 11, 18,
                         27, 33; Unused placeholders skipped), as the board's own XmlUI, so it
                         moves with the board and needs no script. A Muon Source tile placed
                         there covers it. Nothing reads it; a script that sets a board's UI
                         (board.UI.setXml) would replace it. The XML starts with
                         GENERATED_MARKER, so tools/tts_scripts.py doesn't treat it as a script.
                         Scoring (scripts/include/Score.ttslua) reads the Traitor's holder from
                         the spot it lies on.
  rulebook               The two big Rulebook PDFs (RULEBOOK_PDF_GUIDS) are replaced by small
                         locked tiles showing the cover (RULEBOOK_TILE_GUIDS, GMNotes "Rulebook"),
                         one per long side of the table. scripts/include/Rulebook.ttslua gives
                         them a button that opens the rulebook on screen. The 32 pages are UI
                         assets "Rulebook01".."Rulebook32": each page's Steam Cloud URL in
                         RULEBOOK_PAGE_URLS, or for a page not uploaded yet its image in
                         assets/rulebook/ (git-ignored, see README) as a local file:/// URL.
                         If a page has neither, the rule does nothing and the PDFs stay.
  dice-bags              The two sets of dice bags (Ion, Plasma, Soliton, Antimatter, Rift) lie
                         in a column at the combat zone's end of each long side, where the
                         Rulebook PDFs were (DICE_BAG_COLUMN), Ion nearest the seats. They were
                         in rows in the middle of each long side.

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
MOD_NAME = 'Eclipse: Second Dawn for the Galaxy - Emperor Edition'
SETUP_ASSET = 'SetupOptions'
# assets/emperor_background.jpg uploaded to Steam Cloud
SETUP_BACKGROUND_URL = 'https://steamusercontent-a.akamaihd.net/ugc/12261681211286334942/BFC258A117E13CF40E041A5AC7A232D240491B35/'
TRAITOR_GUID = 'faba6c'
TRAITOR_TAG = 'Traitor'
# from a seat's hand position, for the seats at negative z (the far side is mirrored): beside
# the Start Player tile's spot (placeFirstPlayerTile: hand + 28 toward the table centre), to the
# player's left. The tiles are about 5 apart.
TRAITOR_OFFSET = (-5.6, 28.0)
TABLE_Y = 0.96
SEAT_COLORS = ('White', 'Red', 'Blue', 'Purple', 'Green', 'Yellow')
# tools/tts_scripts.py leaves an XmlUI starting with this alone (keep the two in step)
GENERATED_MARKER = '<!-- generated by tools/apply_object_fixes.py'
MUON_SNAPS = (11, 18, 27, 33)     # Muon Source spots: Interceptor, Cruiser, Dreadnought, Starbase/Orbital
MUON_SKIP_BOARDS = {'6ec4f3'}     # Pyxis Unity: deprecated, its board isn't normalized
MUON_LABEL_TEXT = 'Muon\nsource'
MUON_LABEL_FONT = 40              # drawn at 10x and scaled by 0.1, so the small text stays sharp
MUON_LABEL_COLOR = '#FFFFFF66'    # white, about 40% opaque
# Object UI: 100 UI units per board-local unit, UI x = local x, UI y = local z, and the UI's z
# points down into the board. Text reads along the board image's right (local -x) with its top
# toward the image's top (local -z) at a turn of 180. If it shows upside down in TTS, use 0.
MUON_LABEL_TURN = 180
MUON_LABEL_LIFT = 1               # UI units above the board's top surface (a board's origin is its
                                  # bottom, so the top is its thickness up); a part tile (0.1 thick)
                                  # lying on the spot covers it
MUON_LABEL_SIZE = (240, 140)      # width, height before the 0.1 scale: a 24 x 14 box (a cell is 23 apart)
TRAITOR_LABEL_GUIDS = ('b7a101', 'b7a102', 'b7a103', 'b7a104', 'b7a105', 'b7a106')  # in SEAT_COLORS order
TRAITOR_LABEL_GAP = 0.0   # from the spot toward the table centre: 0 = in the middle of the spot
TRAITOR_LABEL_SIZE = 48
SETUP_BACKGROUND_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                     'assets', 'emperor_background.jpg')
RULEBOOK_PDF_GUIDS = ('c055de', '24ffaa')     # the original mod's two Rulebook PDFs
RULEBOOK_TILE_GUIDS = ('b7b001', 'b7b002')
# where the PDFs lay, one per long side: (x, z, rotY), turned like the PDFs to face that side
RULEBOOK_TILE_SPOTS = ((-45.21, 26.0, 0.0), (-45.21, -26.0, 180.0))
RULEBOOK_TILE_SCALE = 2.0     # about 4 x 5.7 (the PDFs were 11.6 x 16.4)
RULEBOOK_TILE_NOTE = 'Rulebook'   # GMNotes: Rulebook.ttslua finds the tiles by it
RULEBOOK_PAGES = 32
RULEBOOK_ASSET = 'Rulebook{:02d}'
# the page images (assets/rulebook/page-01.jpg ...) uploaded to Steam Cloud: page -> URL.
# A page without one uses its local file (a file:/// URL, only on the machine that built the mod).
RULEBOOK_PAGE_URLS = {
    1: 'https://steamusercontent-a.akamaihd.net/ugc/15377515069704833185/6485ED60E0D8F0BF717A2DE0A1259EB6DC299AF7/',
    2: 'https://steamusercontent-a.akamaihd.net/ugc/16780371824131168342/89D2986C034DB97B2C5E1DD7FC78E1482EA58B8D/',
    3: 'https://steamusercontent-a.akamaihd.net/ugc/14453037334833060171/E32219408EEE18432C12DF965DA196D9A56C003C/',
    4: 'https://steamusercontent-a.akamaihd.net/ugc/16565258212438665665/02E6B210A9E3BA311CA54D44DEBE550B40E8A3DD/',
    5: 'https://steamusercontent-a.akamaihd.net/ugc/15005467199493659785/5CE83310331FC95208D4FAE2244FE487100F9DA6/',
    6: 'https://steamusercontent-a.akamaihd.net/ugc/14459871804994455712/4823942607DD629E7372FA367E854E74204EA110/',
    7: 'https://steamusercontent-a.akamaihd.net/ugc/12856901005313561787/82A376F1EFB6DB2F8CDA2DBDACBD97C248AD37F7/',
    8: 'https://steamusercontent-a.akamaihd.net/ugc/12542145536913851612/000B6C1A4A8B840626E07A973A61AAE61BD93C02/',
    9: 'https://steamusercontent-a.akamaihd.net/ugc/14624406172694300517/9032930645926F42C45A797CFE3C65AF9E3841C3/',
    10: 'https://steamusercontent-a.akamaihd.net/ugc/11856971825289528875/71DF3578835D93E953E121F4B32A5A0DE0A245B7/',
    11: 'https://steamusercontent-a.akamaihd.net/ugc/11008757076257638316/FD73C5B2C49A0D5E14C60248590D12B2950ED662/',
    12: 'https://steamusercontent-a.akamaihd.net/ugc/17666731815543565192/BAFBE484A01EAA594284F9D7CAF52887B5803C44/',
    13: 'https://steamusercontent-a.akamaihd.net/ugc/14153699442115854979/083A4F84F5568830413A5E6E3A98006B7E3CA2D4/',
    14: 'https://steamusercontent-a.akamaihd.net/ugc/12388734324393012011/EC7BEAEEEBC9DAF43C41A323C0C29735FAA1C13F/',
    15: 'https://steamusercontent-a.akamaihd.net/ugc/17336511813487563801/193F2D28C827AC8240AB36A36ED110AFE08C84D4/',
    16: 'https://steamusercontent-a.akamaihd.net/ugc/12819679151365399443/38C6798066CD0627BCAD1878F3C033977A2C11F7/',
    17: 'https://steamusercontent-a.akamaihd.net/ugc/9260593931331037586/0512005E2045EFAF66C2E6CB8E81FDCC389F5279/',
    18: 'https://steamusercontent-a.akamaihd.net/ugc/10562113576922221184/6D24BF729B46FDE7FD587E55866B2375D328606D/',
    19: 'https://steamusercontent-a.akamaihd.net/ugc/17519200778101037131/E440EFDB14BFFF2052182EBB0653B020BDB3022B/',
    20: 'https://steamusercontent-a.akamaihd.net/ugc/16047297254393271395/2FF9B5CFA453F0C5115B901CCBAFD79CD08D3402/',
    21: 'https://steamusercontent-a.akamaihd.net/ugc/16653039266951442533/57C24E470DC2880B683F9AB39163F8AD57506C3D/',
    22: 'https://steamusercontent-a.akamaihd.net/ugc/14534115509230634094/4ADF8A4EF53ED874F74E74ADDFAB216C06AD4135/',
    23: 'https://steamusercontent-a.akamaihd.net/ugc/14105829570728464126/52EFE9BABE12D903CDF04B23A808EC31127C654C/',
    24: 'https://steamusercontent-a.akamaihd.net/ugc/16422991501103330289/2AA08D2346EF917B8AF2B3A8486E18ECD81D337C/',
    25: 'https://steamusercontent-a.akamaihd.net/ugc/12762077803608909569/AA78AA7508DBD681580018445900066801056F64/',
    26: 'https://steamusercontent-a.akamaihd.net/ugc/17267773392151811420/3DA8ABD17937413218AD71428475FEE07EBBD259/',
    27: 'https://steamusercontent-a.akamaihd.net/ugc/12698460081826544101/E83063CC0AA365356BC9423FD6F919E1CB8CA7F4/',
    28: 'https://steamusercontent-a.akamaihd.net/ugc/9583546036811186033/644A9B72E435A5B0A8F83D1D8176F692954BE8F4/',
    29: 'https://steamusercontent-a.akamaihd.net/ugc/10470341451568804015/71AF774CFACA5964EAAE33E8F4CF67609F3F62C9/',
    30: 'https://steamusercontent-a.akamaihd.net/ugc/17281021655857794524/53D00BFE449AC6B195E498AEC2513DFD20EBA714/',
    31: 'https://steamusercontent-a.akamaihd.net/ugc/15156364462949804828/E30E835694D437DF4F2BA66A923AD72FD9F3048E/',
    32: 'https://steamusercontent-a.akamaihd.net/ugc/11381325186915709154/A4FE438C1E010BB340ADD350F4BF68DE331D5A79/',
}
RULEBOOK_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'rulebook')
# the dice bags of each long side (+z, -z), Ion, Plasma, Soliton, Antimatter, Rift (the sets
# in scripts/include/CombatZone.ttslua's COMBAT_ZONE_DICE_BAGS)
DICE_BAGS = {1: ('2388bc', '740d72', 'fe326f', '6a7479', '1ec1c3'),
             -1: ('57e8f9', 'a3c3b3', '8ab8d5', '0bea7c', '79897f')}
# x of the column (left of the Rulebook tile, which spans x -47.2..-43.2), and |z| of the
# bags from the seats inward: the same 2.58 apart as before, clear of the Galactic Events
# bag (z 15.2) and the Traitor label at z -32.9
DICE_BAG_COLUMN = (-49.8, (30.2, 27.62, 25.04, 22.46, 19.88))


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
    return local_file_url(SETUP_BACKGROUND_FILE)


def local_file_url(path):
    """file:///C:/... on Windows, file:///Users/... on macOS, or None if the file isn't there.
    Spaces stay as they are: TTS doesn't decode %20 in a file URL."""
    if not os.path.exists(path):
        return None
    path = path.replace(os.sep, '/')
    return 'file://' + (path if path.startswith('/') else '/' + path)


def setup_background(mod):
    """Point the UI asset at the image; without the image, leave the asset out (the popup is
    then black: setupBackground_check in Global hides the image)."""
    url = setup_background_url()
    assets = mod.get('CustomUIAssets') or []
    want = [a for a in assets if a.get('Name') != SETUP_ASSET]
    if url is not None:
        want.append({'Type': 0, 'Name': SETUP_ASSET, 'URL': url})
    if sorted(map(json.dumps, want)) == sorted(map(json.dumps, assets)):
        return []
    return [('ui-assets', want)]


def mod_name(mod):
    if mod.get('SaveName') == MOD_NAME:
        return []
    return [('save-name', MOD_NAME)]


def set_save_name(raw, name):
    """Replace the top-level "SaveName" string (the first key of that name); return the new raw text."""
    key = '"SaveName": '
    start = raw.index(key) + len(key)
    _, end = json.JSONDecoder().raw_decode(raw, start)
    return raw[:start] + json.dumps(name, ensure_ascii=False) + raw[end:]


def set_ui_assets(raw, assets):
    """Replace the CustomUIAssets list; return the new raw text."""
    key = '"CustomUIAssets": '
    start = raw.index(key) + len(key)
    _, end = json.JSONDecoder().raw_decode(raw, start)  # end of the list in the raw text
    line_start = raw.rfind('\n', 0, start) + 1
    indent = raw[line_start:start - len(key)]
    text = json.dumps(assets, indent=2).replace('\n', '\n' + indent) if assets else '[]'
    return raw[:start] + text + raw[end:]


def seat_hands(mod):
    """color -> the seat's hand zone Transform."""
    hands = {}
    for obj in mod['ObjectStates']:
        if obj.get('Name') == 'HandTrigger':
            color = (obj.get('FogColor') or '').capitalize()
            if color in SEAT_COLORS:
                hands[color] = obj['Transform']
    return hands


def traitor_points(mod):
    """The Traitor snap points there should be, one per seat, in SEAT_COLORS order."""
    hands = seat_hands(mod)
    points = []
    for color in SEAT_COLORS:
        if color not in hands:
            raise ValueError(f'no hand zone for {color}')
        hand = hands[color]
        inv = 1 if hand['posZ'] < 0 else -1
        points.append({'Position': {'x': round(hand['posX'] + TRAITOR_OFFSET[0] * inv, 2), 'y': TABLE_Y,
                                    'z': round(hand['posZ'] + TRAITOR_OFFSET[1] * inv, 2)},
                       'Tags': [TRAITOR_TAG]})
    return points


def traitor_labels(mod):
    """The label objects there should be, one per seat: GUID -> object (a 3D text lying flat,
    its top toward the table centre, so the seat reads it the right way up)."""
    labels = {}
    for color, guid, point in zip(SEAT_COLORS, TRAITOR_LABEL_GUIDS, traitor_points(mod)):
        inv = 1 if seat_hands(mod)[color]['posZ'] < 0 else -1
        position = point['Position']
        labels[guid] = {
            'GUID': guid, 'Name': '3DText',
            'Transform': {'posX': position['x'], 'posY': TABLE_Y + 0.02,
                          'posZ': round(position['z'] + TRAITOR_LABEL_GAP * inv, 2),
                          'rotX': 90.0, 'rotY': 0.0 if inv == 1 else 180.0, 'rotZ': 0.0,
                          'scaleX': 1.0, 'scaleY': 1.0, 'scaleZ': 1.0},
            'Nickname': '', 'Description': '', 'GMNotes': f'TraitorLabel {color}',
            'ColorDiffuse': {'r': 1.0, 'g': 1.0, 'b': 1.0},
            'Locked': True, 'Grid': False, 'Snap': False, 'Autoraise': True, 'Sticky': False,
            'Tooltip': False, 'GridProjection': False, 'Hands': False,
            'Text': {'Text': 'Traitor', 'colorstate': {'r': 0.85, 'g': 0.85, 'b': 0.85},
                     'fontSize': TRAITOR_LABEL_SIZE},
        }
    return labels


def traitor_spots(mod):
    edits = []
    have = {o['GUID']: o for o in mod['ObjectStates'] if o.get('GUID') in TRAITOR_LABEL_GUIDS}
    want = traitor_labels(mod)
    if json.dumps(have, sort_keys=True) != json.dumps(want, sort_keys=True):
        edits.append(('traitor-labels', want))
    have = [p for p in mod.get('SnapPoints') or [] if TRAITOR_TAG in (p.get('Tags') or [])]
    want = traitor_points(mod)
    if json.dumps(have, sort_keys=True) != json.dumps(want, sort_keys=True):
        edits.append(('traitor-snaps', want))
    traitor = next(o for o in mod['ObjectStates'] if o.get('GUID') == TRAITOR_GUID)
    if traitor.get('Snap') is not True:
        edits.append(('traitor-snap-flag', None))
    if TRAITOR_TAG not in (traitor.get('Tags') or []):
        edits.append(('traitor-tag', None))
    return edits


def top_level_span(raw, key):
    """(start, end) of a top-level key's value in the raw text (keys at two spaces' indent)."""
    match = re.search(r'^  "' + key + r'": ', raw, re.M)
    if match is None:
        raise ValueError(f'no top-level "{key}"')
    _, end = json.JSONDecoder().raw_decode(raw, match.end())
    return match.end(), end


def set_traitor_snaps(raw, points):
    """Keep the table's other snap points verbatim, replace the Traitor ones; return the new raw text."""
    start, end = top_level_span(raw, 'SnapPoints')
    texts, depth, begin = [], 0, None
    for i in range(start, end):
        if raw[i] == '{':
            if depth == 0:
                begin = i
            depth += 1
        elif raw[i] == '}':
            depth -= 1
            if depth == 0:
                texts.append(raw[begin:i + 1])
    kept = [t for t in texts if TRAITOR_TAG not in (json.loads(t).get('Tags') or [])]
    new = [json.dumps(p, indent=2).replace('\n', '\n    ') for p in points]
    elements = kept + new
    text = '[\n    ' + ',\n    '.join(elements) + '\n  ]' if elements else '[]'
    return raw[:start] + text + raw[end:]


def set_traitor_flag(raw):
    start, end = object_span(raw, TRAITOR_GUID)
    at = raw.index('"Snap": false', start, end)
    return raw[:at] + '"Snap": true' + raw[at + len('"Snap": false'):]


def add_traitor_tag(raw):
    """Add "Tags": ["Traitor"] after the Traitor's GMNotes (it has no Tags yet)."""
    start, end = object_span(raw, TRAITOR_GUID)
    if raw.find('"Tags": [', start, end) != -1:
        raise ValueError(f'{TRAITOR_GUID} has Tags without "{TRAITOR_TAG}": add it by hand')
    at = raw.index('"GMNotes": ', start, end)
    line_start = raw.rfind('\n', 0, at) + 1
    indent = raw[line_start:at]
    line_end = raw.index('\n', at)
    tags = f'{indent}"Tags": [\n{indent}  "{TRAITOR_TAG}"\n{indent}],\n'
    return raw[:line_end + 1] + tags + raw[line_end + 1:]


def set_traitor_labels(raw, labels):
    """Replace the label objects (or add them) at the end of ObjectStates; return the new raw text."""
    return replace_objects(raw, labels.keys(), labels.values())


def replace_objects(raw, drop, add):
    """Remove the top-level objects with the GUIDs in `drop` (those that are there), then add the
    objects in `add` at the end of ObjectStates; return the new raw text."""
    mod = json.loads(raw)
    present = {o.get('GUID') for o in mod['ObjectStates']}
    for guid in drop:
        if guid not in present:
            continue
        start, end = top_level_span(raw, 'ObjectStates')
        s, _ = object_span(raw, guid)
        begin = raw.rindex('{', start, s)
        _, finish = json.JSONDecoder().raw_decode(raw, begin)
        before = raw.rindex(',', start, begin)  # the comma before this element
        raw = raw[:before] + raw[finish:]
    start, end = top_level_span(raw, 'ObjectStates')
    close = raw.rindex(']', start, end)
    body = raw[:close].rstrip()
    text = ''.join(',\n    ' + json.dumps(o, indent=2).replace('\n', '\n    ') for o in add)
    return body + text + '\n  ' + raw[close:]


def muon_label_xml(board):
    """The board's XmlUI: one Text per Muon Source spot, or '' if it has none."""
    snaps = board.get('AttachedSnapPoints') or []
    top = ((board.get('CustomImage') or {}).get('CustomTile') or {}).get('Thickness', 0.2)
    texts = []
    for number in MUON_SNAPS:
        if number > len(snaps) or 'Unused' in (snaps[number - 1].get('Tags') or []):
            continue
        p = snaps[number - 1]['Position']
        texts.append(
            f'<Text position="{p["x"] * 100:.1f} {p["z"] * 100:.1f} {-(top * 100 + MUON_LABEL_LIFT):.1f}" '
            f'rotation="0 0 {MUON_LABEL_TURN}" scale="0.1 0.1 1" '
            f'width="{MUON_LABEL_SIZE[0]}" height="{MUON_LABEL_SIZE[1]}" fontSize="{MUON_LABEL_FONT}" '
            f'color="{MUON_LABEL_COLOR}" alignment="MiddleCenter" raycastTarget="false">{MUON_LABEL_TEXT}</Text>')
    if not texts:
        return ''
    return '\n'.join([GENERATED_MARKER + ' (muon-source-labels): edit the rule, not this -->'] + texts)


def muon_source_labels(mod):
    edits = []
    for board in walk(mod['ObjectStates']):
        if 'PlayerBoard' not in (board.get('Tags') or []) or board.get('GUID') in MUON_SKIP_BOARDS:
            continue
        xml = muon_label_xml(board)
        if board.get('XmlUI', '') != xml:
            edits.append(('board-xml', board['GUID'], xml))
    return edits


def set_board_xml(raw, guid, xml):
    """Set the board's "XmlUI" string; return the new raw text."""
    start, end = object_span(raw, guid)
    key = '"XmlUI": '
    at = raw.find(key, start, end)
    if at == -1:
        raise ValueError(f'{guid}: no "XmlUI"')
    _, value_end = json.JSONDecoder().raw_decode(raw, at + len(key))
    return raw[:at + len(key)] + json.dumps(xml, ensure_ascii=False) + raw[value_end:]


def rulebook_page_urls():
    """The 32 page URLs, each Steam Cloud's or else the local image's; None if any is missing."""
    urls = [RULEBOOK_PAGE_URLS.get(n) or local_file_url(os.path.join(RULEBOOK_DIR, f'page-{n:02d}.jpg'))
            for n in range(1, RULEBOOK_PAGES + 1)]
    return None if None in urls else urls


def rulebook_tiles(cover_url):
    """The tile objects there should be: GUID -> object (a locked tile showing the cover)."""
    tiles = {}
    for guid, (x, z, rot_y) in zip(RULEBOOK_TILE_GUIDS, RULEBOOK_TILE_SPOTS):
        tiles[guid] = {
            'GUID': guid, 'Name': 'Custom_Tile',
            'Transform': {'posX': x, 'posY': TABLE_Y, 'posZ': z, 'rotX': 0.0, 'rotY': rot_y, 'rotZ': 0.0,
                          'scaleX': RULEBOOK_TILE_SCALE, 'scaleY': 1.0, 'scaleZ': RULEBOOK_TILE_SCALE},
            'Nickname': 'Rulebook', 'Description': 'Click the button to read the rulebook on your screen.',
            'GMNotes': RULEBOOK_TILE_NOTE,
            'ColorDiffuse': {'r': 1.0, 'g': 1.0, 'b': 1.0},
            'Locked': True, 'Grid': False, 'Snap': False, 'Autoraise': True, 'Sticky': False,
            'Tooltip': True, 'GridProjection': False, 'Hands': False,
            'CustomImage': {'ImageURL': cover_url, 'ImageSecondaryURL': cover_url, 'ImageScalar': 1.0,
                            'WidthScale': 0.0,
                            'CustomTile': {'Type': 0, 'Thickness': 0.2, 'Stackable': False, 'Stretch': True}},
            'LuaScript': '', 'LuaScriptState': '', 'XmlUI': '',
        }
    return tiles


def dice_bags(mod):
    objects = {o.get('GUID'): o for o in mod['ObjectStates']}
    x, zs = DICE_BAG_COLUMN
    edits = []
    for sign, guids in DICE_BAGS.items():
        for guid, z in zip(guids, zs):
            t = objects[guid]['Transform']
            for field, value in (('posX', x), ('posZ', sign * z)):
                if t[field] != value:
                    edits.append((guid, 'Transform', field, repr(value)))
    return edits


def rulebook(mod):
    urls = rulebook_page_urls()
    if urls is None:
        print(f'  rulebook: no page images in {RULEBOOK_DIR} and no RULEBOOK_PAGE_URLS: '
              'the PDFs stay (see README, "Rulebook pages")', file=sys.stderr)
        return []
    edits = []
    assets = mod.get('CustomUIAssets') or []
    names = {RULEBOOK_ASSET.format(n) for n in range(1, RULEBOOK_PAGES + 1)}
    want = [a for a in assets if a.get('Name') not in names]
    want += [{'Type': 0, 'Name': RULEBOOK_ASSET.format(n), 'URL': url} for n, url in enumerate(urls, 1)]
    if sorted(map(json.dumps, want)) != sorted(map(json.dumps, assets)):
        edits.append(('ui-assets', want))
    objects = {o.get('GUID'): o for o in mod['ObjectStates']}
    tiles = rulebook_tiles(urls[0])
    stale = [g for g in RULEBOOK_PDF_GUIDS if g in objects]
    stale += [g for g, tile in tiles.items()
              if json.dumps(objects.get(g), sort_keys=True) != json.dumps(tile, sort_keys=True)]
    if stale:
        edits.append(('objects', stale, [tiles[g] for g in tiles if g in stale]))
    return edits


def apply_edit(raw, edit):
    if edit[0] == 'objects':
        return replace_objects(raw, edit[1], edit[2])
    if edit[0] == 'board-xml':
        return set_board_xml(raw, edit[1], edit[2])
    if edit[0] == 'traitor-labels':
        return set_traitor_labels(raw, edit[1])
    if edit[0] == 'traitor-snaps':
        return set_traitor_snaps(raw, edit[1])
    if edit[0] == 'traitor-snap-flag':
        return set_traitor_flag(raw)
    if edit[0] == 'traitor-tag':
        return add_traitor_tag(raw)
    if edit[0] == 'ui-assets':
        return set_ui_assets(raw, edit[1])
    if edit[0] == 'save-name':
        return set_save_name(raw, edit[1])
    return set_number(raw, *edit)


FIXES = [('sector-tiles-aligned', sector_tiles_aligned), ('reputation-bag-random', reputation_bag_random),
         ('setup-background', setup_background), ('mod-name', mod_name), ('traitor-spots', traitor_spots),
         ('muon-source-labels', muon_source_labels), ('rulebook', rulebook),
         ('dice-bags', dice_bags)]


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
        if edits:
            mod = json.loads(raw)  # the next rule sees this one's changes (two rules set UI assets)
        total += len(edits)

    if args.check:
        sys.exit(1 if total else 0)
    if total:
        json.loads(raw)  # still valid JSON
        with open(args.mod, 'w', encoding='utf-8', newline='') as f:
            f.write(raw)


if __name__ == '__main__':
    main()
