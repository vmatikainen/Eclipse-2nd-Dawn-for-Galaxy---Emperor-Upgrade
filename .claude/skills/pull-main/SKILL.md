---
name: pull-main
description: Pull the latest main from GitHub and rebuild the local mod JSON (3844682665.json is not in git, so every pull from main must be followed by a rebuild). Use whenever pulling, syncing or updating from main, merging main into a branch, or after switching to an updated main.
---

# Pull main and rebuild the mod JSON

The mod file `3844682665.json` is git-ignored. Each developer has a local copy, and it has to
be rebuilt from the repository after every pull from `main`. Otherwise Tabletop Simulator
keeps loading old scripts and old board snap points. Follow these steps in order.

## 1. Check the working tree

Run `git status --short`.
- If `scripts/` or `tools/` have uncommitted changes, stop and ask the user whether to commit,
  stash or discard them. Never discard changes without being asked.
- If the user edited scripts in the game (in a TTS save or the VS Code extension) and hasn't
  extracted them yet, remind them to run `python tools/tts_scripts.py extract --mod "<save>.json"`
  first. The rebuild in step 3 overwrites the scripts inside the mod file.

## 2. Pull

Run `git fetch origin`, then:
- **On `main`:** `git pull --ff-only origin main`. If it can't fast-forward, stop and explain
  why. Don't rebase or reset on your own.
- **On another branch:** ask before merging `main` into it. If the user agrees, run
  `git merge origin/main`. If there are conflicts, stop and show them.

## 3. Rebuild the local mod JSON

Run `python tools/rebuild_mod.py`. It writes `scripts/` into the mod file and normalizes the
player board snap points.
- If the user keeps the mod somewhere else, e.g. a TTS save they work in, pass
  `--mod "<path>.json"`.
- If it reports that the mod file is missing, relay its instructions. The user copies the
  Workshop download of the original item 2348417296 into the repository root as `3844682665.json`, then runs the rebuild again.
- If the rebuild fails, show the error and stop.

## 4. Report

Tell the user:
- which commits came in (`git log --oneline <old HEAD>..HEAD`)
- that the mod was rebuilt
- that they need to get the rebuilt file into TTS (their own copy or deploy step, if they
  have one) and load it again (*Games → Workshop* or their save)
