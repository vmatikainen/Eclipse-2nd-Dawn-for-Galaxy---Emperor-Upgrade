"""Rebuild a local mod JSON from the repository.

The mod JSON is not in git (it is one huge file of one-line scripts that diffs badly).
Everything we change in it is reproducible from the repository:
  1. scripts/ are written into it                               (tools/tts_scripts.py build)
  2. our object changes are applied                             (tools/apply_object_fixes.py)
  3. player board snap points are put into the canonical order  (tools/normalize_board_snaps.py)
  4. the mod's thumbnail (<mod>.png next to the JSON, shown in TTS and used as the Workshop
     preview when uploading) is assets/workshop_cover_square.png: only for our mod file

Usage (run from the repository root):
    python tools/rebuild_mod.py                       rebuild ./3844682665.json
    python tools/rebuild_mod.py --mod "<save>.json"   rebuild another mod or save file

Our mod is Workshop item 3844682665. Any copy of the mod works as the starting point,
including the plain Steam Workshop download of the original mod (item 2348417296) copied to
3844682665.json; the result is the same.
"""
import argparse
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_MOD = os.path.join(ROOT, '3844682665.json')
THUMBNAIL = os.path.join(ROOT, 'assets', 'workshop_cover_square.png')
WORKSHOP_HINT = """No mod file at {path}.
Copy the Workshop download of the original mod there first (as 3844682665.json), from
  macOS:   ~/Library/Tabletop Simulator/Mods/Workshop/2348417296.json
  Windows: Documents\\My Games\\Tabletop Simulator\\Mods\\Workshop\\2348417296.json
(subscribe to Workshop item 2348417296 in Steam if it isn't there), then run this again."""


def run(*args):
    result = subprocess.run([sys.executable, *args], cwd=ROOT)
    if result.returncode != 0:
        sys.exit(result.returncode)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--mod', default=DEFAULT_MOD, help='mod or save JSON to rebuild (default: %(default)s)')
    args = parser.parse_args()

    mod = os.path.abspath(args.mod)
    if not os.path.isfile(mod):
        print(WORKSHOP_HINT.format(path=mod), file=sys.stderr)
        sys.exit(1)

    print('== scripts/ -> mod')
    run(os.path.join('tools', 'tts_scripts.py'), 'build', '--mod', mod)
    print('== object fixes')
    run(os.path.join('tools', 'apply_object_fixes.py'), '--mod', mod)
    print('== player board snap points')
    run(os.path.join('tools', 'normalize_board_snaps.py'), '--mod', mod)
    # a save keeps its own thumbnail
    if os.path.basename(mod) == os.path.basename(DEFAULT_MOD) and os.path.isfile(THUMBNAIL):
        print('== thumbnail')
        shutil.copyfile(THUMBNAIL, os.path.splitext(mod)[0] + '.png')
    print(f'\nRebuilt {mod}. Load it again in Tabletop Simulator to see the changes.')


if __name__ == '__main__':
    main()
