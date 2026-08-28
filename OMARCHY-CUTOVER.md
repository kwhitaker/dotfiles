# Boudica cutover — Fedora 44 + niri/DMS → Omarchy 4 "Quattro"

Framework 13 AMD 7040. Generated 2026-08-28 from live inspection of the **old** machine.
Commit and push this file — the laptop it describes is about to be wiped.

---

## 00 — Read this first (for Claude on the new machine)

**If you are an agent reading this on a freshly installed Omarchy box: this is your brief.**
Everything below was measured on the old Fedora install before the wipe. Treat it as a
statement of intent, not of current fact — verify before you act on any of it.

### Situation

| | |
|---|---|
| You are on | Omarchy 4 "Quattro" — Arch, Hyprland, Quickshell, `pacman` + `yay` |
| Replacing | Fedora 44 + niri + Dank Material Shell |
| Hostname was | `boudica` (Framework 13, AMD Ryzen 7040) |
| User | `kevin`, uid 1000 |
| Restoring from | **Hrothgar**, 2 TB exfat USB (WDC WD20NMVW), `boudica-cutover/` at the root. Read its `README.md`. |

### Ground rules

- **Never commit or push.** Kevin commits his own work. Stage nothing, run no `gh` writes.
  This is also in his `~/.claude/CLAUDE.md` — restore that early (§02) so the rest of his
  preferences apply too.
- **Verify before asserting.** Package names, paths, and service layouts differ between Fedora
  and Arch. Two claims in this very document were wrong on the first pass and had to be
  corrected against the live machine — check, don't infer.
- **Ask before anything destructive.** Restores overwrite. Confirm targets first.

### Order of work

Do these in sequence; each depends on the last.

1. **§04** — verify hardware basics: fwupd, fingerprint, Bluetooth, mount of the external drive.
2. **§02** — restore keys and identity: `~/.ssh/id_ed25519` (chmod 600), `~/.claude/`,
   `~/.aws/config`, Wi-Fi profiles.
3. **§05** — install packages. Job-critical block first (WARP, docker, mise, dotnet, aws-cli, gh).
4. **§06** — dotfiles via stow, then bring up Cartwheel and airadoc.
5. **§07** — Plex.
6. **§08** — desktop config that needs rewriting rather than restoring.

### Fast verification

Once §05–06 are done, these should all pass:

```sh
ssh -T git@github.com                       # → "Hi kwhitaker!"
dotnet --list-sdks                          # → an 8.x AND a 10.x, same root
mise ls                                     # → node 24, pnpm 10, python, ruby
warp-cli --accept-tos status                # → Connected, org crtwhl
aws sts get-caller-identity --profile cartwheel
docker compose version
ls -d /run/media/kevin/Beowulf/Movies       # → exists before Plex starts
```

### Known-tricky, in order of how likely they are to bite

1. **WARP's TLS root CA** — different path on Arch, breaks `pnpm install` / `dotnet restore`. §06.
2. **dotnet must be one root, not mise** — §05.
3. **Plex mount race + auto-empty-trash** — can silently gut the library. §07.
4. **Port 5433 double-bind** between the two dev stacks. §06.
5. **Nothing niri- or DMS-shaped transfers.** Rewrite, don't restore. §08.

## Vitals

| | |
|---|---|
| Disk | 1 × NVMe 465 GB, single LUKS → btrfs |
| `/home` | btrfs **subvolume**, not a partition |
| External | Beowulf, 932 GB exfat, **43 GB free** |
| Backup | ✅ **done 2026-08-28** → Hrothgar, 2 TB exfat USB. Verified by trial restore. §10 |
| Must-save set | ~34.2 GB (32 GB of it wedding RAWs) |
| Secure Boot | already disabled ✓ |
| At-risk git | 10 unpushed commits (stashes deliberately dropped — §01) |
| BIOS | 03.20 (2026-06-23) |

### The one thing that will bite you

`/home` is **not a separate partition**. It's a btrfs subvolume (`subvol=home`) inside the
same LUKS container as `/`, on the only NVMe. Omarchy's full-disk install wipes the drive —
there is no "keep my home" option that applies here.

Second: **check the backup before you trust it.** There was none at all until 2026-08-28, and
the one photo archive that *did* exist on Hrothgar turned out to be an interrupted copy holding
284 of 1379 files with no darktable sidecars at all. It is now complete and verified — see §10 —
but the lesson stands: restore something before you format anything. Beowulf is 96% full and is
the Plex media drive, so it is not a backup target.

---

## 01 — Rescue work that exists nowhere else

Ten commits live only on this disk, on branches with no upstream. Nothing else in `~/Work` is
dirty in the working tree.

| Repo | Unpushed | Local-only branches | Extra worktrees |
|---|---|---|---|
| `airadoc/airadoc` | **9 commits** | pr3446/head, pr3480, pr3586, pr3589, pr3592, worktree-agent-a4e9411a8e532e6ca | `.claude/worktrees/agent-a4e9411a8e532e6ca` (dirty: package.json) |
| `Cartwheel/Cartwheel` | **1 commit** | cv2-3809, cv2-3896, cv2-3937, list-row-links-entity-company-sweep | — |
| `dotfiles` | 0 | — | — |
| `project-fatima` | 0 (the "ahead 9" on `feature/drafting` is already on `origin/main`) | ralph/ui-polish-3, trash | `project-fatima-worktrees/ralph` |
| `Documents/rpg-campaigns` | 0 | — | — |

Push what should be pushed — Kevin's call, no remotes were touched. Bundle the rest (purely
local, captures every local branch and all reachable objects):

```sh
# one self-contained file per repo — restores with `git clone <name>.bundle`
for r in ~/Work/airadoc/airadoc ~/Work/Cartwheel/Cartwheel \
         ~/Work/dotfiles ~/Work/project-fatima; do
  git -C "$r" bundle create "$BACKUP/$(basename $r).bundle" --all
done
```

- The airadoc agent worktree has an uncommitted `package.json` — commit or copy it.
- Once the bundles exist, a plain copy of `~/Work` covers everything else.

### Stashes: deliberately dropped

All nine stashes are being let go — **no action needed, they die with the disk.** `git bundle
--all` doesn't capture `refs/stash`, so simply not rescuing them is the whole plan. Recorded
here so a future reader doesn't think it was an oversight:

| Repo | What was dropped |
|---|---|
| airadoc | 4 of 5 were single-file churn in `packages/api-client/src/client/api-types/index.ts` — a **generated** file, 9k–18k line diffs of codegen noise. The fifth (`stash@{2}`, 3 months old) was real: 7 files, 434 insertions, chat locales + `ChatMessages.tsx`. |
| Cartwheel | `dialog close guard` (73 lines) — superseded by branch `feature/cv2-4451-…` and its plan doc. And `cv2-4722 regex activePattern nav highlighting (pre route-data rewrite)` — 8 days old, 3 files, 85 insertions, the only genuinely recent one. |
| dotfiles | 6-month-old ghostty config, superseded by the dankcolors work. |
| project-fatima | 6 files, 0 insertions, 0 deletions. Empty diff. |

---

## 02 — Save manifest

Legend: **[ONLY]** gone forever if missed · **[REBUILD]** painful but recoverable · **[SAFE]** cloud/remote has it

### Personal & irreplaceable

| What | Path | Size | |
|---|---|---|---|
| Wedding RAWs + darktable edits (1,379 files, 649 `.xmp` sidecars) | `~/Downloads/JJ Wedding` | 32 GB | **[ONLY]** |
| Passport scan, personal PDFs | `~/Downloads/*.pdf`, `kw-passport.jpg` | ~15 MB | **[ONLY]** |
| Pictures + Videos | `~/Pictures`, `~/Videos` | 83 MB | **[ONLY]** |
| Documents (rpg-campaigns is a clean pushed repo; the rest isn't) | `~/Documents` | 367 MB | [REBUILD] |
| Dropbox — reports "Up to date" | `~/Dropbox` | 14 GB | [SAFE] |

### Work & credentials

| What | Path | Size | |
|---|---|---|---|
| SSH key — the GitHub key, no passphrase, no backup, no GPG keyring here | `~/.ssh/id_ed25519{,.pub}` | 530 B | **[ONLY]** |
| Untracked `.env` files (7; `apps/api/.env` is 5.6 KB of real secrets) | `~/Work/**/.env` | ~7 KB | **[ONLY]** |
| Git bundles from stage 01 | `$BACKUP/*.bundle` | ~250 MB | **[ONLY]** |
| Cartwheel local DB dump (2026-07-16) | `~/Work/Cartwheel/carwheel-local.sql` | 37 MB | [REBUILD] |
| Loose plans/notes beside the repos | `~/Work/{Cartwheel,airadoc}/*.md`, `plans/`, `docs/` | ~230 MB | **[ONLY]** |
| AWS SSO config (also verbatim in Cartwheel's README) | `~/.aws/config` | 537 B | [SAFE] |
| kubeconfig | `~/.kube/config` | 3 KB | [REBUILD] |
| Work repos minus build output | `~/Work` | 762 MB | [SAFE] |

### Config & state

| What | Path | Size | |
|---|---|---|---|
| Plex library DB — watch history, metadata, collections, server identity | `~/.local/share/plexmediaserver` | 764 MB | **[ONLY]** |
| Claude Code setup — CLAUDE.md, 4 hand-written skills, settings; none in a repo | `~/.claude/{CLAUDE.md,skills,settings*.json}` | ~40 KB | **[ONLY]** |
| Claude memory store | `~/.claude/projects/-home-kevin/memory/` | ~20 KB | **[ONLY]** |
| pi agent config — auth, settings, extensions, sessions | `~/.pi/agent/` | ~1 MB | **[ONLY]** |
| `dms-audio-inhibit` — last hand-written script not in the repo | `~/.local/bin/dms-audio-inhibit` | 1.5 KB | **[ONLY]** |
| ~~CK3 saves~~ — **skipped by decision** | `~/.local/share/Paradox Interactive` | 602 MB | — |
| ~~Proton prefixes + Steam userdata~~ — **skipped by decision** | `~/.local/share/Steam/{userdata,steamapps/compatdata}` | 780 MB | — |
| Wi-Fi — 4 PSKs Kevin actually uses, extracted to `files/wifi-psk.txt` | `/etc/NetworkManager/system-connections` | 288 B | [REBUILD] |
| sqlit connections + query history | `~/.sqlit` | 8 KB | **[ONLY]** |
| hypa database | `~/.hypa/hypa.db` | 487 KB | **[ONLY]** |
| VSCode settings | `~/.config/Code/User/settings.json` | 4 KB | [REBUILD] |
| darktable library — film rolls, tags, ratings, collections | `~/.var/app/org.darktable.Darktable/config/darktable/` | 6.8 MB | **[ONLY]** |
| niri / DMS configs — won't run on Omarchy, keep for reference | `~/.config/{niri,DankMaterialShell}` | 3.8 MB | [REBUILD] |
| Everything stow-managed | `~/Work/dotfiles` | 624 KB | [SAFE] |

Dump the lists that exist nowhere else:

```sh
code --list-extensions > "$BACKUP/vscode-extensions.txt"
flatpak list --app --columns=application > "$BACKUP/flatpaks.txt"
dnf repoquery --userinstalled --qf '%{name}' | sort > "$BACKUP/dnf-packages.txt"
sudo cp -a /etc/NetworkManager/system-connections "$BACKUP/nm-connections"
```

---

## 03 — Deliberately not saving

~100 GB of the 136 GB in use.

- **Steam game files** — 40 GB, ~19 GB of it BG3. Redownloads. Keep `userdata` + `compatdata` only.
- **pnpm store** (7.8 GB), **mise installs** (2.3 GB), **NuGet cache** (509 MB), every `node_modules` — all regenerate from lockfiles.
- **Docker images/containers** — every one is on a registry or built from an in-repo Dockerfile.
- **Brave profile** (4.5 GB) — sign in and sync. Same for Firefox.
- **Tor Browser** (395 MB), **opencode** (345 MB), **pipx venvs** (387 MB), **nvim plugin store** (1.1 GB — `lazy-lock.json` is what matters and it's in the config).
- **Nerd Fonts** (269 MB) — Omarchy ships nerd fonts.
- **Downloads**, other than the wedding folder and personal PDFs.
- **`~/Desktop`** — a 45 MB heapsnapshot and its diagnostics json. Nothing else.
- **Rancher Desktop leftovers** — the `~/.rd/bin` block in `.bashrc` and the `isv:Rancher` repo are dead already.

---

## 04 — Before booting the installer

- [x] **Firmware — nothing to do.** Checked 2026-08-28: `fwupdmgr get-updates` → *No updates available*. System Firmware, UEFI dbx and the fingerprint sensor are all current. BIOS `03.20` (2026-06-23).
- [x] **Secure Boot already disabled.** Omarchy requires it off. TPM is present (`/dev/tpm0`) — the manual says turn that off too.
- [ ] **De-register Cloudflare WARP.** Team `crtwhl`, device ID `712a5281-1193-11f1-b64e-7abfabfd708c`. `warp-cli registration delete` so the old device doesn't eat a Zero Trust seat.
- [ ] **Note the WARP split-tunnel include list** (policy-pushed, should return on enrollment): AWS nonprod/prod `10.221.x` `10.222.x` `172.20.0.0/16`, DO `10.132.0.0/16` `10.136.0.0/16`, K8s `10.245.0.0/16`, Cloudflare One `172.64.128.0/20` + `2606:4700:cf1::/48`.
- [ ] **Deauthorize per-seat licences** — 1Password, Dropbox, Todoist, Slack, Zoom device lists.
- [x] **Backup verified by trial restore** (2026-08-28). All six archives gzip-checked; ssh key
  extracted at mode 600 and read by `ssh-keygen`; `git clone` from the Cartwheel bundle restored
  17 branches with the unpushed commit intact; Plex DB `integrity_check = ok` via Plex's own
  SQLite. The wedding folder on Hrothgar turned out to be 284 of 1379 files — resynced and
  re-diffed to zero. **This step is why.**
- [ ] **Bluetooth pairings die**: CIDOO V75-1 keyboard, Logitech LIFT, MX Anywhere 2. Have a wired mouse for first boot.
- [ ] **Fingerprint** (Goodix, right index) needs re-enrolling with `fprintd-enroll`.
- [ ] **Write the Omarchy ISO.** `omarchy-4.0.1.iso`, sha256 verified 2026-08-28 against the
  published release checksum: `69cbb4e10d98ad831c3c9f245b5757a9d1fedfd0c9592780e977d6f950dea8c3`.
  `caligula` is on the app wishlist but was never actually installed here — use `dd` or the
  `mediawriter` GUI. **Address the target by `/dev/disk/by-id/`, never `/dev/sdX`:** letters
  reshuffle whenever a USB drive comes or goes, and Hrothgar and the install stick have already
  swapped places once.
- [ ] **Know where Hrothgar is.** It holds every copy of everything. Don't format anything until
  it is physically accounted for and unplugged.
- [ ] **Accept that the install stick was the Fedora retreat media.** Writing Omarchy over the
  SanDisk destroys the `Fedora-WS-Live-43` image on it. Fine — 43 was stale, and Fedora 44 can be
  redownloaded from the new machine — but it means there is no bootable fallback in the drawer.

---

## 05 — Reinstall manifest, Fedora → Arch

Omarchy 4 ships as pacman packages and includes `yay`. 1Password, Spotify and Signal moved to
on-demand installs in Quattro.

### Job-critical

| App | On Arch | Notes |
|---|---|---|
| Cloudflare WARP | `yay -S cloudflare-warp-bin` | Then `sudo systemctl enable --now warp-svc`, `warp-cli teams-enroll crtwhl`. Cartwheel's README calls it "Cloudflare One Client". |
| Docker | `pacman -S docker docker-compose` | Enable socket, add self to `docker` group. Same shape as your Rancher→native migration. |
| mise | `pacman -S mise` | Carries node 24, pnpm 10, python, ruby. **Not dotnet** — see below. |
| .NET 8 + 10 SDK | `pacman -S dotnet-sdk dotnet-sdk-8.0` | Both are in `extra`, both install under `/usr/share/dotnet`, no conflict (`dotnet-sdk-8.0` declares `Provides: dotnet-sdk=8.0`). Same one-root, side-by-side model Fedora gives you today. |

**Do not use mise for dotnet.** .NET's side-by-side model needs *one* `DOTNET_ROOT` holding
every SDK and runtime — `sdk/8.0.x/` and `sdk/10.0.x/` under the same tree, one muxer
dispatching by `global.json`. Multi-level lookup was removed in .NET 7, so separate roots
cannot be chained: whichever `dotnet` is first on PATH is the only one that exists.

The mise install on this machine uses the **isolated** layout — one root per version, each with
its own muxer, one SDK, one runtime:

```
~/.local/share/mise/installs/dotnet/8.0.418/   sdk: 8.0.418   runtime: 8.0.24
~/.local/share/mise/installs/dotnet/10.0.103/  sdk: 10.0.103  runtime: 10.0.3
```

Neither root can build a solution that needs the other. Newer mise added a shared-`DOTNET_ROOT`
mode that does merge them, but that's a version-dependent behaviour to verify, not something to
bet the work machine on.

It's moot anyway: **mise was never managing dotnet here.** `mise current` lists node, python,
pnpm, ruby, opencode — no dotnet, and `mise which dotnet` errors with "not currently active."
The dnf packages are doing the work, exactly the way Arch's will:

```
$ dotnet --list-sdks
8.0.129  [/usr/lib64/dotnet/sdk]
10.0.110 [/usr/lib64/dotnet/sdk]
```

One root, both SDKs, both runtimes. `pacman -S dotnet-sdk dotnet-sdk-8.0` reproduces it.

**Note:** Cartwheel's current `main` targets `net10.0` in all four projects
(`Directory.Build.props` sets it globally) — no `net8.0` anywhere. The README's "install the
dotnet 8 SDK" may be stale for this branch. Install it regardless; it costs nothing and other
branches or tooling may still want it.
| AWS CLI | `pacman -S aws-cli-v2` | Restore `~/.aws/config`, then `aws sso login --sso-session crtwhl-g-suite`. |
| gh | `pacman -S github-cli` | Token is in the keyring, not `hosts.yml` — you will re-auth. Your gitconfig uses gh as the https credential helper, and airadoc/website + wireframe use https remotes. |
| 1Password | `yay -S 1password 1password-cli` | Or keep the flatpak. Omarchy's web-app wrapper reportedly doesn't play well with 1Password — install the real desktop app. |
| psql client | `pacman -S postgresql-libs` | For loading `carwheel-local.sql`. |

### Daily driver

- `pacman` (most already in Omarchy defaults): ghostty, neovim, lazygit, starship, zsh + autosuggestions + syntax-highlighting, fzf, eza, zoxide, ripgrep, bat, stow, btop, tmux, tmuxinator, jq, unzip
- `yay -S visual-studio-code-bin`
- `pacman -S steam` (enable multilib)
- `pacman -S lazydocker` — no more grabbing GitHub releases
- AUR: caligula, sqlit, rustdesk

### Flatpaks — reinstall by app ID

Every flatpak currently installed, so nothing gets lost in a comma list. `flatpak install flathub <id>`,
or Omarchy menu → Install where it offers one.

| App | ID | |
|---|---|---|
| **Todoist** | `com.todoist.Todoist` | ✅ **keep** — cloud-synced, no local data to carry |
| 1Password | `com.onepassword.OnePassword` | keep — job-critical |
| Slack | `com.slack.Slack` | keep — job-critical |
| Brave | `com.brave.Browser` | keep — sign in, profile re-syncs |
| Dropbox | `com.dropbox.Client` | keep — this is also your backup target |
| Obsidian | `md.obsidian.Obsidian` | keep — vaults live in the `rpg-campaigns` repo, see below |
| Zoom | `us.zoom.Zoom` | keep |
| Bruno | `com.usebruno.Bruno` | keep — API collections |
| Vesktop | `dev.vencord.Vesktop` | keep |
| Spotify | `com.spotify.Client` | keep |
| TIDAL Hi-Fi | `com.mastermindzh.tidal-hifi` | keep |
| LocalSend | `org.localsend.localsend_app` | keep |
| darktable | `org.darktable.Darktable` | keep — **has a library DB, see §02** |
| Easy Effects | `com.github.wwmm.easyeffects` | keep |
| Flatseal | `com.github.tchx84.Flatseal` | keep |
| Pinta | `com.github.PintaProject.Pinta` | optional |
| Foliate | `com.github.johnfactotum.Foliate` | optional |
| Fragments | `de.haeckerfelix.Fragments` | optional |
| Sly | `page.kramo.Sly` | optional |
| Sound Recorder | `org.gnome.SoundRecorder` | optional |
| Extension Manager | `com.mattjakeman.ExtensionManager` | ❌ **drop** — GNOME Shell extensions, meaningless under Hyprland |

**Obsidian vaults need no separate backup.** All five live inside
`~/Documents/rpg-campaigns`, which is a clean, fully-pushed git repo. Only the vault *registry*
(`~/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json`) is sandbox-local — three
entries, rebuilt by opening the folders once.

### Agent CLIs and TUIs

Easy to forget because none of them come from a package manager you'd think to check.

| Tool | How it's installed | Config to restore |
|---|---|---|
| **`pi`** (Pi coding agent) | global npm under mise's node: `npm i -g @earendil-works/pi-coding-agent` | `~/.pi/agent/` — see below |
| **`hypa`** | pi extension `@hypabolic/pi-hypa`; `~/.local/bin/hypa` is a shim to `~/.pi/agent/npm/node_modules/@hypabolic/hypa-linux-x64/bin/hypa` | `~/.hypa/hypa.db` (487 KB) |
| **`claude`** | official installer; `~/.local/bin/claude` → `~/.local/share/claude/versions/<v>` | `~/.claude/` (§02) |
| **`sqlit`** | `pipx install sqlit-tui` | `~/.sqlit/` (connections + query history) |
| **`lazydocker`** | was a GitHub release binary; **use `pacman -S lazydocker` now** | `~/.config/lazydocker` |
| **`tmuxinator`** | ruby gem under mise: `gem install tmuxinator` | stowed (`crtwhl.yml`) |
| **`starship`** | currently a manual `/usr/local/bin` install; **use `pacman -S starship`** | stowed |
| **`eza`, `rg`, `wthrr`** | `cargo install` today; `pacman -S eza ripgrep` is simpler, `wthrr` stays cargo | — |
| **`odin` / `ols` / `odinfmt`** | hand-placed in `~/.local/share/{odin,ols-src}`, ~142 MB, symlinked into `~/.local/bin` | only needed for the two toys in `~/Work/odin` — reinstall on demand |

**`pi` in detail.** Config lives in `~/.pi/agent/`: `auth.json` (credentials), `settings.json`,
`models-store.json`, `trust.json`, `sessions/`, and `npm/` holding the extensions. Two couplings
to Claude Code that break silently if restored out of order:

- `~/.pi/agent/AGENTS.md` is a **symlink to `~/.claude/CLAUDE.md`** — restore `~/.claude` first.
- `settings.json` sets `skills: ["~/.claude/skills"]`, so pi shares Kevin's hand-written skills.

Its `packages[]` list, for rebuilding by hand if the config doesn't restore cleanly:

```
npm:@aliaksei-raketski/pi-angular-developer   npm:@vigolium/piolium
npm:pi-web-access                             npm:pi-caveman
npm:@hypabolic/pi-hypa                        git:github.com/obra/superpowers
```

### Hand-written scripts in `~/.local/bin`

| Script | Status |
|---|---|
| `tmux-nuke`, `tmux-clear-panes` | ✅ **stowed 2026-08-28** into the `scripts` package — they come back with `stow scripts` |
| `smart-copy` / `smart-cut` / `smart-paste` | ✅ already in the `scripts` package |
| `niri-auto-display` | ✅ stowed, but don't restow it — see §08 |
| `dms-audio-inhibit` | ⚠️ **not in the repo.** DMS-specific (MPRIS idle-inhibit), so it dies with DMS either way — but back the file up: the logic may port to Hyprland's idle daemon. |
| `hypa` | regenerable shim, don't bother |

### Dead aliases in `.zshrc`

`y='yazi'` and `alias r='rails'` both point at things that aren't installed. Either install
`yazi` (`pacman -S yazi`) or drop the aliases while you're rewriting the shell config.

### Quietly retire

Installed here, not on your list, no evidence of use: `albert`, `ulauncher`, `vicinae`,
`danksearch` (three-and-a-half launchers — Omarchy has its own), `cava`, `gnome-boxes`, the
whole GNOME app suite, `torbrowser-launcher`, `caddy`, `postgresql-server` (you run Postgres
in docker), `opencode`, dnf's `dotnet-sdk-*`, the Rancher repo.

---

## 06 — Bringing Cartwheel and airadoc back up

### Shared groundwork

1. Restore `~/.ssh/id_ed25519`, `chmod 600`, `ssh -T git@github.com`.
2. `git clone git@github.com:kwhitaker/dotfiles.git ~/Work/dotfiles`, then
   `stow -d home_stow -t ~ ghostty lazygit starship tmuxinator shell scripts`.
   **Skip `niri-auto-display`** — see stage 08. The `scripts` package now carries
   `smart-copy`/`smart-cut`/`smart-paste` plus `tmux-nuke` and `tmux-clear-panes`.
3. `./install-system.sh` for the `90-autotz` NetworkManager dispatcher. Desktop-agnostic,
   works fine under Hyprland. Check with `journalctl -t autotz`.
4. Install mise, restore `~/.config/mise/config.toml` (node 24, pnpm 10, python latest, ruby latest), `mise install`.
5. `gh auth login`, `aws sso login`, WARP enrolled **and connected**.

### Cartwheel

1. Restore the bundle or re-clone; the four local-only branches come with it.
2. Drop `.env` and `.config/.env` back (both gitignored).
3. `docker compose -f eng/db/docker-compose.yml up -d` — Postgres 17.4-alpine on host **5433**.
   `docker compose -f eng/rabbit/docker-compose.yml up -d` — RabbitMQ on 5678/15678.
4. `psql -h localhost -p 5433 -U postgres -d cartwheel -f ~/Work/Cartwheel/carwheel-local.sql`.
   That dump is from 16 Jul — if too stale, re-dump with `pnpm cli:nobuild db-dump dev … --as local`
   (needs WARP + AWS SSO working).
5. `pnpm install` (engine-strict on, node ≥24, pnpm 11.9.0 via `packageManager`), then `dotnet build`.
6. `tmuxinator start crtwhl` → the 2×2 dev grid: UI, api, msg-worker, razor templates.

### airadoc

1. Restore the bundle — this is the repo with 9 unpushed commits and an agent worktree.
   Recreate the worktree with `git worktree add` if you still want it.
2. Restore four `.env` files: repo root, `apps/api/.env` (the big one), `apps/web-client/.env`,
   and the sibling `~/Work/airadoc/.env`.
3. `docker compose up -d` — Postgres (5432), Redis (6379), synapse-postgres (**5433**), synapse.
4. **Port collision:** airadoc's `synapse-postgres` and Cartwheel's `db` both bind host **5433**.
   Already true today; only Cartwheel's is running. You can't have both stacks up without
   remapping one. Worth fixing now.
5. `airadoc-synapse` builds from `docker/synapse` in-repo — nothing to back up, but first `up` is slow.
6. `pnpm install`, `pnpm --filter api prisma migrate deploy`, `prisma generate`, `turbo run dev`.
7. Synapse reaches the host via `host.docker.internal:host-gateway` — works the same on native
   docker on Arch, but it's the first thing to check if Matrix auth breaks.

### The WARP TLS gotcha

Cloudflare Gateway installs its own root CA (`/var/lib/cloudflare-warp/installed_certs/`) into
the system trust store. Fedora: `/etc/pki/ca-trust`. Arch: `/etc/ca-certificates/trust-source/anchors/`
then `sudo trust extract-compat`. If `pnpm install`, `dotnet restore` or `git clone` over https
start failing with certificate errors while WARP is connected, that cert didn't get installed.
Node may additionally need `NODE_EXTRA_CA_CERTS`.

---

## 07 — Plex

Media is on Beowulf (external USB) and the wipe never touches it. The library database is the catch.

### Stay with the user service — the reasoning checks out

Plex runs from `~/.config/systemd/user/plex.service` with
`PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=%h/.local/share/plexmediaserver`, deliberately, so it
runs as `kevin` and can read a udisks-mounted drive.

The blocker for the packaged system service isn't the mount options — it's the parent directory:

```
$ ls -ld /run/media/kevin
drwxr-x---+ root root /run/media/kevin

$ getfacl /run/media/kevin
user::rwx
user:kevin:r-x        # ← only kevin can traverse
group::r-x
mask::r-x
other::---
```

udisks2 creates that directory root-owned, `0750`, with an ACL granting traverse to the session
user alone. The system unit runs as `User=plex` (uid 967), which cannot get through it —
regardless of the mount's `uid=1000,gid=1000`. The only fix is moving the mount out of
`/run/media/kevin`, which costs the removable-drive affordance in the file browser. **Keeping the
user service is the right call.** Don't enable `plexmediaserver.service` on the new box.

### The path survives the migration

**Omarchy 4 ships `udiskie` for removable automount**, and udiskie mounts to
`/run/media/$USER/<label>` — the same convention udisks2/GNOME uses here. So
`/run/media/kevin/Beowulf` should come back byte-identical, and the two library roots keep
resolving:

```
[1] Movies    → /run/media/kevin/Beowulf/Movies
[2] TV Shows  → /run/media/kevin/Beowulf/TV Shows
```

**Verify the mount path before starting Plex for the first time.** If udiskie lands it somewhere
else, fix the path *then* — don't let Plex scan against a wrong or missing root.

*(Earlier draft of this doc suggested pinning it with an fstab entry. Not needed, and it would
cost you the file-browser entry. If you ever do want determinism, the option that keeps both is
`comment=x-gvfs-show` plus `noauto,x-systemd.automount` in fstab — but there's no reason to.)*

### The actual risk: a scan against a missing drive

`plex.service` waits for nothing:

```
$ systemctl --user show plex.service -p RequiresMountsFor
RequiresMountsFor=/usr/lib/plexmediaserver
```

Nothing about Beowulf. Today that's a race you happen to win. On a fresh install, with udiskie
timing instead of gvfs, Plex can easily start before the drive mounts — and
`Empty trash automatically after every scan` is **not set in your `Preferences.xml`**, so it's
running at Plex's built-in default rather than a choice you made. A scan with the drive absent
plus auto-empty-trash is how a library empties itself. The files are safe; the watch state,
collections and metadata are not.

Two mitigations, do both:

1. **Set the trash behaviour explicitly** in Settings → Library, rather than inheriting a default.
2. **Make the unit wait for the media root.** `RequiresMountsFor=` on a udisks mount is awkward
   (the `.mount` unit is transient and doesn't exist until the drive appears), so a bounded
   `ExecStartPre` is more predictable:

```ini
[Service]
ExecStartPre=/bin/sh -c 'for i in $(seq 60); do [ -d "/run/media/kevin/Beowulf/Movies" ] && exit 0; sleep 2; done; exit 1'
Restart=on-failure
RestartSec=10
```

### Moving the data

- **Stop Plex before copying.** Copying a live SQLite DB gives you a corrupt one.
- The support dir is `~/.local/share/plexmediaserver/Plex Media Server/` (the env var points one
  level above). `Preferences.xml` holds `MachineIdentifier`, `ProcessedMachineIdentifier` and
  `PlexOnlineUsername` — restoring it is what keeps the server claimed and linked to your
  account. Starting fresh means re-claiming and a full re-scan.
- On Arch: `yay -S plex-media-server`, then **don't enable its system unit**. Copy your user unit
  back and `systemctl --user enable --now plex`.
- **Check the binary path before reusing the unit verbatim.** Fedora puts it at
  `/usr/lib/plexmediaserver/Plex Media Server`; confirm Arch's with
  `pacman -Ql plex-media-server | grep 'Plex Media Server$'` and adjust `ExecStart` /
  `WorkingDirectory` if it differs.
- exfat needs `exfatprogs` on Arch for udiskie to mount the drive at all.
- `Linger=no` today, so Plex stops when you log out. That's fine for a laptop — but if you want
  it serving without a session, `loginctl enable-linger kevin`.

---

## 08 — What doesn't survive the desktop change

Omarchy is Hyprland + Quickshell. DMS is also Quickshell, but they're different shells — none
of this config transfers.

- **`~/.config/niri/config.kdl`** (280 lines of keybinds and rules) → rewrite as `hyprland.conf`.
  Keep the old file as reference for the bindings you actually use.
- **DMS `settings.json`** (22 KB) and `monitors.json` display profiles → gone.
- **`niri-auto-display`** — your systemd user service that toggles the internal panel on dock
  hotplug. It's niri-specific (calls `niri msg`). Hyprland emits real monitor events and has
  `monitor=` rules plus `hyprctl`, so this problem may just not exist. Don't stow that package;
  see whether you need it first. Update the dotfiles README either way.
- **ghostty `theme = dankcolors`** — that theme file is written by DMS's matugen run and won't
  exist. Your own README says the walk-back is `theme = Catppuccin Mocha`.
- **nvim** — `colors/dms.lua` pulls from the DMS palette. Same problem, same fix. Everything
  else in the LazyVim config is portable; `lazy-lock.json` restores the exact plugin set.
- **Login shell** is currently `/bin/bash` with ghostty launching zsh via `command = /usr/bin/zsh`.
  Decide whether to `chsh -s /usr/bin/zsh` properly this time.
- **`.bashrc` cruft** — drop the Rancher Desktop block and the `~/.opencode/bin` line.
- **`.zshrc` sets a bogus `DOTNET_ROOT`.** Line 125 exports `DOTNET_ROOT="$HOME/.dotnet"`, but
  that directory holds only first-run sentinel files — no `sdk/`, no `shared/`. The `dotnet` CLI
  ignores it (the muxer resolves from its own location), which is why nothing has broken, but
  framework-dependent apphosts *do* consult it. Drop the line, or point it at the real root
  (`/usr/share/dotnet` on Arch). Keep `$DOTNET_ROOT/tools` on PATH for global dotnet tools.

---

## 09 — Framework 13 AMD, specifically

- **amd-ucode** must be in the initramfs — Omarchy's installer handles it, verify after first boot.
- **Suspend** on 7040 wants `s2idle` and a recent kernel; check `cat /sys/power/mem_sleep`.
- **Fingerprint**: `fprintd` + `libfprint`, re-enroll, add `pam_fprintd` if you want it for sudo.
- **fwupd** works on Arch — install early so BIOS updates keep flowing.
- **zram**: you currently swap on an 8 GB zram device with no disk swap. Hibernation would need
  a real swap partition/file sized to RAM; otherwise replicate zram.
- **LUKS**: Omarchy encrypts by default. TPM unlock is off the table since the manual says
  disable TPM — expect to type a passphrase at boot.

---

## 10 — Backup: DONE 2026-08-28

Taken to **Hrothgar** (2 TB exfat USB, `WDC WD20NMVW`), at
`/run/media/kevin/Hrothgar/boudica-cutover/`. 2.0 GB plus the 32 GB of photos already
on the drive. Every archive gzip-verified; a trial restore of the ssh key, the Claude
config, two git bundles and the Plex database all passed.

### What went

| Path | Size | Contains |
|---|---|---|
| `bundles/*.bundle` | 231 MB | 5 repos, `--all`. Confirmed: airadoc's 9 unpushed commits, Cartwheel's `e5064afd66`, all 10 local-only branches |
| `archives/work.tar.gz` | 566 MB | `~/Work` minus node_modules, `.venv`, `artifacts/`, obj. Untracked plans/docs/sql included |
| `archives/home-config.tar.gz` | 147 MB | `.ssh` (mode 600 preserved), `.claude` + all memory stores, `.pi/agent`, `.aws`, `.kube`, `.sqlit`, `.hypa`, `.gitconfig`, `.config/{git,mise,nvim,niri,DankMaterialShell,Code/User,btop,lazydocker,systemd/user}`, `dms-audio-inhibit` |
| `archives/plex-library.tar.gz` | 597 MB | Support dir, taken with Plex stopped. `integrity_check = ok`, 1042 items, 133 watched, identity intact |
| `archives/documents.tar.gz` | 357 MB | `~/Documents`, all five Obsidian vaults |
| `archives/pictures-videos.tar.gz` | 56 MB | `~/Pictures`, `~/Videos` |
| `archives/cartwheel-db-17.sql` | 29 MB | `pg_dumpall` of the live dev DB, fresher than `carwheel-local.sql` |
| `archives/darktable.tar.gz` | 298 KB | `library.db` + `data.db` |
| `files/env/` | 10 files | Every gitignored `.env`, flattened and browsable |
| `files/downloads/` | 15 MB | Passport scan, FPCA forms, character sheets, WhatsApp images |
| `files/plex.service` | — | The user unit |
| `manifests/` | — | 506 dnf packages, 21 flatpaks, 39 vscode extensions, mise tools, cargo bins, pipx, wifi list, bluetooth pairings, system snapshot |

### Photos — the backup was NOT what it looked like

`Photo Backup/JJ Wedding` on Hrothgar held **284 of 1379 files** and **zero `.xmp`
sidecars** — an interrupted copy that stopped at `L1000746.DNG` on 21 Aug. Missing were
182 DNGs, 264 JPGs, the whole `export/` folder, and every darktable edit.

Resynced 2026-08-28: 1,095 files / 21 GB transferred. Both sides now 1379 files, 32 GB,
zero diff, all 649 sidecars present.

**This is the argument for §04's "restore one thing to verify it".** The drive looked
right from the outside.

### Wi-Fi

Only the four networks in regular use were kept, as PSKs rather than connection files:

    files/wifi-psk.txt    One Does Not Simply Connect · Muehle · KW Samsung · Shire

**This file is plaintext on an exfat volume with no permissions. Move it into 1Password
and delete it.** It is a stopgap, not a resting place.

The other four saved profiles — `FRITZ!Box 7590 TH`, `FRITZ7490office Gastzugang`,
`MagentaWLAN-CEED`, `Warwick_Guest` — were deliberately dropped. Travel and guest
networks, last used March–June, rejoin from the phone if ever needed. `Warwick_Guest`
is open anyway.

Rejoining on the new machine is just `nmcli device wifi connect "<ssid>" password "<psk>"`,
or the Omarchy network menu.

**If you'd rather restore the real profiles instead** (keeps per-network settings, not just
the password), grab the files before the wipe — this needs a password so it wasn't scripted:

```sh
sudo tar -czf /run/media/kevin/Hrothgar/boudica-cutover/archives/nm-connections.tar.gz \
  -C /etc/NetworkManager system-connections
```

Restoring them on Arch — same keyfile format, same path, and `wlp1s0` keeps its name because
it derives from the PCI path:

```sh
sudo tar -xzf .../nm-connections.tar.gz -C /etc/NetworkManager
sudo chown -R root:root /etc/NetworkManager/system-connections
sudo chmod 600 /etc/NetworkManager/system-connections/*.nmconnection   # NM ignores any other mode
sudo nmcli connection reload
```

### Deliberately excluded

Steam games, CK3 saves, Proton prefixes, node_modules, pnpm store, mise installs, NuGet,
.NET `artifacts/` (3.6 GB), docker images and volumes, Brave profile, nerd fonts, the
nine git stashes, and Dropbox (re-syncs from the cloud).

