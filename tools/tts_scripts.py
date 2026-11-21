"""Split the Lua/XML scripts of a Tabletop Simulator mod file into separate files, and back.

File naming follows the VS Code Tabletop Simulator extension:
    Global.-1.lua, Global.-1.xml       global script and UI
    <Object Name>.<GUID>.lua / .xml    object scripts and UI

Usage (run from the repository root):
    python tools/tts_scripts.py extract   mod JSON -> scripts/
    python tools/tts_scripts.py build     scripts/ -> mod JSON
    python tools/tts_scripts.py check     exit code 1 if scripts/ and the mod JSON differ

Files are matched to objects by GUID, so renaming an object does not break anything.
Only the script strings that changed are rewritten; the rest of the mod file stays
byte-for-byte identical. Deleting a script file clears that object's script.
"""
import argparse
import json
import os
import re
import sys
from json.decoder import scanstring

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_MOD = os.path.join(ROOT, '2348417296.json')
DEFAULT_DIR = os.path.join(ROOT, 'scripts')

FIELDS = {'LuaScript': '.lua', 'XmlUI': '.xml'}
FIELD_PATTERN = re.compile(r'"(LuaScript|XmlUI)": "')
FILE_PATTERN = re.compile(r'^(?P<name>.*)\.(?P<guid>-1|[0-9a-fA-F]{6})\.(?P<ext>lua|xml)$')
GLOBAL_GUID = '-1'


def read_text(path):
    with open(path, encoding='utf-8', newline='') as f:
        return f.read()


def write_text(path, text):
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(text)


def find_slots(raw):
    """Every LuaScript/XmlUI string in the mod, in file order, with its position in the raw text."""
    entries = []

    def walk(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key in FIELDS and isinstance(value, str):
                    guid = GLOBAL_GUID if node is data else str(node.get('GUID', ''))
                    name = 'Global' if guid == GLOBAL_GUID else (node.get('Nickname') or node.get('Name') or 'Object')
                    entries.append({'field': key, 'guid': guid, 'name': name, 'value': value})
                else:
                    walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    data = json.loads(raw)
    walk(data)

    matches = list(FIELD_PATTERN.finditer(raw))
    if len(matches) != len(entries):
        sys.exit('Could not locate all script fields in the mod file (%d found, %d expected).'
                 % (len(matches), len(entries)))
    for entry, match in zip(entries, matches):
        start = match.end() - 1  # opening quote of the value
        value, end = scanstring(raw, start + 1)
        if match.group(1) != entry['field'] or value != entry['value']:
            sys.exit('Script fields in the mod file are not in the expected order.')
        entry['span'] = (start, end)
    return entries


def file_name(entry):
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', entry['name']).strip().rstrip('.') or 'Object'
    return '%s.%s%s' % (name, entry['guid'], FIELDS[entry['field']])


def script_files(directory):
    """(guid, ext) -> path for every script file in the directory."""
    files = {}
    if not os.path.isdir(directory):
        return files
    for fname in sorted(os.listdir(directory)):
        match = FILE_PATTERN.match(fname)
        if not match:
            continue
        key = (match.group('guid').lower() if match.group('guid') != GLOBAL_GUID else GLOBAL_GUID,
               match.group('ext'))
        if key in files:
            sys.exit('Two script files for the same object: %s and %s'
                     % (os.path.basename(files[key]), fname))
        files[key] = os.path.join(directory, fname)
    return files


def entry_key(entry):
    guid = entry['guid'] if entry['guid'] == GLOBAL_GUID else entry['guid'].lower()
    return guid, FIELDS[entry['field']][1:]


def extract(mod, directory):
    raw = read_text(mod)
    os.makedirs(directory, exist_ok=True)
    existing = script_files(directory)
    wanted = {}
    for entry in find_slots(raw):
        if entry['value'].strip() == '' and entry['guid'] != GLOBAL_GUID:
            continue
        key = entry_key(entry)
        if key in wanted:
            sys.exit('Several objects with GUID %s have scripts; cannot extract them separately.' % entry['guid'])
        wanted[key] = (file_name(entry), entry['value'])

    for key, path in existing.items():
        if key not in wanted or os.path.basename(path) != wanted[key][0]:
            os.remove(path)
            print('removed  ', os.path.basename(path))
    for key, (fname, value) in sorted(wanted.items(), key=lambda kv: kv[1][0].lower()):
        path = os.path.join(directory, fname)
        if not os.path.exists(path) or read_text(path) != value:
            write_text(path, value)
            print('extracted', fname)
    print('%d script files in %s' % (len(wanted), os.path.relpath(directory, ROOT)))


def compose(mod, directory):
    """Return (new mod text, list of changed file names)."""
    raw = read_text(mod)
    files = script_files(directory)
    entries = find_slots(raw)

    counts = {}
    for entry in entries:
        counts[entry_key(entry)] = counts.get(entry_key(entry), 0) + 1

    used = set()
    changes = []
    pieces = []
    position = 0
    for entry in entries:
        key = entry_key(entry)
        path = files.get(key)
        if path is not None:
            if counts[key] > 1:
                sys.exit('Several objects in the mod have GUID %s; cannot tell which one %s belongs to.'
                         % (entry['guid'], os.path.basename(path)))
            value = read_text(path)
            used.add(key)
        else:
            value = ''  # no file: the object has no script
        if value != entry['value']:
            start, end = entry['span']
            pieces.append(raw[position:start])
            pieces.append(json.dumps(value, ensure_ascii=False))
            position = end
            changes.append(os.path.basename(path) if path else '%s (cleared)' % file_name(entry))
    pieces.append(raw[position:])

    unknown = [os.path.basename(path) for key, path in files.items() if key not in used]
    if unknown:
        sys.exit('No object in the mod matches these files: ' + ', '.join(unknown))

    new_raw = ''.join(pieces)
    json.loads(new_raw)  # still valid JSON
    return new_raw, changes


def build(mod, directory):
    new_raw, changes = compose(mod, directory)
    if not changes:
        print('mod file already up to date')
        return
    write_text(mod, new_raw)
    for change in changes:
        print('updated  ', change)


def check(mod, directory):
    _, changes = compose(mod, directory)
    if changes:
        print('out of sync: ' + ', '.join(changes))
        sys.exit(1)
    print('in sync')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('command', choices=['extract', 'build', 'check'])
    parser.add_argument('--mod', default=DEFAULT_MOD, help='mod JSON file (default: %(default)s)')
    parser.add_argument('--dir', default=DEFAULT_DIR, help='scripts directory (default: %(default)s)')
    args = parser.parse_args()
    {'extract': extract, 'build': build, 'check': check}[args.command](args.mod, args.dir)


if __name__ == '__main__':
    main()
