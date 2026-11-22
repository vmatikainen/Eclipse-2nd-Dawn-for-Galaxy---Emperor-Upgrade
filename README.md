# Eclipse: Second Dawn for the Galaxy – Emperor Upgrade

A modified version of the Tabletop Simulator Workshop mod
*Eclipse: Second Dawn for the Galaxy [Scripted]* (Workshop ID `2348417296`).
It adds turn order options, including the **Pass order** house rule (see below).

## Repository layout

| Path | What it is |
|---|---|
| `scripts/` | The mod's scripts as readable files. **Edit these.** |
| `tools/rebuild_mod.py` | Rebuilds your local mod file from the repository (scripts and board snap points). |
| `tools/tts_scripts.py` | Copies scripts between `scripts/` and a mod file. |
| `tools/apply_object_fixes.py` | Applies our changes to objects in the mod file (e.g. sector tiles aligned in their bags). |
| `tools/normalize_board_snaps.py` | Gives every player board's snap points the same numbering (see CLAUDE.md). `--check` reports boards that don't follow it. |
| `scripts/include/` | Script files pulled into other scripts with `#include Name` (same format as the VS Code TTS extension). |
| `tools/reference_sheets.py` | Draws `reference/ship-parts.svg`, `reference/ancient-tech.svg` and `reference/npc-ships.svg`: every ship part, ancient ship part and NPC ship variant, with the stats our data records. |
| `tools/annotate_boards.py` | Draws each player board's snap points, numbered, into `board-maps/index.html`. |
| `.claude/skills/` | Project skills for Claude Code, e.g. `pull-main`. |

**The mod file `2348417296.json` is not in git.** It holds every object on the table with
all scripts as one-line strings, which makes diffs unusable. Each developer keeps a local
copy and rebuilds it from the repository. Everything we change in it is reproducible:

- the scripts come from `scripts/`
- the changes to objects come from `tools/apply_object_fixes.py`
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

Changes to objects (positions, bag settings, snap points, new objects) live only in the mod
file, which isn't in git. Make them reproducible:

- add a rule to `tools/apply_object_fixes.py`, or
- write a tool that `rebuild_mod.py` runs, as `normalize_board_snaps.py` does for the board
  snap points.

Otherwise they are lost on the next rebuild, and the other developer never gets them. If
you made the change in the game, compare your save with a rebuilt mod to see what changed.

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

## Turn order and starting player

Two dropdowns under *Turn Order* in the setup popup. Hover over their labels for an
explanation.

**Turn order**

- **Rotating** (default): the base game. Play goes clockwise from the start player. Pass
  by flipping your *Actions* card face down. The first player to pass gets the start
  player tile and starts the next round. The second gets the *Direction of Play* card:
  flip it to choose the direction, and right-click it → *Update direction* to change the
  direction during the round. A small *Passed* list at the top right shows who passed.
- **Pass order** (formerly the *Advanced Turn Order* house rule): each round is played in
  the order the players passed in the round before. To pass, flip your *Actions* card
  face down during your own turn. Your turn ends at once and you take the best free turn
  order position for the next round. A small *Next round* list at the top right shows it.
  Passed players still get turns, so they can take reactions as in the base rules. To
  skip them instead, set `ATO_KEEP_TURNS_AFTER_PASS = false` in `scripts/Global.-1.lua`.

**Starting player**

- **Yellow** (default): the Yellow player starts. If nobody sits at Yellow, the next
  seated player after it does.
- **Random:** a random player starts. With *Pass order* the whole round 1 turn order is
  random, revealed one player at a time.
- **Draft** (*Pass order* only): after *Setup*, players are put in a random draft order,
  revealed one at a time. On their turn, each player takes either the best free race pick
  position or the best free turn order position, and is put in the last free position of
  the other track at the same time. The last player in the draft gets the remaining
  positions automatically. With *Rotating*, or with *Random races*, *Draft* works as
  *Random*.

So the old Advanced Turn Order is *Pass order* + *Draft*.

**Race selection** always comes after *Setup*, one player at a time: in reverse turn
order (the player before the starting player picks first, the starting player last), or
in the drafted race pick order. Only the player whose turn it is to pick sees the race
buttons. A panel shows the race pick order and the round 1 turn order meanwhile.

The starting techs are drawn at *Setup*. Tick **Tech setup after race selection** under
*House Rules* (off by default) to draw them once every player has a race instead. It
works with every turn order and starting player.

## Randomize seat order

Tick **Randomize seat order** under *House Rules* in the setup popup, and pick when it
happens in the dropdown next to it:

- **Before drafting:** when *Setup* is pressed, before the draft. Without *Draft* as the
  starting player this works like *Before race selection*.
- **Before race selection:** after the draft, or when *Setup* is pressed (before the
  starting player is chosen) if there is no draft.
- **After race selection** (default): players pick factions first, but nothing is set
  up yet. Once everyone has picked, the seats are randomized and each faction is set up
  at its player's new seat. The seats people sit at before that decide nothing, so
  (except with *Draft*) races are picked in a random order, and the starting player
  setting isn't used: the last player to pick starts, and play goes clockwise from
  their new seat.

The seated players are moved to a random order of the seats they already use, by
changing their player colors. Draft results, race picks and the turn order go with the
player. This works in hot seat too:
the hot seat players are moved between the colors in the same way.

## Random races

Tick **Random races** under *Options* in the setup popup. Nobody picks a race: after
*Setup*, every seated player is given a random one.

- The six Terran races count as one race in the draw. A player who draws it gets the
  Terran race of their own color (Purple gets the black one, Terran Alliance).
- Pyxis Unity is never drawn. Expansion races are only drawn with *Expansion Species*.
- Races are given out in race pick order (reverse turn order). There is no draft:
  *Draft* as the starting player works as *Random*.
- **Randomize seat order** works with it as with picked races.

## Combat simulator

Every player board has a **Combat Sim** button, between the Actions card and the
Interceptor blueprint. It opens a panel where you set how many interceptors, cruisers and
dreadnoughts attack, then pick the opponent: **Ancient**, **2 Ancients**, **GCDS**, or
**Guardian** (shown when a Guardian is on the table). It plays 1000 or 5000 random
battles (*Battles: 1k / 5k* at the top of the panel, 5k by default) and shows the odds of
winning and, when winning, how many of each ship survive on average.

- Your ships are your blueprints as they are now, including upgrades. The NPCs are the
  variants this game uses (randomized Ancients, Guardians and GCDS included).
- Missiles fire first, then cannons in initiative order; on a tie the NPC fires first.
- Ships without cannons (missile boats) escape after firing their missiles. They count as
  survivors when the battle is won.
- NPCs hit the biggest ship they can destroy, else the biggest ship.
- Rift cannons roll the rift die: miss, 1 damage, 2 damage, 3 damage + 1 self damage,
  1 self damage, miss. Their hits ignore computers and shields. Self damage goes to your
  own ships with rift weapons: it destroys the largest ship it can, else hits the largest.
- Not simulated: retreating (other than missile boats) and Starbases.

## Player colors and hot seat

The table has seats for six player colors: **White, Red, Yellow, Blue, Green and Purple**.
Black is the game master's seat and doesn't take part.

Don't seat players at any other color. Orange has no seat at this table, and Pink, Teal
and Brown aren't known to the mod. A player at one of those colors breaks faction setup
(for example with *"You already selected nil"*) and the turn order draft.

**Hot seat:** the screen moves to whoever is due to choose, pick a faction or play. When you set up hot seat, give each player one of the
six colors above.
