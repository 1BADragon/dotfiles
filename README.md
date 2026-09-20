# dotfiles

My dotfiles and configs.

## On a new machine

```sh
git clone https://github.com/1BADragon/dotfiles.git ~/Workspace/config
cd ~/Workspace/config
make theme        # kitty + helix + theme-switch
make theme-auto   # optional: follow the desktop's light/dark preference
```

`make theme` is enough on a machine that only runs kitty and helix, which
includes any Mac: the i3 and polybar targets are Linux-only and are never
deployed unless named. `make zsh` adds the shell on top.

The zsh config expects [powerlevel10k][p10k] to be installed already — it is
`zsh-theme-powerlevel10k` on Arch and `powerlevel10k` in Homebrew. `.zshrc`
sources whichever prefix it finds rather than a fixed one, so the same file
works on both.

[p10k]: https://github.com/romkatv/powerlevel10k

## Deploying

Everything is opt-in — plain `make` deploys nothing, it just lists the targets.
Pick only what the machine actually needs:

```sh
make theme      # kitty + helix + theme-switch (no i3/polybar required)
make all        # every component
make kitty      # or any single component: helix, theme-switch, zsh, bin, i3, polybar
```

`make status` shows what is currently deployed; `make uninstall` removes the
symlinks and `theme-switch`, leaving copied files alone.

kitty and helix are **symlinked** into `~/.config`, so edits in this repo take
effect immediately. Everything else is **copied**, as `deploy.sh` used to do.

## theme-switch

Switches kitty and helix between a dark and a light theme together, reloading
already-running instances via `SIGUSR1`:

```sh
theme-switch               # toggle
theme-switch light
theme-switch dark
theme-switch auto          # match the desktop's own light/dark preference
theme-switch auto --watch  # follow that preference until killed
theme-switch status
```

Themes are Catppuccin Frappé (dark) and Solarized Light (light). To change the
pair, edit the four variables at the top of `theme-switch`; kitty themes are
read from `kitty/themes/<name>.conf`, helix themes by name from its runtime.

`auto` asks the OS, so where it reads from depends on the machine:

| | reads | watches by |
|---|---|---|
| Linux | XDG desktop portal, `org.freedesktop.appearance` `color-scheme` | waiting on the portal's `SettingChanged` signal |
| macOS | `defaults read -g AppleInterfaceStyle` | polling, every `THEME_SWITCH_POLL_SECONDS` (default 2) |

Linux goes through the portal rather than anything Plasma-specific, so it works
on any desktop that runs one. "No preference" there is treated as dark; macOS
has no such state, since `AppleInterfaceStyle` is simply absent in light mode.

macOS polls because nothing announces the change to a shell: the switch is
broadcast as the `AppleInterfaceThemeChangedNotification` distributed
notification, and subscribing to it needs a compiled listener. For an instant
switch, install [dark-mode-notify][dmn] and point it at `theme-switch auto`
instead of enabling the agent below.

[dmn]: https://github.com/bouk/dark-mode-notify

### Following the desktop automatically

`make theme-auto` installs a service that runs `auto --watch` — a systemd user
unit on Linux, a LaunchAgent on macOS. Both are left disabled on purpose —
enabling a service changes a running system — so turn it on per machine:

```sh
make theme-auto

systemctl --user enable --now theme-switch.service          # Linux
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/com.github.1badragon.theme-switch.plist   # macOS
```

The unit is bound to `graphical-session.target` and a LaunchAgent only runs in a
GUI login session, so either way it starts with the desktop and stops with it.
`make uninstall` stops and removes whichever one this machine has.

The agent's output goes to the unified log rather than a file:

```sh
log show --predicate 'process == "theme-switch"' --last 10m
```

`kitty/current-theme.conf` is generated — `theme-switch` rewrites it on every
toggle, so it is gitignored.

## Licence

MIT, see [LICENSE](LICENSE).

The kitty themes under `kitty/themes/` are third-party and vendored rather than
written here: Catppuccin Frappé and Latte (Pocco81, MIT) and Solarized Light
(Ethan Schoonover, MIT). Each file keeps its upstream author, licence and
source URL in its own header, and those terms govern it rather than the licence
above.
