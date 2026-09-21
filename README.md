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
includes any Mac: the i3 and waybar targets are Linux-only and are never
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
make theme      # kitty + helix + theme-switch (no i3/waybar required)
make all        # every component
make kitty      # or any single component: helix, theme-switch, zsh, waybar, bin, i3
```

`make status` shows what is currently deployed; `make uninstall` removes the
symlinks and `theme-switch`, leaving copied files alone.

kitty, helix and waybar are **symlinked** into `~/.config`, so edits in this
repo take effect immediately. Everything else is **copied**.

## theme-switch

Switches kitty, helix and waybar between a dark and a light theme together,
reloading already-running instances by signal:

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

`kitty/current-theme.conf` and `waybar/current-colors.css` are generated —
`theme-switch` rewrites them on every toggle, so both are gitignored.

## waybar

A read-only status line for Plasma: the fields the taskbar shows, without the
interactions, for a setup where the Plasma panel auto-hides but still owns the
tray, the volume and the window list.

```
weather            <clock>            privacy · updates · failed units ·
                                      CPU · RAM · temp · SSD · net · mouse · battery
```

Three of those are silent by default and cost no width until they have
something to say: `privacy` (microphone live or screen being shared),
`custom/updates` (pending pacman updates, via `checkupdates`) and
`systemd-failed-units`.

### Why not polybar

polybar is an X11 bar. It asks the window manager for screen space with
`_NET_WM_STRUT_PARTIAL`, and under a Wayland session it can only run as an
XWayland client, whose struts `kwin_wayland` does not apply to the Wayland
workspace. The bar sets the property correctly and the compositor ignores it,
so maximised windows open underneath and the bar covers their titlebars. The
tell is that `_NET_WORKAREA` stays at the full screen size even with the Plasma
panel on screen — the X11 work area is decoupled from the session entirely.
Waybar reserves space through the layer-shell protocol instead, which KWin
does honour. The old polybar config was removed rather than kept as a fallback.

### Look

Colours are read from Plasma's own schemes in
`/usr/share/color-schemes/Breeze{Light,Dark}.colors` rather than eyeballed, and
the bar uses Plasma's UI font. No icon font is involved: every readout is text,
and `privacy` draws its icons from the GTK icon theme, which is Breeze here.

waybar is GTK3, so it has no `prefers-color-scheme` media query, and the
appearance it reads from the portal only flips GTK's own dark-theme setting —
it does not restyle explicit colours or expose a class to match on. So the
palette lives in `current-colors.css`, which `theme-switch` rewrites from
`colors-light.css` or `colors-dark.css` before reloading waybar with `SIGUSR2`.
The bar therefore follows the same signal kitty and helix do.

### Hardware

Module hardware is named for the machine this is deployed on: `BAT0`, the
coretemp sensor by its stable platform path rather than a `/sys/class/hwmon`
number that shuffles between boots, and no pinned network interface so a
device rename does not break it. The bluetooth mouse is resolved at runtime by
`bin/waybar-mouse.sh` rather than pinned by address.

## Licence

MIT, see [LICENSE](LICENSE).

The kitty themes under `kitty/themes/` are third-party and vendored rather than
written here: Catppuccin Frappé and Latte (Pocco81, MIT) and Solarized Light
(Ethan Schoonover, MIT). Each file keeps its upstream author, licence and
source URL in its own header, and those terms govern it rather than the licence
above.
