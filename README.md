# dotfiles

## Uses [GNU Stow](https://www.gnu.org/software/stow/) to manage dotfiles

Home-directory dotfiles live under `home_stow/` (one package per app) and are
symlinked with stow.

### dock-display-watch

Turns the laptop panel off whenever an external display is connected. Stows as part of the
`scripts` package — no post-stow step, it's launched from `~/.config/hypr/autostart.lua`:

```lua
o.launch_on_start(os.getenv("HOME") .. "/.local/bin/dock-display-watch")
```

Omarchy already does this in clamshell, with the lid shut. This extends it to lid-open docking,
which is the case that actually comes up at a desk.

It's deliberately **one-way**. Unplugging doesn't need anything here —
`omarchy-hyprland-monitor-watch` clears the same toggle on `monitorremoved`, and that's the
recovery that stops an unplug from leaving the session with no enabled output at all. Re-enabling
the panel by hand while docked (`SUPER + CTRL + Delete`) sticks until the next hotplug.

Two details that look like paranoia and aren't: it retries on a 1s-then-3s delay because
`monitoradded` can fire before the output is usable and at login it runs while Hyprland is still
bringing displays up, and it holds an `flock` so overlapping hotplug events don't race.

Watch it react with `journalctl --user -t hyprland -f`, or just plug the dock in.

### niri-auto-display — dead, kept for reference

The niri + DMS ancestor of the above. niri emitted no output-hotplug event, so it watched DRM
udev events instead and ran as a `systemd --user` service. **Don't stow it** — it calls
`niri msg` and there's no niri here any more. The package stays in `home_stow/` only because the
udev approach is worth re-reading if `dock-display-watch` ever proves insufficient.

## System files (not stow-managed) — currently none

Root-owned files under `/etc` can't be stowed — stow only symlinks, and some daemons (e.g.
NetworkManager) ignore config that isn't owned by root. Those live under `system/` mirroring
their real path, and get **copied** into place by `./install-system.sh`.

**Nothing needs it right now.** `system/` holds `90-autotz`, a NetworkManager dispatcher that set
the timezone from public-IP geolocation on every network change. It was retired in the move to
Omarchy (2026-08-28) — `install-system.sh` was deliberately not run on this machine, and timezone
is handled by running `tzupdate` by hand. The script and the notes below survive in case that
decision gets revisited.

### Setting up a new machine

See [NEW-MACHINE.md](NEW-MACHINE.md) — the app list, the work-stack bring-up, the Plex
firewall rules, and the things that went wrong last time.
