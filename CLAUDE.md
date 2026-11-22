# CLAUDE.md

Guidance for working in this repository.

## Purpose

A fork of the Tabletop Simulator (TTS) Workshop mod *Eclipse: Second Dawn for the Galaxy
[Scripted]* (Workshop ID `2348417296`), developed as a personal project by two friends.
The goal is to add functionality and quality-of-life features for playing Eclipse in TTS.

- Already added: the **Advanced Turn Order** house rule (see README).
- In progress: **combat zone automation**. Take the units in a contested hex, move them
  to a combat area, and pick the right dice for each player to throw. The groundwork is
  **ship state**: knowing which race each player color has and what is on each of their
  ship blueprints.

This will be published under **our own Workshop ID** (not yet created). It is a permanent
fork: we don't merge updates from the original mod, and we refactor the original code
step by step as features need it. Don't rewrite large untouched areas in one go. There
are no automated tests, and every change has to be checked by playing in TTS.

**Pyxis Unity is deprecated** and will be removed from our mod. Don't support its special
rules (Deathmoons, its custom board layout, Pyxis population) in new features, and don't
spend effort fixing its existing code. New code can skip it. Its existing setup code
(`Faction.Name == 'Pyxis Unity'` branches in Global, `Button Pyxis Unity`) stays until
the removal is done as its own change.

## The game, briefly

Eclipse: Second Dawn for the Galaxy is a 4X board game for **1–6 players**. Each player
picks a **race** (faction). Every race has its own player board, starting resources and
ship blueprints.

- **Ships:** Interceptor, Cruiser, Dreadnought, Starbase. Some races differ: Exiles have
  an **Orbital** in place of the Starbase, Rho Indi have no Dreadnought. (Pyxis Unity's
  Deathmoons are out of scope, see above.) NPC ships are Ancients, Guardians and the GCDS (Galactic Center Defense
  System).
- **Blueprints:** each ship type has a blueprint on the player board with a fixed number of
  **slots**. Slots are printed with default parts (or left empty). The board also prints
  values outside the slots, such as initiative chevrons by the ship name, base energy,
  and race bonuses. Examples: the Exiles Orbital has a printed base of 2 hull and
  4 energy, and Rho Indi's interceptor has a printed "-1" box.
- **Upgrading:** a player puts a ship part tile on a slot. The tile replaces whatever was
  printed there. We don't support stacking tiles on tiles.
- **Combat** (what the combat zone will automate): ships fire in initiative order. Each
  weapon rolls its own dice colour: Ion yellow (1 damage), Plasma orange (2), Soliton
  blue (3), Antimatter red (4), Rift pink (rift rules). A roll of 6 always hits and 1
  always misses. Otherwise a hit needs roll + computers − target shields ≥ 6. Missiles
  fire once, before cannons. Damage is absorbed by hull.
- **Draco and the Ancients:** Descendants of Draco are friendly **only with the Ancients**.
  Draco ships share a hex with Ancients without combat. They still fight Guardians and the
  GCDS like any other race. The mod tags Guardian and GCDS objects `Alien Not Draco Friend`.

When a rule detail matters for code, confirm it with the user rather than relying on
memory. Rule books are in the mod as `Rulebook` PDFs.

## Repository layout

| Path | What it is |
|---|---|
| `2348417296.json` | **Local only, git-ignored.** The mod file TTS loads: every object on the table, scripts embedded as one-line strings. Rebuilt from the repo with `tools/rebuild_mod.py`. Will be renamed when we get our own Workshop ID. |
| `scripts/` | Scripts extracted from the mod file. **Edit these**, never the JSON directly. |
| `tools/rebuild_mod.py` | Rebuilds a local mod file from the repo: `tts_scripts.py build` + `apply_object_fixes.py` + `normalize_board_snaps.py`. `--mod` for another file. |
| `tools/apply_object_fixes.py` | Rules for our changes to objects in the mod JSON: sector tiles aligned in their bags, Reputation bag drawing in random order. `--check` exits 1 if a rule still needs applying. |
| `tools/tts_scripts.py` | `extract` / `build` / `check` scripts between `scripts/` and the mod JSON. |
| `tools/normalize_board_snaps.py` | Puts every player board's snap points into the canonical order (see "Snap point convention"). `--check` exits 1 if a board isn't normalized. Edits only the boards' snap point arrays. |
| `tools/annotate_boards.py` | Draws every player board's snap points, numbered and coloured by tag, on its image → `board-maps/`. Re-run after changing board snap points. |
| `.claude/skills/pull-main/` | Project skill: pull `main`, then rebuild the local mod JSON. |
| `scripts/include/*.ttslua` | Include files, pulled into a script by an `#include Name` line (see "Includes"). Ship data and ship state live here. |
| `tools/reference_sheets.py` | Draws `reference/ship-parts.svg`, `reference/ancient-tech.svg` and `reference/npc-ships.svg`: every ship part tile, ancient (Discovery) ship part and NPC ship variant, with the stats recorded in `ShipData`. |
| `reference/` | Generated by `reference_sheets.py` and committed. The images are linked from Steam. |
| `board-maps/` | Generated by `annotate_boards.py` and committed: `index.html` plus one SVG per race. The SVGs link to the board images on Steam (viewing needs internet). `board-maps/images/` is a git-ignored download cache. Don't commit `--embed` output. |

`.gitignore` is an **allow-list** (`*` then `!path`). New tracked files or folders must be
added to it.

**The mod JSON is not in git.** It diffs badly, so each developer keeps a local copy and
rebuilds it. Starting from the plain Workshop download of item 2348417296,
`rebuild_mod.py` gives exactly our mod. So:
- **After every pull from `main`, rebuild the local JSON.** Use the `pull-main` skill, or
  run `python tools/rebuild_mod.py`.
- **Workflow:** edit `scripts/` → `python tools/rebuild_mod.py` → get the file into TTS and
  load it again → commit `scripts/`.
- **Changes to objects** (positions, bag settings, snap points, new objects) only exist in the
  JSON. To keep them, add a rule to `apply_object_fixes.py`, or write a tool that
  `rebuild_mod.py` runs (like `normalize_board_snaps.py`). Otherwise the next rebuild loses
  them and the other developer never gets them. When merging work that changed the JSON,
  compare the objects (not the scripts) between the merge base and the other side, and
  turn every difference into such a rule.

Python 3, standard library only, no extra packages. Full details are in README.md.

The repo can live outside TTS's folders. How each developer gets the built mod file into
TTS is a personal setup and not part of the repo. On macOS, TTS can't follow a symlink into
`~/Documents`, because privacy protection blocks it, so copy the file instead. One
developer edits directly in their TTS save folder, and their changes come into git through
`tts_scripts.py extract --mod <save>.json`. A save stores the whole table, not just scripts,
so only extract from a save of a clean setup state.

## How the code works

TTS Lua is MoonSharp, roughly Lua 5.2. There is no `require`. Object scripts call into
Global with `Global.call('FunctionName', params)`. API reference:
https://api.tabletopsimulator.com/

### Script files

- `Global.-1.lua` (~2500 lines): setup, rounds, player setup, utilities, the event
  handlers, and the Advanced Turn Order code (`ATO_*`, near the end of the file). It's
  being split into components, see "Includes".
- `include/ShipData.ttslua`, `include/ShipState.ttslua`, `include/HexState.ttslua`: ship data, ship
  state and hex state, included in Global.
- `include/SeatOrder.ttslua`: the "Randomize seat order" setup option (`SEAT_*`). Global
  calls it from `gameSetup`, `PlayerSetup` (which records picks for later and sets up
  factions through `placeFaction`), the Advanced Turn Order and the turn order panel.
- `include/RandomRaces.ttslua`: the "Random races" setup option (`RandomRaces_*`). It gives
  races out through `PlayerSetup`, reading each race button's faction table with
  `getTable`. Global calls it from `gameSetup`, `PlayerSetup` and the Advanced Turn Order
  (`ATO_beginDraft` skips the draft, `ATO_advanceRacePick` gives the current race).
- `Global.-1.xml`: on-screen UI (setup popup, Advanced Turn Order panel).
- `Button <Race>.<guid>.lua`: one per race. Each holds a faction table (`Name`,
  `startingShip`, `numStartingShips`, resources, `Influence`, `Box_GUID`, population
  positions) and, on click, calls `Global.call('PlayerSetup', {PlayerColor, Faction})`.
- `Player Board.<guid>.lua`: a few boards carry an `initialTechs` table.
- `Homeworld.<guid>.lua`, `Next Round`, bag scripts: small helpers.

### Includes

A line `#include Name` in a Lua script is replaced on build by `scripts/include/Name.ttslua`,
wrapped in `---- #include Name` marker lines. This is the VS Code TTS extension's format, so
the extension's own includes work the same way. `tts_scripts.py extract` folds marked
blocks back into the include files, so edits made in TTS end up in the right file.

**Components.** We split Global's functionality into clearly named component files, one
per feature (`ShipData`, `ShipState`, …). Global stays as the entry point: shared
constants, `onLoad`/`onSave`, the `#include` lines, and every TTS event handler. The rules:

1. **New features go in their own include file.** Global only gets the `#include` line
   and calls from its event handlers.
2. **Event handlers live only in Global.** All files become one script, so a second
   `onObjectDrop` (or any `on*` handler) in another file silently replaces the first,
   without an error. Global's handler calls into each component instead, e.g.
   `onObjectDrop` → `ShipState_onDrop(obj)`. The same goes for any function name: no two
   files define the same one.
3. **Every function and global variable in a component has the component's prefix**
   (`ATO_`, `ShipState_`). All files share one namespace, and the prefix is the only
   protection.
4. **Original code moves out when a feature touches it,** or in a commit that only moves
   code without editing it, so it can be reviewed with `git diff --color-moved`. Each move
   is play-tested in TTS like any change. Don't move large untouched areas in one go.
5. **Include order matters for top-level code.** A file that reads another file's
   variables at load time must be included after it. Calls made inside functions work in
   any order.

TTS error line numbers point into the combined script, so subtract to find the line in a
component. `Global.-1.xml` can't be split: includes only work in Lua.

### Objects and GUIDs

Every object has a six-character **GUID**. Scripts find objects with `getObjectFromGUID`.
Fixed GUIDs (bags, templates) are constants at the top of Global. A GUID normally
survives being taken out of a bag, but TTS assigns a new one if it would clash. Record
the GUID of the object you actually took out rather than hard-coding the one in the bag.

### Player setup and ownership

- **Seats:** the table has hand zones for **White, Red, Blue, Purple, Green, Yellow** (plus
  a non-player Black zone). `PlayerSetup` lays out a player's whole area relative to their
  hand position (`Player[color].getHandTransform()`).
- **Hot seat:** only the six seat colors work. Seating someone at Orange (no hand zone) or at
  Pink, Teal or Brown (not in `PlayerSelection`) breaks faction setup. The README documents
  this for players. With the Advanced Turn Order, hot seat picks are made for whoever's turn
  it is (`ATO_canPickRace` returns the color to use).
- **Known issue, no fix yet: hot seat picks player colors before the game file loads.**
  TTS's hot seat mode makes you pick the seat colors before the mod is loaded. So the
  scripts start with players already seated, which they don't expect, and many scripts
  misbehave in odd ways as a result. When a bug is strange and only shows in hot seat,
  suspect this first, before debugging the feature's own code. The other contributor is
  working on it.
- **`PlayerState[color] = { faction, boardGUID }`** (section at the end of Global) is the
  saved color → race record. `PlayerSetup` records it once a faction is set up. `onSave`
  stores it in the save next to `settings` and `ATOState`. `onLoad` restores it whatever the
  round, because factions can be picked before *Setup*. Read it through
  `PlayerState_faction(color)` and `PlayerState_board(color)`.
- **`PlayerSelection[color] = faction name`** comes from the original mod and is still used
  by `PlayerSetup` and the Advanced Turn Order code. It isn't saved itself. `PlayerState_restore`
  fills it in again on load. It only has entries for White, Red, Blue, Purple, Green,
  Orange and Yellow. Any other color reads as `nil`, and `PlayerSetup` treats that as
  "already selected".
- **Ownership on the table is mostly by position.** Player boards, faction sheets, control
  boards, ambassadors and colony ships carry no color. **Ships** do: `PlaceShip` sets their
  tint and **memo `"Ship <Color> <ship>"`** (e.g. `"Ship Red interceptor"`, read it with
  `ShipState_shipOf(obj)`). Their name is `"Red - Interceptor"` and their Description is the
  ship's current stats (see "Ship data and ship state"). Don't read the color from the name
  or Description. Influence discs and population cubes are
  tinted with the color. Action cards are tracked in `ATO.actionCards[guid] = color`.

### Player boards and blueprints

- Each race's `Player Board` (`Custom_Tile`, tag `PlayerBoard`) has its **race name in
  Description**. Some names have stray spaces or odd case (`'Orion Hegemony '`,
  `'Enlightened of lyra'`), so compare trimmed and case-insensitive.
- A board is one flat object. Its only structure is **snap points**, numbered by their order
  in the board's `AttachedSnapPoints` (= `board.getSnapPoints()[n]` in Lua, the number shown
  in `board-maps/`). All boards follow the **snap point convention** below.
- **Snap point tags** restrict what snaps there: only objects sharing a tag snap to a tagged
  point, and untagged points accept anything. The tags in use are:
  - `Influence`, `Reputation`, `Ambassador`
  - `TechTile` and `Discovery` (Magellan)
  - `Population` (deprecated Pyxis)
  - `Unused`, for placeholders. Nothing has this tag, so nothing snaps to them.
- Snap points use board-local coordinates. Local x is **mirrored** against the image (the
  Interceptor is on the image's left and at local +x). Local z runs top (−) to bottom (+).
- Real slots per ship (Interceptor/Cruiser/Dreadnought/Starbase):
  - most races: 4/6/8/5
  - Planta: 3/5/7/4 (printed bonus boxes in place of the others)
  - Exiles: 4/6/8/3. The Orbital uses Starbase cells 2, 3 and 4.
  - Rho Indi: 4/6/–/5. Its Cruiser is printed in the middle of the board.
  - Lyra: 4/6/8/5
  - Pyxis Unity: deprecated, not normalized

### Snap point convention

Every player board (except deprecated Pyxis) has the same numbering, so code can use fixed
numbers on any board. Each range is sized for the race with the most points in that
group. Where a race lacks a slot, the number holds an `Unused` placeholder at the spot the
slot would be. `tools/normalize_board_snaps.py` enforces this. Run it with `--check` after
editing boards in TTS.

| Numbers | Group | Notes |
|---|---|---|
| 1–6 | Actions: EXP, RES, UPG, BUI, MOV, INF | tag `Influence` |
| 7–10 | Interceptor slots | cells, see below |
| 11 | Interceptor Muon Source | |
| 12–17 | Cruiser slots | |
| 18 | Cruiser Muon Source | |
| 19–26 | Dreadnought slots | Rho Indi: all placeholders |
| 27 | Dreadnought Muon Source | Rho Indi: placeholder |
| 28–32 | Starbase / Orbital slots | |
| 33 | Starbase / Orbital Muon Source | |
| 34–46 | Influence track, left to right | tag `Influence` |
| 47–53 | Military tech spaces 1–7, left to right | |
| 54–60 | Grid tech spaces 1–7 | |
| 61–67 | Nano tech spaces 1–7 | |
| 68–72 | Reputation / ambassador column, top to bottom | Keeps its tags. Placeholders fill the end on boards with 4. |
| 73 | Discovery spot | Magellan only, placeholder elsewhere |
| 74+ | Race-specific extras, left as they were | Lyra's points for its secondary board |

- **Blueprint cells** are numbered the same on every board: column by column, top to
  bottom, as printed on a standard board.
  - Interceptor: 1 left, 2 middle top, 3 middle bottom, 4 right.
  - Cruiser: 1–2 left column, 3–4 middle, 5–6 right.
  - Dreadnought: four columns of two.
  - Starbase: 1–2 left column, 3 middle, 4–5 right column.
  - So "Cruiser cell 5 = right column, top" means the same on every board.
- **Muon Source** is placed outside the blueprint. Its spot is right of the ship's name, above
  the right-hand column. On the Starbase/Orbital it's the top middle, covering the ⊠ symbol.
- **Every tech space has a snap point,** including spaces with a pre-printed start tech
  (e.g. Rho Indi's Gauss Shield at 54, Exiles' Orbitals at 61). This is for later UX, such
  as dragging a printed start tech to create its token.
- **Future idea (out of scope):** an influence disc dropped on snap 1–6 of a board could
  announce "{player} chose {action}". The owner comes from `PlayerState` (board → color).
  TTS has no "snapped to point n" event, so find the nearest snap point to the dropped disc,
  using `board.positionToLocal()`.
- **Ship parts:** `Custom_Tile`s tagged `ShipPart`, nickname = part name (`"Ion Cannon"`), from
  infinite bags named `<Part> Parts`. Some printed defaults have no tile (e.g. the Exiles
  Orbital's Ion Turret).

### Ship data and ship state

Both live in include files (`scripts/include/`, pulled into Global with `#include`):

- **`ShipData.ttslua`** is reference data, read from the part tiles, Discovery tiles and
  board images in the mod:
  - `SHIP_PARTS`: what each part does. `energy` is + produced / − used. `shield` is the
    shield's size, so a printed "−1" box is `shield = 1`. `cannons`/`missiles` list dice as
    `{color, count, damage}`, e.g. Plasma Cannon is **1 orange die, 2 damage**. Ancient parts
    have `ancient = true`. Rift dice have `rift = true`. There are also `jump` (Jump Drive)
    and `regenerate` (Morph Shield) flags.
  - `SHIP_BLUEPRINTS[faction][ship]`: `name`, `base` (printed values outside the slots) and
    `cells` (printed default per cell, in snap point order). `false` means an empty slot and
    `NO_SLOT` means the race has no slot there. The Exiles' Orbital is the `starbase` entry,
    named "Orbital". Rho Indi has no `dreadnought`. Pyxis isn't listed.
  - `DISCOVERY_PARTS`: Discovery tiles are all named "Discovery", so they're told apart by
    texture (CustomMesh DiffuseURL → part name).
  - `SHIP_TYPES` and `SHIP_SNAPS` give each ship's snap point range.
  - `NPC_SHIPS`: the 9 NPC variants (plain + 2 advanced each for Ancient, Guardian, GCDS),
    with the same stat fields as `SHIP_PARTS` plus `npc`. Each box printed on the miniature
    is one die. The two advanced variants share a name in the mod, so `NPC_TEXTURES` tells
    them apart by texture, e.g. "Advanced Guardian (Missiles)".
- **`ShipState.ttslua`**:
  - `ShipState_init(color, faction)` copies the race's blueprints to the player. It's
    called by `PlayerSetup`.
  - When a ship part tile (or ancient Discovery tile) is dropped on a blueprint slot of a
    player's board, it's recorded in that slot (`placed[cell]`).
  - Picking it up or deleting it removes it, so the printed default counts again.
  - Muon Source is only accepted on the Muon Source spot, and nothing else there. Stacked
    tiles and tiles on `Unused` placeholders aren't counted.
  - `ShipState_stats(color, ship)` returns `base` + the effective parts: initiative, computer,
    shield, hull, movement, energy, dice by colour, and warnings (not enough energy, no
    drive, drive on a Starbase).
  - **NPC ships** can't be upgraded: their state is the variant setup put on the table.
    `ShipState_npcOf(obj)` gives an object's variant, `ShipState_npcStats(variant)` its stats
    in the same shape as `ShipState_stats` (plus `npc` and `name`, no movement or energy).
    `ShipState_statsOf(obj)` works for any ship miniature, player or NPC, and is the entry
    point for the combat zone. NPC miniatures are named after their variant and get their
    stats as tooltip when they spawn (`onObjectSpawn`) and on load. The stock bags get the
    tooltip but keep their name. Right-clicking the table gives "Show NPC ships".
  - It isn't saved. `onLoad` rebuilds it with `ShipState_restore()` from `PlayerState` and the
    tiles on the boards. Right-clicking the table gives "Show my ships", which prints your ships.
  - **Ship miniatures show their stats as a tooltip.** `ShipState_markShip` (called by
    `PlaceShip`) sets the memo and name. `ShipState_updateTooltips(color, ship)` rewrites
    the Description of all that color's ships of that type whenever the blueprint changes,
    and of every ship after a load. Ships from saves made before the memo existed (name
    `Interceptor`, Description = color) are marked on load. Shrines and Deathmoons aren't marked.
- Global only has one-line hooks: in `PlayerSetup`, `onLoad`, `onObjectSpawn`, `onObjectDrop`,
  `onObjectPickUp` and `onObjectDestroy`.
- `tools/reference_sheets.py` draws `reference/ship-parts.svg`, `reference/ancient-tech.svg`
  and `reference/npc-ships.svg`: every part tile and NPC variant with the stats `ShipData`
  records for it. Re-run it after changing part or NPC data.

### Hex state

`HexState.ttslua` knows which sides have units in each hex, and the order they arrived in.
It's the input for the combat zone.

- **Hexes come from the lattice, not from tiles.** The Galactic Center is at (0, 0), and
  hexes are 11.92 apart with flat sides facing ±z, the same geometry `placeHomeworld` uses.
  `HexState_keyAt(position)` rounds any table position to an axial coordinate, key `"q,r"`.
  `HexState_center(q, r)` goes back. Sector III chains have no limit, and the grid doesn't
  snap, so tiles are only roughly aligned. A hex counts only while a sector tile (Sector
  1/2/3, Guardian Sector, Galactic Center, a Homeworld) lies on it, so ships in the supply
  areas are in no hex.
- **Units:** player ship miniatures (`ShipState_shipOf`), NPC ships (`ShipState_npcOf`) and the
  Exiles' Orbitals, which are their Starbases. An Orbital tile has no color. It counts as an
  Exiles ship when the hex's influence disc has the Exiles' color. Other races' Orbitals are
  population and don't count. Population cubes and discs aren't units.
- **Sides:** a player color, or `"Ancient"` / `"Guardian"` / `"GCDS"`. `HexState_hostile(a, b)`:
  NPCs don't fight each other, and Descendants of Draco don't fight the Ancients (but do
  fight Guardians and the GCDS). A hex is
  **contested** while it holds two hostile sides.
- **Combat order follows arrival order** (`HexState_arrivals[key]`, first arrival first). The
  last two sides to arrive fight first, with the later one attacking. The winner then attacks
  the side that arrived before them, and so on. The defender wins initiative ties. E.g. Red
  holds a hex, then Blue enters, then Purple: Purple attacks Blue, and the winner attacks Red.
  With Ancients + Draco + a newcomer, the newcomer fights Draco first, then the Ancients.
- The arrival order is **saved** (`settings.HexState`). Every query and every drop, spawn or
  delete of a unit reconciles it with the table: sides that are gone are removed, and new
  sides are added at the end (NPCs first if several are new at once, e.g. on load). A held
  unit counts in the hex it was picked up from, so picking a ship up and putting it back
  keeps the order.
- **Hexes fight in sector number order, highest first.** The number is the tile's
  Description: `"203"`, or the trailing number of a Homeworld (`"Descendants of Draco 228"`),
  read with `HexState_sectorNumber(tile)`. Tiles without a number (the Lyra Homeworld) go last.
- Queries: `HexState_all()`, `HexState_hex(key or position)`, `HexState_contested()`. They
  return hexes in combat order, each `{ key, q, r, tile, number, sides, units = { [side] = { obj, ... } }, contested }`.
  Right-clicking the table gives "Show combats".
- **Combat tooltip:** a contested hex's tile gets its combats added below its Description,
  attacker first, e.g. `Combat 1 of 2` / `Red (2 Interceptors, 1 Starbase) vs Blue (2 Cruisers)` /
  `Winner vs Purple (3 Interceptors)`. The sector number stays first, and `populateSector`
  reads it. Read a tile's own Description through `HexState_baseDescription(tile)`, never
  `getDescription()`.
  The mod has the Tooltip turned off on every hex tile. HexState turns it on only while the hex has a combat.
- When the combat zone moves ships out of a hex, they'll leave its arrival order. The combat
  zone has to keep the order itself, or tell HexState.

## Conventions

- New feature code goes in its own component file (see "Includes"), and event handlers
  stay in Global. Refactor original code only in the areas a feature touches.
- Match the existing style in files you edit. Global uses PascalCase for older functions,
  and new subsystems use a prefix (`ATO_`).
- Tools in `tools/` use only the Python standard library.
- Scripts' line endings are preserved exactly (`.gitattributes` has `* -text`).
