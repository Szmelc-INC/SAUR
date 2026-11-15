# Szmelc AUR

**SAUR** for short: the pacman repository of everything Szmelc.INC builds, rebuilt automatically from git.

```sh
curl -fsSL https://szmelc-inc.github.io/SAUR/add | sudo bash
```

That's it. The one-liner adds `[saur]` to `/etc/pacman.conf`, runs `pacman -Syy` and greets you once with a few snippets for browsing. After that it never talks again: plain `pacman -Syu` keeps every Szmelc package fresh.

Want the experimental builds too (side branches, work in progress)?

```sh
curl -fsSL https://szmelc-inc.github.io/SAUR/add-ex | sudo bash
```

[![build](https://github.com/Szmelc-INC/SAUR/actions/workflows/build.yml/badge.svg)](https://github.com/Szmelc-INC/SAUR/actions/workflows/build.yml)
[![packages](https://img.shields.io/badge/browse-packages-8a2be2)](https://szmelc-inc.github.io/SAUR)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![arch: x86_64](https://img.shields.io/badge/arch-x86__64-1793d1?logo=archlinux&logoColor=white)

<details>
<summary>Prefer to edit pacman.conf by hand?</summary>

```ini
[saur]
SigLevel = Optional TrustAll
Server = https://szmelc-inc.github.io/SAUR/$arch
Server = https://github.com/Szmelc-INC/SAUR/releases/download/$arch

# optional: experimental channel
[saur-ex]
SigLevel = Optional TrustAll
Server = https://szmelc-inc.github.io/SAUR/$arch
Server = https://github.com/Szmelc-INC/SAUR/releases/download/$arch
```

Then run `sudo pacman -Syy`.
</details>

## Browse

```sh
pacman -Sl saur                                       # everything stable
pacman -Sl saur-ex                                    # everything experimental
pacman -Si $(pacman -Slq saur)                        # details
pacman -Slq saur | fzf --preview 'pacman -Si saur/{}' | xargs -ro sudo pacman -S
```

Or browse <https://szmelc-inc.github.io/SAUR>. It has a tab per channel, and you can link straight to one: [#stable](https://szmelc-inc.github.io/SAUR/#stable), [#experimental](https://szmelc-inc.github.io/SAUR/#experimental) or [#all](https://szmelc-inc.github.io/SAUR/#all). Every row has a copy-ready `pacman -S` line, the build date and, for experimental builds, the branch and commit they come from. The page uses Szmelc dirty cyan (`SAUR_COLOR`, `#105c5c`) and switches to dark red (`SAUR_EX_COLOR`, `#750f0f`) on the experimental tab.

Machine-readable lists live at [`packages.json`](https://szmelc-inc.github.io/SAUR/packages.json) and [`packages.txt`](https://szmelc-inc.github.io/SAUR/packages.txt). In `packages.json`, experimental entries also carry `branch` and `commit`.

## Stable and experimental

| channel | pacman repo | built from | package names |
|---|---|---|---|
| stable | `[saur]` | each repo's default branch | as in the PKGBUILD: `foo` |
| experimental | `[saur-ex]` | every other branch | suffixed: `foo-ex` |

Every branch of every repo is scanned. The default branch goes to stable and any other branch goes to experimental. Branches already merged into the default one, or still at the same commit, are skipped. So are `dependabot/*`, `renovate/*` and `gh-pages` (see `SAUR_IGNORE_BRANCHES`).

Experimental packages are renamed so they install next to the stable ones: `foo-ex`, with the description tagged `[experimental: branch@commit]`. Inside the package, the commands in `/usr/bin`, man pages, bash/zsh/fish completions, `.desktop` entries, licenses and docs get the suffix too, so you run `foo` and `foo-ex` side by side. Inherited `provides`/`conflicts` that point at the package itself are renamed as well (a `foo-git` with `provides=(foo) conflicts=(foo)` becomes `foo-git-ex` providing `foo-ex`), and `replaces` is dropped, so `pacman -Syu` never swaps a stable package for an experimental one. The PKGBUILD's own functions still see the original `$pkgname`, so paths like `/usr/share/$pkgname` stay what the author wrote.

**The PKGBUILD decides.** Put one line in it to override the branch rule:

```bash
_saur_channel=experimental   # or: stable, skip
```

While building, `$SAUR_CHANNEL` is `stable` or `experimental`, so a PKGBUILD can do its own thing (another install prefix, extra flags). `_saur_ex_rename=0` turns the automatic renaming off for that PKGBUILD.

**Where side by side stops.** Some files can't be renamed safely: shared data such as `/usr/share/foo/…` or `/etc/foo.conf`, systemd units, and scripts that call themselves by name. When the experimental package still ships a file the stable one owns, SAUR adds `conflicts=(foo)`. Pacman then swaps one for the other cleanly instead of failing on a file clash. To get both at once, install those files under a `$SAUR_CHANNEL`-dependent path in the PKGBUILD.

One package name, one source. If two branches build the same `foo-ex`, the first one to publish keeps it. A default branch always takes a name back from a side branch.

## How it works

```
nightly cron / push / manual / repository_dispatch
        │
        ▼
 list every repo in Szmelc-INC  +  repos.extra  −  repos.ignore
        │   git ls-remote: every branch, compared with saur-state.tsv (kept in the release, not in git)
        ▼
 changed branch → blobless clone → every file named PKGBUILD → channel (PKGBUILD, else branch)
        │   makepkg inside the PKGBUILD's own directory (local .install files work)
        ▼
 repo-add → saur.db / saur-ex.db ──► GitHub Release "x86_64"  (durable package storage, mirror #2)
                                └──► GitHub Pages             (short URL, mirror #1)
```

- **Change detection.** A branch is rebuilt when its HEAD moves, so new code and PKGBUILD edits both count. Branches without a PKGBUILD are remembered too, and nothing gets cloned until they change.
- **Upgrades that actually upgrade.** If a PKGBUILD has a static `pkgver` and the code changed, SAUR bumps `pkgrel` past the published one. Without that, `pacman -Syu` would never notice the new build. `-git` packages with `pkgver()` version themselves.
- **Failures stay local.** A broken package keeps its last good build online. It is retried when its repo changes, or by hand with `--retry-failed`. Every run writes a summary table in the Actions tab.
- **Cleanup.** Packages from repos or branches that were deleted, merged, archived or lost their PKGBUILD are unpublished.
- **Dependencies.** Packages can depend on each other: the repo being built is visible to pacman during the build.

## Add your project

Put a `PKGBUILD` in a public repo under [Szmelc-INC](https://github.com/Szmelc-INC), at the root or in a folder like `packaging/arch/`. Folders named `tests/`, `examples/`, `vendor/` and similar are skipped. It appears after the next nightly run, or right away if you run the workflow by hand: *Actions → build → Run workflow*.

Push a branch with a changed PKGBUILD or code and it shows up as `foo-ex` in `[saur-ex]`. Merge it and the experimental build goes away; the stable `foo` picks up the change.

Repos from elsewhere (a personal account, Codeberg, anything git) go in [`repos.extra`](repos.extra):

```
serainox420/some-tool                     # every branch, like an org repo
serainox420/other-tool@dev                # only this branch, as the main source
serainox420/wild-idea@wip experimental    # force a channel
https://codeberg.org/someone/thing.git
```

To keep a repo out, list it in [`repos.ignore`](repos.ignore).

### Rebuild on push (optional)

The nightly run is enough. For instant updates, add this to a project repo. `SAUR_TOKEN` is a token with *Contents: write* on Szmelc-INC/SAUR; set it once as an org secret.

```yaml
# .github/workflows/saur.yml
on: { push: { branches: [main] } }
jobs:
  saur:
    runs-on: ubuntu-latest
    steps:
      - run: gh api repos/Szmelc-INC/SAUR/dispatches -f event_type=saur-rebuild -f "client_payload[repos]=${{ github.event.repository.name }}"
        env: { GH_TOKEN: "${{ secrets.SAUR_TOKEN }}" }
```

## Free forever (and plan B)

SAUR is a public repo, and GitHub Actions minutes on public repos are free. Packages live in a Release, and the index lives on Pages. GitHub turns off scheduled workflows after 60 days without repo activity, so the workflow commits a heartbeat when things get quiet.

If GitHub ever starts charging, the same script builds and serves SAUR on any Linux box with docker or podman. Arch is not required:

```sh
git clone https://github.com/Szmelc-INC/SAUR && cd SAUR
echo 'SAUR_URL=http://my-box:8080' > saur.local.conf   # where clients will reach it
echo "SAUR_MIRRORS=''" >> saur.local.conf
bin/saur run          # build everything in an Arch container → ./public
bin/saur serve        # http://0.0.0.0:8080
bin/saur timer install  # nightly rebuild at midnight + server, as systemd user units
```

Not in the `docker` group? Use `SAUR_ENGINE="sudo docker"` or `"pkexec docker"`, or install podman. Point clients at it with `curl -fsSL http://my-box:8080/add | sudo bash`.

## The `saur` CLI

| command | what it does |
|---|---|
| `saur run [-f] [-r] [-n] [REPO…]` | scan, build what changed, regenerate the site (CI and the timer call this) |
| `saur build …` | same without the site |
| `saur scan [--json]` | every source (repo branch) with HEAD, last state and planned action |
| `saur list [-s\|-x] [--json]` | packages of both channels, or only stable (`-s`) / experimental (`-x`) |
| `saur status [--json]` | ok / failed / idle and channel per source |
| `saur serve [-p PORT]` | HTTP server for `public/` |
| `saur release pull\|push` | sync packages with the GitHub release |
| `saur timer install\|remove\|status` | systemd user units for self-hosting |
| `saur extra ls\|add\|rm [--ex\|--stable]` | manage `repos.extra` |
| `saur config [--json]` · `saur doctor` · `saur init` · `saur clean` | config, checks, setup, cleanup |
| `saur completion bash\|zsh\|fish` | shell completion |

Global flags: `-H/--home DIR`, `-q/--quiet`, `--no-color` (or `NO_COLOR`). Use `saur help <command>` for details. Configuration lives in [`saur.conf`](saur.conf). `saur.local.conf` (gitignored) and `SAUR_*` env vars override it.

Install the tool itself with `sudo pacman -S saur/saur` once the repo is added, or `cd packaging && makepkg -si`, or `nix run github:Szmelc-INC/SAUR`.

## Limits worth knowing

- Packages are not signed yet, hence `SigLevel = Optional TrustAll`. Signing with a key stored in repo secrets is a small follow-up.
- x86_64 only for now. `arch=('any')` packages land there too.
- GitHub Pages serves up to about 1 GB. That is plenty for scripts and small binaries.
- Experimental side-by-side install is best effort, see [Stable and experimental](#stable-and-experimental).
- PKGBUILDs build in a clean Arch container from the official repos. AUR-only dependencies won't resolve unless the dependency is itself in SAUR.

## License

[MIT](LICENSE)
