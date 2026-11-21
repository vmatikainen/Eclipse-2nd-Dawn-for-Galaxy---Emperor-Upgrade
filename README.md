# Eclipse: Second Dawn for the Galaxy – Emperor Upgrade

A modified version of the Tabletop Simulator Workshop mod
*Eclipse: Second Dawn for the Galaxy [Scripted]* (Workshop ID `2348417296`).
It adds an optional **Advanced Turn Order** house rule (see below).

## Repository layout

| Path | What it is |
|---|---|
| `2348417296.json` | The mod file Tabletop Simulator loads. It contains every object on the table, with all scripts embedded as one-line strings. |
| `scripts/` | The scripts from the mod file as readable files. **Edit these.** |
| `tools/tts_scripts.py` | Copies scripts between `scripts/` and the mod file. |

Script files are named the way the VS Code Tabletop Simulator extension names them:

- `Global.-1.lua` and `Global.-1.xml`: the global script and the on-screen UI.
- `<Object Name>.<GUID>.lua`: a script attached to an object, for example `Next Round.3d6d3a.lua`.

The rest of this folder (other Workshop mods, thumbnails, `WorkshopFileInfos.json`)
belongs to Tabletop Simulator and is ignored by git.

## Requirements

Python 3, with no extra packages. Run the commands from the repository root:

```
python tools/tts_scripts.py build     # scripts/  ->  2348417296.json
python tools/tts_scripts.py extract   # 2348417296.json  ->  scripts/
python tools/tts_scripts.py check     # are they in sync? (exit code 1 if not)
```

## Workflow

### Edit the script files (recommended)

1. Edit the files in `scripts/`.
2. Run `python tools/tts_scripts.py build`. Only the scripts you changed are rewritten
   in `2348417296.json`; the rest of the file stays byte-for-byte identical.
3. In Tabletop Simulator, load the mod again (*Games → Workshop*). A mod that is already
   open doesn't pick up the change until it is loaded again.
4. Commit both the changed script files and `2348417296.json`.

### Edit in the game, or with the VS Code extension

The extension's *Save and Play* and the in-game script editor change the game that is
running, not `2348417296.json`. To keep those changes:

1. Save the game in Tabletop Simulator. It writes a save file such as
   `Saves/TS_Save_12.json` (under `Documents/My Games/Tabletop Simulator/`), not the mod file.
2. Pull the scripts out of that save into `scripts/`:
   ```
   python tools/tts_scripts.py extract --mod "../../Saves/TS_Save_12.json"
   ```
3. Run `python tools/tts_scripts.py build` to write them into `2348417296.json`.
4. Check `git diff scripts/` and commit.

Pick one place to make changes at a time. If you edit both the script files and the
running game, the next extract or build overwrites one side.

### Before committing

Run `python tools/tts_scripts.py check`. It reports any script that differs between
`scripts/` and the mod file, so you don't commit one without the other.

## How the tool works

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

- **Steam updates overwrite the mod file.** If the original Workshop item is updated,
  Tabletop Simulator may download it again over `2348417296.json`. Git shows that as a
  change you can inspect, discard (`git checkout -- 2348417296.json`), or merge with
  `extract`.
- Don't edit scripts directly inside `2348417296.json`. The next `build` replaces any
  script whose file differs.

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
