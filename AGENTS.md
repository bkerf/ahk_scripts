# Repository Guidelines

## Project Structure & Module Organization
This repository is a flat collection of Windows automation scripts built around AutoHotkey v2. Main entry points live in the repo root: `StartAll.ahk` launches `UnifiedHotkeys.ahk` and starts `media_listener.py`. Feature scripts such as `ClipboardImagePaste.ahk`, `Home_MediaControl.ahk`, `VoiceMediaControl.ahk`, and `translator.ahk` stay beside their helpers. Python backends (`translator.py`, `media_listener.py`, `check_media.py`) and PowerShell helpers (`CheckMediaPlaying.ps1`, `ClipboardMonitor.ps1`) also live at the root. Keep new files in the root unless a real submodule boundary appears.

Startup ownership is intentionally split: `StartAll.ahk` is only the bootstrap script and must exit after launching `UnifiedHotkeys.ahk` plus background helpers. Any persistent AHK hotkey, tray menu item, or long-running automation belongs in `UnifiedHotkeys.ahk`; adding a hotkey directly to `StartAll.ahk` keeps it resident and creates a second tray icon.

## Build, Test, and Development Commands
There is no build step. Use the local virtual environment when Python is involved.

```powershell
.venv\Scripts\python.exe translator.py --help
.venv\Scripts\python.exe media_listener.py --tcp
start "" ".\StartAll.ahk"
powershell -File .\CheckMediaPlaying.ps1
```

The first two commands validate Python entry points. `StartAll.ahk` is the normal local run path and should result in one tray icon through `UnifiedHotkeys.ahk`. Use the PowerShell helper to smoke-test media state checks.

## Coding Style & Naming Conventions
Use AutoHotkey v2 syntax only, with `#Requires AutoHotkey v2.0` and `#SingleInstance Force` near the top of each script. Follow existing formatting: 4-space indentation in Python, brace-on-next-line blocks in AHK hotkeys/functions, and short Chinese comments only where behavior is non-obvious. Keep AHK filenames descriptive and feature-oriented (`VoiceMediaControl.ahk`); keep Python modules in `snake_case.py`; keep PowerShell scripts in verb-style or descriptive PascalCase names.

## Testing Guidelines
This repo does not currently have an automated test suite. For behavior changes, run the relevant script directly and perform a manual hotkey smoke test on Windows. For startup changes, verify `StartAll.ahk` creates only one tray icon. For translator changes, verify clipboard read/write and `DEEPL_API_KEY` handling by launching `translator.ahk` manually. For media control changes, validate pause/resume behavior and TCP listener startup. Document the exact manual checks in the PR.

## Commit & Pull Request Guidelines
Follow the existing Conventional Commit pattern from history: `feat:`, `fix:`, `refactor:`, `docs:`. Keep commits scoped to one script or one behavior change. PRs should include a short summary, affected hotkeys or startup behavior, required env vars, and manual verification steps. Add screenshots only when a visible notification, tray menu, or terminal output changed.

## Configuration & Security Tips
Do not hardcode secrets. `DEEPL_API_KEY` must come from the environment. Treat `.venv/`, local logs, and startup-specific machine settings as local-only artifacts and avoid committing them.
