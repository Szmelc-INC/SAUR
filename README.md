# Szmelc AUR

**SAUR** for short: the pacman repository of everything Szmelc.INC builds, rebuilt automatically from git.

```sh
curl -fsSL https://szmelc-inc.github.io/SAUR/add | sudo bash
```

That's it. The one-liner trusts the SAUR signing key for pacman, adds `[saur]` to `/etc/pacman.conf` with `SigLevel = Required`, runs `pacman -Syy` and greets you once with a few snippets for browsing. After that it never talks again: plain `pacman -Syu` keeps every Szmelc package fresh, and pacman refuses anything SAUR did not sign.

Added SAUR before it was signed? Run the same one-liner again. It imports the key and switches your existing entries to `SigLevel = Required`, quietly.

Want the experimental builds too (side branches, work in progress)?

```sh
curl -fsSL https://szmelc-inc.github.io/SAUR/add-ex | sudo bash
```

[![build](https://github.com/Szmelc-INC/SAUR/actions/workflows/build.yml/badge.svg)](https://github.com/Szmelc-INC/SAUR/actions/workflows/build.yml)
[![packages](https://img.shields.io/badge/browse-packages-105c5c)](https://szmelc-inc.github.io/SAUR)
[![signed](https://img.shields.io/badge/signed-ed25519-7fffd4)](#signed)
[![license: MIT](https://img.shields.io/badge/license-MIT-c0c0c0.svg)](LICENSE)
![arch: x86_64](https://img.shields.io/badge/arch-x86__64-105c5c?logo=archlinux&logoColor=white)

<details>
<summary>Prefer to do it by hand, or read the script first?</summary>

Trust the signing key. Its fingerprint is `@FPR_PRETTY@`, compare it with the one on [the site](https://szmelc-inc.github.io/SAUR):

```sh
curl -fsSLO https://szmelc-inc.github.io/SAUR/key.asc
sudo pacman-key --add key.asc
sudo pacman-key --lsign-key @FPR@
```

Then add this to `/etc/pacman.conf` and run `sudo pacman -Syy`:

```ini
[saur]
SigLevel = Required
Server = https://szmelc-inc.github.io/SAUR/$arch
Server = https://github.com/Szmelc-INC/SAUR/releases/download/$arch

# optional: experimental channel
[saur-ex]
SigLevel = Required
Server = https://szmelc-inc.github.io/SAUR/$arch
Server = https://github.com/Szmelc-INC/SAUR/releases/download/$arch
```

Or check the add script's signature before it runs as root:

```sh
curl -fsSL -O https://szmelc-inc.github.io/SAUR/key.asc -O https://szmelc-inc.github.io/SAUR/add -O https://szmelc-inc.github.io/SAUR/add.asc
gpg --import key.asc && gpg --verify add.asc add && sudo bash add
```
</details>

## Browse

```sh
pacman -Sl saur                                       # everything stable
pacman -Sl saur-ex                                    # everything experimental
pacman -Si $(pacman -Slq saur)                        # details
pacman -Slq saur | fzf --preview 'pacman -Si saur/{}' | xargs -ro sudo pacman -S
```

Or browse <https://szmelc-inc.github.io/SAUR>. It has a tab per channel, and you can link straight to one: [#stable](https://szmelc-inc.github.io/SAUR/#stable), [#experimental](https://szmelc-inc.github.io/SAUR/#experimental) or [#all](https://szmelc-inc.github.io/SAUR/#all). Every row has a copy-ready `pacman -S` line, the build date, the package and its signature and, for experimental builds, the branch and commit they come from. Press `/` to filter, sort by name, newest or size, and follow the links to [szmelc.com](https://szmelc.com), [Szmelc-INC on GitHub](https://github.com/Szmelc-INC), the build log or a new issue.

The page is dark by default (neutral near-black greys, no tint) with a light toggle that it remembers. Colors: Szmelc dirty cyan `#105c5c` is the accent (`SAUR_COLOR`), silver `#c0c0c0` the second one for labels and secondary text (`SAUR_SILVER`), aquamarine `#7fffd4` a rare highlight, only the "signed" badge (`SAUR_AQUA`). The experimental tab switches the accent to dark red `#750f0f` (`SAUR_EX_COLOR`).

Machine-readable lists live at [`packages.json`](https://szmelc-inc.github.io/SAUR/packages.json) and [`packages.txt`](https://szmelc-inc.github.io/SAUR/packages.txt), each with a `.asc` signature. In `packages.json`, every entry says whether it is `signed` and where its `signature` is; experimental entries also carry `branch` and `commit`. New builds show up in the Atom feed [`feed.xml`](https://szmelc-inc.github.io/SAUR/feed.xml).

## Signed

One ed25519 key signs everything SAUR publishes, so there is no doubt what comes from Szmelc.INC:

- every package (the signature is embedded in the database and also sits next to the file as `.sig`),
- both databases, `saur.db` and `saur-ex.db`, and their `.files`,
- the add scripts and the package lists: `add.asc`, `add-ex.asc`, `packages.json.asc`, `packages.txt.asc`.

Fingerprint: **`@FPR_PRETTY@`**. The public key is [`keys/saur.asc`](keys/saur.asc) in this repo and [`key.asc`](https://szmelc-inc.github.io/SAUR/key.asc) on the site. The add script carries it inline, imports it into pacman's keyring and signs it locally (`pacman-key --lsign-key`), so pacman trusts it for SAUR and the key gets no other power. `SigLevel = Required` then makes pacman refuse an unsigned or modified package or database from any mirror.

What a signature proves: the file was built and published by SAUR's own pipeline from Szmelc.INC sources (or `repos.extra`). The secret key lives only in the repo's Actions secret `SAUR_GPG_KEY` and the maintainer's keyring. `bin/saur` takes it out of the environment before any build starts, and PKGBUILD build functions run as an unprivileged user that cannot reach it. Install scripts of build dependencies (which may come from SAUR itself) do run as root in the same container, so push access to a Szmelc-INC repo is, in effect, signing access: guard it like the key. On `main` a run without the key fails instead of publishing unsigned files, and `saur release push` refuses anything that `saur verify` would not pass.

Check a local copy yourself: `saur verify` (all files against `SAUR_KEY`), or `pacman-key --verify saur.db.sig saur.db`.

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

If GitHub ever starts charging, the same script builds, signs and serves SAUR on any Linux box with docker or podman. Arch is not required:

```sh
git clone https://github.com/Szmelc-INC/SAUR && cd SAUR
echo 'SAUR_URL=http://my-box:8080' > saur.local.conf   # where clients will reach it
echo "SAUR_MIRRORS=''" >> saur.local.conf
bin/saur run          # build everything in an Arch container → ./public
bin/saur serve        # http://0.0.0.0:8080
bin/saur timer install  # nightly rebuild at midnight + server, as systemd user units
```

Not in the `docker` group? Use `SAUR_ENGINE="sudo docker"` or `"pkexec docker"`, or install podman. Point clients at it with `curl -fsSL http://my-box:8080/add | sudo bash`.

Signing works the same away from GitHub: with the SAUR secret key in your gpg keyring (`gpg --import`), `bin/saur run` hands it to the build container by name and signs everything. Your own instance gets its own key with `bin/saur key gen` (writes `keys/saur.asc` and `SAUR_KEY`), and `bin/saur key upload` stores it as the `SAUR_GPG_KEY` secret of `SAUR_GH_REPO`. Without any key the add script falls back to `SigLevel = Optional TrustAll`.

## The `saur` CLI

| command | what it does |
|---|---|
| `saur run [-f] [-r] [-n] [REPO…]` | scan, build what changed, regenerate the site (CI and the timer call this) |
| `saur build …` | same without the site |
| `saur scan [--json]` | every source (repo branch) with HEAD, last state and planned action |
| `saur list [-s\|-x] [--json]` | packages of both channels, or only stable (`-s`) / experimental (`-x`) |
| `saur status [--json]` | ok / failed / idle and channel per source |
| `saur serve [-p PORT]` | HTTP server for `public/` |
| `saur release pull\|push` | sync packages with the GitHub release (push refuses anything unsigned) |
| `saur key [show\|export\|gen\|upload]` | the signing key: fingerprint, public key, create one, store it as the CI secret |
| `saur sign [-f]` | sign every package, database and list that lacks a valid signature |
| `saur verify [-a] [--json]` | check every signature against `SAUR_KEY`, exit 1 on any problem |
| `saur timer install\|remove\|status` | systemd user units for self-hosting |
| `saur extra ls\|add\|rm [--ex\|--stable]` | manage `repos.extra` |
| `saur config [--json]` · `saur doctor` · `saur init` · `saur clean` | config, checks, setup, cleanup |
| `saur completion bash\|zsh\|fish` | shell completion |

Global flags: `-H/--home DIR`, `-q/--quiet`, `--no-color` (or `NO_COLOR`). Use `saur help <command>` for details. Configuration lives in [`saur.conf`](saur.conf). `saur.local.conf` (gitignored) and `SAUR_*` env vars override it.

Install the tool itself with `sudo pacman -S saur/saur` once the repo is added, or `cd packaging && makepkg -si`, or `nix run github:Szmelc-INC/SAUR`.

## Limits worth knowing

- Signatures prove where a package comes from, not that its code is safe. Anyone who can push to a Szmelc-INC repo can get a package built and signed.
- x86_64 only for now. `arch=('any')` packages land there too.
- GitHub Pages serves up to about 1 GB. That is plenty for scripts and small binaries.
- Experimental side-by-side install is best effort, see [Stable and experimental](#stable-and-experimental).
- PKGBUILDs build in a clean Arch container from the official repos. AUR-only dependencies won't resolve unless the dependency is itself in SAUR.

## License

[MIT](LICENSE)
