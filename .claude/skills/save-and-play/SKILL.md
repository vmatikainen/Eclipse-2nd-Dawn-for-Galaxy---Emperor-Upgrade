---
name: save-and-play
description: Load changed scripts into the running Tabletop Simulator game with Save & Play (External Editor API), and probe the live game with Lua. Use after every small script change the user will test in TTS (suggest it), when the user asks to push, reload or Save & Play, or when inspecting live game state to debug.
---

# Save & Play: push scripts into the running game

Loading the mod through *Games → Workshop* starts a new game, so every test means setting up
again. For small iterations on scripts, push them into the running game instead.
`tools/tts_live.py` does this through TTS's External Editor API: TTS listens on
127.0.0.1:39999 and answers on 127.0.0.1:39998.

## When to suggest it

After every small change to `scripts/` (Lua or `Global.-1.xml`) that the user is going to try
in TTS, offer Save & Play as the way to test, in one line: *"Save your game in TTS, then I can
push it (Save & Play)."* Push only once the user says so: it reloads their game.

Don't suggest it when the change needs the mod JSON reloaded. Save & Play only replaces scripts
and UI XML. It doesn't apply:
- changes from `tools/apply_object_fixes.py` or `tools/normalize_board_snaps.py` (objects,
  snap points, bag settings, new objects),
- anything that only runs at a fresh start of the mod, before a save exists.
Those need *Games → Workshop*.

## The catch: it reloads the last save

TTS reloads the game **from its last save**, not from the table as it is now. Anything done
since that save is lost, e.g. a game goes back to faction selection. So the user saves first
(*Games → Save*, or the save they want to continue from), then you push.

## Steps

1. Rebuild the mod file, which is what gets pushed: `python tools/rebuild_mod.py`. If the user
   has a personal deploy step (e.g. `./deploy-local.sh`), run that instead, since it also rebuilds.
2. Check TTS is up: `nc -z 127.0.0.1 39999`. If it isn't, the user loads the mod in TTS first.
3. Once the user has saved and said to push: `python tools/tts_live.py push`. This sends
   Global's script and XML. Changed object scripts (a `Button <Race>`, `Next Round`, ...) need
   `--guid <guid>` each, the GUID being the one in the script's file name.
4. The tool prints `loaded: ...` once TTS has reloaded, then what the scripts printed while
   loading. `ERROR ...` lines are Lua errors: report them. Line numbers point into the combined
   Global script, so subtract to find the line in an include file.
5. Optionally confirm the new code is running with a read-only probe (below).

## Probing the live game

`python tools/tts_live.py lua <file>` (or `-` for stdin) runs Lua in Global. Only `print()`
output comes back, so print what you need, e.g.

```bash
echo 'for c, e in pairs(PlayerState) do print(c .. " " .. tostring(e.faction)) end' \
  | python tools/tts_live.py lua -
```

Probe read-only by default. Changing objects changes the user's game: ask first.
Write longer probes to the session scratchpad, not the repo.

## If it fails

- `port 39998 is in use`: the VS Code TTS extension is connected. Close its connection first.
- `TTS is not listening`: TTS isn't running, or no game is loaded.
- No `loaded:` line: TTS didn't reload. Check that a game is loaded, and try again.
