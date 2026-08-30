# New machine setup

Distilled from the Fedora 44 → Omarchy cutover (2026-08-28), after it went fine. No package
manager commands: the next move might be another distro, or macOS. Names of things, reasons for
things, and the traps.

## Before you wipe anything

**Ask Kevin what he wants to keep. Don't assume.** Last time the save manifest was built by
inventorying the disk, and most of it was never wanted — the answer to "should this survive?" is
his, not yours, and it's cheaper to ask than to haul 30 GB somewhere. Walk the list below with
him and let him say no.

Nor should you assume *where* it goes. External drive, another machine, cloud storage, or
straight onto the new install afterward — ask that too.

- Restore one thing before you format. One archive on the last backup looked complete from the
  outside and turned out to be an interrupted copy holding a fifth of its files. Extract an
  archive, check a checksum, open a database.
- `git bundle create <name>.bundle --all` per repo. One file, every local-only branch and
  unpushed commit. It does *not* capture stashes; ask about those separately.
- Deauthorize per-seat licences while the old machine still boots: 1Password, Dropbox, Todoist,
  Slack, Zoom, and the Cloudflare Zero Trust device registration. A dead device keeps its seat.
- Bluetooth pairings don't survive. Have a wired mouse for first boot.

## Candidates that exist nowhere else

Things with no second copy, so they're gone if he doesn't say keep. Offer them; don't act on them.

- SSH key (`~/.ssh/id_ed25519`), any GPG keyring
- Every gitignored `.env` under `~/Work`
- Loose plans, notes and SQL dumps sitting *beside* the repos rather than in them
- `~/.claude/` — CLAUDE.md, hand-written skills, settings, memory stores
- `~/.pi/agent/` — auth, settings, sessions, extensions
- Plex library database (see below)
- sqlit connections and query history (`~/.sqlit`), hypa database (`~/.hypa`)
- Any hand-written script in `~/.local/bin` that isn't stowed. This trap has sprung twice now
  (`dms-audio-inhibit`, and `dock-display-watch` nearly). Write one, stow it that day.

Whatever he does say yes to, take sandboxed app state wholesale rather than app by app. Naming
one Flatpak's config path looked thorough and quietly dropped every other app's state; the
EasyEffects presets went with the disk and had to be rebuilt from community profiles. Same for
`~/Library/Application Support` on macOS.

## Don't even offer

Steam games, Proton prefixes, `node_modules`, the pnpm/NuGet/cargo caches, mise installs, docker
images and volumes, browser profiles (sign in and sync), fonts, nvim's plugin store
(`lazy-lock.json` is the part that matters and it's in the config), anything Dropbox holds. That
was ~100 GB of 136 GB in use.

## Apps

Job-critical:

- 1Password — the real desktop app plus the CLI, not a web-app wrapper
- Cloudflare WARP / Zero Trust client (team `crtwhl`)
- Docker + compose
- mise — carries node, pnpm, python, ruby
- .NET SDK 8 *and* 10 — see the gotchas
- AWS CLI v2, gh
- VS Code
- Slack, Zoom, Bruno
- A postgres client for loading dumps

Daily driver: ghostty · zsh + autosuggestions + syntax-highlighting · starship · tmux +
tmuxinator · neovim (LazyVim) · lazygit · lazydocker · stow · fzf · eza · zoxide · ripgrep · bat ·
btop · jq

Everything else: Brave · Dropbox · Todoist · Obsidian · Vesktop · LocalSend · Spotify ·
TIDAL Hi-Fi · Steam · RustDesk · Plex Media Server · EasyEffects · Pinta · Foliate ·
Fragments · caligula · sqlit

Retired, don't reinstall: the three-and-a-half app launchers, cava, opencode, Tor Browser, caddy,
a host-level postgres (it runs in docker), the GNOME app suite, Rancher Desktop.

### Installed outside the package manager

The ones you forget, because there's no manifest to diff against.

| Tool | Comes from |
|---|---|
| `claude` | official installer |
| `pi` | global npm under mise's node, plus the `hypa` extension |
| `sqlit` | pipx, or a plain venv symlinked into `~/.local/bin`. Bound to mise's python, so a minor bump means recreating it |
| `tmuxinator` | ruby gem under mise |
| `wthrr` | cargo |

`~/.pi/agent/AGENTS.md` is a symlink to `~/.claude/CLAUDE.md`, and pi's `settings.json` points
`skills` at `~/.claude/skills`. Restore `~/.claude` first or both break silently.

## Work stacks

Order: ssh key (mode 600, verify with `ssh -T git@github.com`) → clone dotfiles → stow → mise
install → auths.

Stow packages: `ghostty lazygit starship tmux tmuxinator shell scripts`.

Three interactive auths, none scriptable: `gh auth login`, `aws sso login --sso-session
crtwhl-g-suite`, and WARP enrollment via `warp-cli registration new crtwhl` (the old
`teams-enroll` verb is gone).

**Cartwheel.** Drop `.env` and `.config/.env` back. Bring up the db and rabbit compose files
(postgres on host 5433, rabbit on 5678/15678), load the cluster dump, `pnpm install`,
`dotnet build`, then `tmuxinator start crtwhl` for the 2×2 dev grid.

**airadoc.** Four `.env` files: repo root, `apps/api/.env` (the big one), `apps/web-client/.env`,
and the sibling one a level up. `docker compose up -d` brings up postgres, redis, synapse and
synapse-postgres; then `pnpm install`, `prisma migrate deploy`, `prisma generate`, `turbo run dev`.
Synapse reaches the host through `host.docker.internal:host-gateway`, which is the first thing to
check if Matrix auth breaks.

Both stacks bind host 5433. Never a problem in practice, since they're never up at once.

## RPG campaigns

Every Obsidian vault lives inside `~/Documents/rpg-campaigns`, a git repo. Clone it and they're
back. Only the vault registry is machine-local (`~/.config/obsidian/obsidian.json`), and that
rebuilds by opening each folder once. Nothing else to save.

## Plex

Run it as your own user, not the packaged system service. The reason is the removable mount:
udisks creates `/run/media/$USER` root-owned at `0750` with an ACL granting traverse to the
session user alone, so a `User=plex` service can't reach the media however the drive is mounted.
A user unit with `PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=%h/.local/share/plexmediaserver`
sidesteps it. The unit is in the backup; check the server binary's path before reusing it verbatim.

Library paths live in SQLite, not in a config file, so a username or mount change means editing
the database. Three tables hold them: `media_parts.file`, `section_locations.root_path`, and
`media_streams.url` (percent-encoded, though usernames aren't escaped, so a plain `replace()`
still works). Scan every text column rather than guessing. Never `VACUUM` that database with a
stock `sqlite3` CLI — Plex uses custom collations the CLI doesn't have, and an index rebuild can
destroy it.

Set *empty trash after every scan* to off, explicitly, before first start. It was never set, so it
ran on Plex's default for years. With it off, a scan against an absent drive does no damage, which
is why the mount-guard `ExecStartPre` built for this got thrown away: on a laptop that leaves the
desk, refusing to start without the media drive turns "library unavailable" into "Plex never
starts." `Restart=on-failure` wouldn't have helped either — Plex doesn't exit when its root is
missing.

`customConnections` in `Preferences.xml` pins the old DHCP lease; refresh it. That file is also
what keeps the server claimed, so restore it or you re-claim and re-scan.

Firewall, scoped to the LAN rather than `0.0.0.0/0`:

| Port | Proto | What |
|---|---|---|
| 32400 | tcp | the server itself, the only required one |
| 32469 | tcp | DLNA server |
| 1900 | udp | DLNA discovery (SSDP) |
| 5353 | udp | mDNS / Bonjour discovery |
| 32410, 32412, 32413, 32414 | udp | Plex's own network discovery |

While you're in there: LocalSend wants 53317 tcp+udp, and docker's embedded DNS needs udp 53
allowed from the bridge gateway (`172.17.0.1`) to the container subnets, or nothing in a container
resolves anything.

## Linux laptop bits (Framework 13 AMD)

- amd-ucode in the initramfs; verify after first boot
- Suspend wants `s2idle` — `cat /sys/power/mem_sleep`
- Fingerprint (Goodix) needs re-enrolling; add the PAM module if you want it for sudo
- Install fwupd early so BIOS updates keep flowing
- Swap is an 8 GB zram device, no disk swap. Hibernation would need a real one

## Gotchas that actually bit

**A new install can hand you a different username.** `kevin` → `kwhitaker` was the through-line of
every real problem in the restore, because the backup holds databases with absolute paths inside
them. Files restore fine; tar doesn't care what you're called. Anywhere an app keeps its own
database, check it before first launch. Git worktree registrations need `git worktree repair`.

**.NET needs one root holding every SDK, not one root per version.** Multi-level lookup was
removed in .NET 7, so separate roots can't chain and whichever `dotnet` is first on PATH is the
only one that exists. Use the OS packages, side by side under a single tree, not mise, whose
default layout is isolated-per-version. Some distros also split the ASP.NET runtime and targeting
packs out of the SDK package; without them `dotnet build` fails on web projects.

**WARP may install its own root CA** into the system trust store. If `pnpm install`,
`dotnet restore` or an https `git clone` start throwing certificate errors while WARP is
connected, that's the cause; node may additionally want `NODE_EXTRA_CA_CERTS`. It never
materialised on this account — Gateway TLS inspection appears to be off — but it's still the first
place to look.

**Nothing shell- or compositor-shaped transfers.** Window manager config, bar config, themes
generated from a palette tool, colorschemes keyed to that palette. All of it gets rewritten rather
than restored, and expect the config *format* to have changed too. Keep the old files as a reading
reference for which keybinds you actually used.
