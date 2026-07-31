# neru-config

[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=fff)](https://www.apple.com/macos/)
[![neru](https://img.shields.io/badge/neru-upstream-465FBC)](https://github.com/y3owk1n/neru)
[![config](https://img.shields.io/badge/config-TOML-9C4221?logo=toml&logoColor=fff)](config.toml)
[![modes](https://img.shields.io/badge/modes-hints%20%2B%20recursive%20grid-465FBC)](#hints)

> My [neru](https://github.com/y3owk1n/neru) config: one shortcut labels every clickable thing on screen, then you type the label and hit `Space`.

neru moves and clicks the macOS pointer from the keyboard. It ships with four modes; this config keeps two.

The first commit is the template `neru config init` writes for v1.49.0, byte for byte. Every commit after it changes one default and says why, so `git log` reads as the list of decisions and `git diff f2ceb52` shows everything that differs from upstream.

## Install

```sh
./install.sh
```

The script symlinks `config.toml` into `~/.config/neru/config.toml` (or `$XDG_CONFIG_HOME/neru`), then runs `neru config validate` so a bad link or bad TOML surfaces now instead of at daemon start. Re-running it is safe. A real config already sitting there is moved aside, not overwritten:

```
config.toml.backup.20260729155325
```

It links the file rather than the directory, so runtime files neru writes beside its config stay out of this repo.

If neru itself is missing, the script offers to install it through Homebrew, printing the exact commands and waiting for a `y` first. It targets the tagged release line, the `y3owk1n/tap/neru` cask, not `neru-nightly`. Answering no leaves the link in place, so the config is ready whenever neru arrives.

## Hints

`Hyper+Space` (`Cmd+Ctrl+Alt+Shift+Space`) draws a label on every clickable element. Type the label to select it.

Labels use the home row, `asdfghjkl`, so both hands stay put. Elements come from the accessibility tree (`strategy = "axtree"`), not from Vision, which means the labels sit on real controls rather than on guesses about pixels.

Inside the mode:

| Key | Does |
| --- | --- |
| `Space` | Left click, then leave the mode |
| `Shift+R` / `Shift+M` | Right click / middle click |
| `Shift+I` / `Shift+U` | Mouse down / mouse up, for dragging |
| `/` | Filter hints by the element's text |
| `Tab` / `Shift+Tab` | Step through matches |
| Arrows | Nudge the cursor 10px |
| `Escape` | Leave |

Upstream's left click is `Shift+L`, which needs a modifier mid-navigation and leaves the overlay up, so a click took three keystrokes with an `Escape` at the end. `Space` does both here. The old binding stays in the file as `"Shift+L" = "__disabled__"`, which records what upstream ships without it firing.

The menu bar gets hints too, so the focused app's menus (`File`, `Edit`, `View`) and third-party status items are clickable from hints mode. The cost is that every menu title now carries a label, so each activation shows more of them than before.

Apple's own Control Center items (clock, Wi-Fi, battery) get no hints, despite being configured. Their `AXMenuBar` container reports a stale frame, so neru prunes the whole subtree before it reaches the children. This is an upstream bug, not a setting to fix here; status items on a non-active display fail the same way. Check with `neru hints --debug --role AXMenuBarItem`.

The Dock, Notification Center, Stage Manager, and picture-in-picture windows get no hints by choice.

## Recursive grid

Double-tapping Capslock fires `F17` (see the [capslock](https://github.com/y3owk1n/capslock) interceptor config at `~/.config/capslock/config.json`), which activates recursive grid. Cmd+Shift+C, the upstream default, is unbound.

Recursive grid subdivides the screen into a 3x3 grid; typing a cell's key zooms into it, recursively, until the cursor lands where you want it. Cell keys are `qweasdzxc`, the left hand's home block, matching the grid to the fingers that reach it. `Space` clicks, then leaves the mode, same as hints. Upstream's click key, `Enter`, now resets the zoom back to the full grid.

## Everything else

Grid, scroll, and monitor-select are off, and their `[hotkeys]` bindings are commented out. Their settings and keymaps stay in the file, so turning one back on means flipping `enabled` and uncommenting one line.

Also on:

- **Headless.** No menu bar icon (`[systray] enabled = false`), since the icon never gets clicked and menu bar space is scarce on a laptop. The daemon runs normally; `neru status` covers checking on it.
- **Sticky modifiers.** Tap a modifier instead of holding it.
- **A blue theme,** with separate light and dark palettes.

Logs go to the console only; nothing is written to disk.
