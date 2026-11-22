# Eclipse: Second Dawn for the Galaxy – Emperor Upgrade

A modified version of the Tabletop Simulator Workshop mod
*Eclipse: Second Dawn for the Galaxy [Scripted]* (Workshop ID `2348417296`).
It adds an optional **Advanced Turn Order** house rule (see below).

## Repository layout

| Path | What it is |
|---|---|
| `scripts/` | The mod's scripts as readable files. **Edit these.** |
| `tools/rebuild_mod.py` | Rebuilds your local mod file from the repository (scripts and board snap points). |
| `tools/tts_scripts.py` | Copies scripts between `scripts/` and a mod file. |
| `tools/normalize_board_snaps.py` | Gives every player board's snap points the same numbering (see CLAUDE.md). `--check` reports boards that don't follow it. |
| `tools/annotate_boards.py` | Draws each player board's snap points, numbered, into `board-maps/index.html`. |
| `.claude/skills/` | Project skills for Claude Code, e.g. `pull-main`. |

**The mod file `2348417296.json` is not in git.** It holds every object on the table with
all scripts as one-line strings, which makes diffs unusable. Each developer keeps a local
copy and rebuilds it from the repository. Everything we change in it is reproducible:

- the scripts come from `scripts/`
- the player board snap points come from `tools/normalize_board_snaps.py`

Starting from the plain Workshop download of the original mod gives exactly the same result.

Script files are named the way the VS Code Tabletop Simulator extension names them:

- `Global.-1.lua` and `Global.-1.xml`: the global script and the on-screen UI.
- `<Object Name>.<GUID>.lua`: a script attached to an object, for example `Next Round.3d6d3a.lua`.

## Requirements

Python 3, with no extra packages. Run the commands from the repository root.

### First time: get a mod file

Copy the Workshop download of the original mod (subscribe to Workshop item `2348417296` in
Steam) into the repository root as `2348417296.json`. TTS keeps it in:

- macOS: `~/Library/Tabletop Simulator/Mods/Workshop/2348417296.json`
- Windows: `Documents\My Games\Tabletop Simulator\Mods\Workshop\2348417296.json`

Then rebuild it:

```
python tools/rebuild_mod.py                      # rebuild ./2348417296.json
python tools/rebuild_mod.py --mod "<save>.json"  # or rebuild another mod or save file
```

How you get the rebuilt file into Tabletop Simulator is up to you: copy it into the
Workshop folder above, or work in a save file and pass it with `--mod`.

## Workflow

### After every pull from main

Rebuild your local mod file: `python tools/rebuild_mod.py`. Otherwise TTS keeps loading the
old scripts and board snap points. In Claude Code, the `pull-main` skill does the pull and the
rebuild together.

### Edit the script files (recommended)

1. Edit the files in `scripts/`.
2. Run `python tools/rebuild_mod.py`.
3. Get the rebuilt file into TTS and load the mod again (*Games → Workshop*). A mod that is
   already open doesn't pick up the change until it is loaded again.
4. Commit the changed script files.

### Edit in the game, or with the VS Code extension

The extension's *Save and Play* and the in-game script editor change the game that is
running, not the mod file. To keep those changes:

1. Save the game in Tabletop Simulator. It writes a save file such as
   `Saves/TS_Save_12.json` under the Tabletop Simulator folder.
2. Pull the scripts out of that save into `scripts/`:
   ```
   python tools/tts_scripts.py extract --mod "<path to>/Saves/TS_Save_12.json"
   ```
3. Check `git diff scripts/` and commit.

Pick one place to make changes at a time. If you edit both the script files and the
running game, the next extract or rebuild overwrites one side.

### Changing objects, not scripts

Changes to objects (positions, snap points, new objects) live only in the mod file, which
isn't in git. Make them reproducible with a tool in `tools/` that `rebuild_mod.py` runs, as
`normalize_board_snaps.py` does for the board snap points. Otherwise they are lost on the
next rebuild, and the other developer never gets them.

## How the script tool works

- Scripts are matched to objects by **GUID**, not by name, so renaming an object in the
  game doesn't break anything. After a rename, `extract` renames the file to match.
- **Deleting** a script file clears that object's script on the next `build`.
- **Adding** a script to an object that has none: create `<Any Name>.<GUID>.lua` with
  that object's GUID, then `build`. A file whose GUID matches no object is an error,
  and nothing is written.
- Only objects with a non-empty script get a file. `Global.-1.lua` and
  `Global.-1.xml` always exist.
- Scripts inside bags and decks (contained objects) are included too.
- Line endings are kept exactly as they are; `.gitattributes` stops git from converting them.

## Caveats

- **Steam updates can overwrite the Workshop copy** of `2348417296.json` in the TTS folder.
  Run `python tools/rebuild_mod.py` on it again, or copy your rebuilt file back.
- Don't edit scripts directly inside the mod file. The next rebuild replaces any script
  whose file differs.

## Advanced Turn Order house rule

Turn it on with the **Advanced Turn Order** checkbox under *House Rules* in the setup popup.

1. **Draft:** after *Setup*, players are put in a random draft order. On their turn,
   each player takes either the best free race pick position or the best free turn order
   position. They are put in the last free position of the other track at the same time.
2. **Faction selection:** factions must be selected in race pick order.
3. **Play:** round 1 follows the drafted turn order. To pass, flip your *Actions* card face
   down during your own turn. Your turn ends at once and you take the best free turn
   order position for the next round. Each new round's order is the pass order of the
   previous round.

While drafting and selecting factions, a panel shows all the positions. During play, the
built-in turn indicator (top right) shows the current order, with the next round's order
listed below it. Passed players still get turns, so they can take reactions as in the base
rules. To skip them instead, set `ATO_KEEP_TURNS_AFTER_PASS = false` in `scripts/Global.-1.lua`.
