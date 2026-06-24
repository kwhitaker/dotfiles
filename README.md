# dotfiles

## Uses [GNU Stow](https://www.gnu.org/software/stow/) to manage dotfiles

Home-directory dotfiles live under `home_stow/` (one package per app) and are
symlinked with stow.

### niri-auto-display (needs one post-stow step)

A `systemd --user` service that makes the laptop panel follow the dock under
niri + Dank Material Shell: **internal off while an external monitor is plugged
in; back on at 200% scale when it's unplugged.** DMS can disable the internal
panel but never re-enables it on disconnect, and niri emits no output-hotplug
event — so this watches DRM udev events (the same signal GNOME/KDE hook) and
reconciles.

The scale matches DMS's own "Unplugged" display profile (`eDP-1` at `scale 2`).
It's pinned by the watcher rather than the DMS profile because DMS doesn't
auto-switch profiles on hotplug. Change it via `INTERNAL_SCALE` at the top of
the script (set to `None` to leave niri's auto-scale alone).

Both files stow normally:

- `home_stow/niri-auto-display/.local/bin/niri-auto-display` — the watcher
- `home_stow/niri-auto-display/.config/systemd/user/niri-auto-display.service`

The catch: stow symlinks the unit, but the *enablement* link
(`niri.service.wants/…`) is something systemd writes, not stow. So on a fresh
machine, after stowing, enable it once:

```sh
systemctl --user enable --now niri-auto-display.service
```

Watch it react: `journalctl --user -u niri-auto-display -f`, then plug/unplug.

**Tradeoff:** it's a hard policy — you can't run internal + external together
while it's active (internal dies whenever an external is live). Want both
screens? `systemctl --user stop niri-auto-display` for the session.

## System files (not stow-managed)

Root-owned files under `/etc` can't be stowed — stow only symlinks, and some
daemons (e.g. NetworkManager) ignore config that isn't owned by root. Those live
under `system/` mirroring their real path, and are **copied** into place by:

```sh
./install-system.sh
```

Currently just `90-autotz`, a NetworkManager dispatcher that sets the system
timezone from public-IP geolocation on every network change. Check it with
`journalctl -t autotz`.

### If moving back to GNOME

`90-autotz` is desktop-agnostic (it runs off NetworkManager, not the session),
so it keeps working under GNOME with no changes — it touches no geoclue config,
so GNOME's own geolocation still works out of the box. GNOME ships its own
auto-timezone though, so pick one owner:

- **Keep the dispatcher (default):** leave GNOME's *Settings → Date & Time →
  Automatic Time Zone* toggle **off** (off by default on a fresh GNOME). One
  mechanism in every session, nothing to change.
- **Use GNOME's built-in instead:** flip that toggle **on** and remove the
  dispatcher so they don't both fire —
  `sudo rm /etc/NetworkManager/dispatcher.d/90-autotz` (and drop `system/` here).

Leaving both active is harmless — same IP signal, same answer — just redundant.

### List of Apps I need to install

Just a list of the apps I tend to use, so I don't forget them.

- 1Password
- brave
- caligula
- claude
- dank material shell (DMS)
- docker
- dropbox
- eza
- ghostty
- git
- lazygit
- localsend
- mise
- mullvad
- neovim/lazyvim
- niri
- obsidian
- rancher/podman
- rustdesk
- slack
- spotify
- sqlit
- starship prompt
- steam
- todoist
- vesktop
- vscode
- zoom
- zoxide
- zsh
- zsh auto-complete
