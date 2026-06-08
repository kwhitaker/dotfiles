# dotfiles

## Uses [GNU Stow](https://www.gnu.org/software/stow/) to manage dotfiles

Home-directory dotfiles live under `home_stow/` (one package per app) and are
symlinked with stow.

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
