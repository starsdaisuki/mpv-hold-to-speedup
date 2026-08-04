<img src="https://github.com/user-attachments/assets/aa3aa288-f2a5-4baf-a883-404cb5388c94" />

# hold-to-speedup.lua

An mpv / mpv.net script that speeds up playback while the spacebar or left mouse button is held, and drops back to your previous speed on release. Tap the spacebar once a file has finished and it replays from the start.

> Fork of [iiiGerardoiii/mpv-hold-to-speedup](https://github.com/iiiGerardoiii/mpv-hold-to-speedup). See [Changes from upstream](#changes-from-upstream).

## Usage

| Action | Result |
|---|---|
| Hold Space | Speed up to `speed` (2× by default) |
| Release Space | Back to whatever speed you were on |
| Tap Space | Pause / unpause, as usual |
| Tap Space on the final frame | Replay from 0:00 |
| Hold left mouse button | Same speed boost (optional) |

## Installation

Everything is configured through files — neither mpv nor mpv.net has a plugin manager that installs from a GitHub URL.

### mpv.net (Windows)

```powershell
irm https://raw.githubusercontent.com/starsdaisuki/mpv-hold-to-speedup/main/install-mpvnet.ps1 | iex
```

The installer resolves the config folder the same way mpv.net does — `MPVNET_HOME`, then `portable_config` next to `mpvnet.exe`, then `%APPDATA%\mpv.net` — and drops the script in. Run it again whenever you want the latest version; it will not overwrite an options file you have edited.

> ⚠️ mpv.net does **not** read `%APPDATA%\mpv`. That is mpv's folder, not mpv.net's — and a scoop or portable install ignores `%APPDATA%` entirely in favour of `portable_config`. Putting the script in the wrong one fails silently.

### mpv

Copy `hold-to-speedup.lua` into your mpv `scripts` folder, and optionally `script-opts/hold-to-speedup.conf` into `script-opts`:

- **Linux / Unix / macOS:** `~/.config/mpv/scripts/hold-to-speedup.lua`
- **Windows:** `%APPDATA%\mpv\scripts\hold-to-speedup.lua`

(See the [Files section](https://mpv.io/manual/master/#files) of mpv's manual.)

## Configuration

Edit `script-opts/hold-to-speedup.conf` in your config folder:

| Option | Default | Meaning |
|---|---|---|
| `speed` | `2.0` | Playback speed while held |
| `hold_threshold` | `0.15` | Seconds before a press counts as a hold rather than a tap |
| `enable_mouse` | `yes` | Also speed up while the left mouse button is held |
| `replay_on_end` | `yes` | Tapping Space on the final frame restarts the file |
| `keep_open` | `yes` | Force `keep-open=yes` so a finished file stays on its last frame |
| `osd_duration` | `1.0` | How long OSD messages stay up, in seconds |

`keep_open` matters: without it the player drops the file the moment it ends, so there is no last frame left to tap on. It is only applied when `replay_on_end` is on, and only when `keep-open` is currently `no`, so an explicit setting of your own is left alone.

## Changes from upstream

- **Replay on tap at end.** Tapping Space while parked on the final frame seeks to 0:00 and resumes, instead of un-pausing in place and appearing to do nothing. Detected via `eof-reached` with a duration/position fallback, both gated on being paused so a normal pause near the end is unaffected.
- **Configurable via `script-opts`.** Speed and hold threshold were hardcoded; they and everything else now come from a conf file. The hold threshold also drops from upstream's 0.5s to 0.15s, which feels far more responsive — raise it back toward 0.25s if a deliberate tap ever registers as a hold.
- **Separate state per binding.** Upstream shared one `timer` and one `is_speeding` flag between the keyboard and mouse handlers, so releasing one cancelled the other's hold. Each binding now has its own.
- **Plain OSD messages.** Replaced the `set_osd_ass` overlay (which had to be cleared by hand with an empty `osd_message`) with ordinary `mp.osd_message` calls.
- **`install-mpvnet.ps1`** for mpv.net, since its config folder is not the one upstream's README points at.

## License

Upstream ships no license file, so no redistribution terms are granted. This repository exists as a GitHub fork, which is permitted under [GitHub's Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service#5-license-grant-to-other-users). If the original author adds a license, this fork will follow it.
