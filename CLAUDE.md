# SAUR (Szmelc AUR): working rules

## Finish every change

A change is done only when everything it touches is done. Never leave half of a feature for later. Every change carries through to:

- `bin/saur`: the code, `--help` text (global and per command), and bash/zsh/fish completions.
- The generated site (`saur site`: `index.html`, `packages.json`, `packages.txt`, `add`/`add-ex`) whenever packages, channels or metadata change.
- Docs and config: `README.md`, `saur.conf` (with a comment per option), `CONFIG_VARS`, and the `load_config` defaults.
- Packaging: bump the version together in `bin/saur` (`SAUR_VERSION`), `packaging/PKGBUILD` (`pkgver`) and `flake.nix` (`version`).
- CI: `.github/workflows/build.yml`, if the build or publish flow changes.
- Verification on real data. `bin/saur release pull`, then `bin/saur site`, with `SAUR_OUT`/`SAUR_STATE`/`SAUR_WORK` pointing at a temporary directory. Look at the page in light and dark mode at desktop and phone width. Get a green CI run on the branch before calling it done.
- Live checks after a merge: the main CI run succeeds, and the live site shows the change.

When a build fails because of a PKGBUILD in another repo, name the repo and the cause in the report. Do not change other repos without asking.

## Better idea? Do it, then say so

If you see a better solution than the one asked for, implement the better one. Then tell the user in the report what you changed from the request, and why. Keep the user's intent (what they wanted to achieve). The literal wording may change.

## Brand

- Szmelc dirty cyan `#105c5c` is the main accent of every design here: site (`SAUR_COLOR`), CLI output, the add-script welcome. No purple, no default accents.
- Dark red `#750f0f` marks experimental (`SAUR_EX_COLOR`).
- Both colors are dark. Use them as fills with white text. On a dark background, tint them toward white for text. The CLI uses `#1f8a8a` and `#b83a3a` in 24-bit mode, and plain cyan and red otherwise.
- Second accent: silver `#c0c0c0` (`SAUR_SILVER`) for labels, secondary text and outlines; darken it on light backgrounds. Third accent, used sparingly: aquamarine `#7fffd4` (`SAUR_AQUA`), today only the "signed" badge, as a fill with black text.
- Everything else is neutral: near-black and dark-grey backgrounds and surfaces (`#0b0b0b`, `#131313`, `#1b1b1b`, lines `#262626`), with no green or blue tint. The site is dark by default; the light theme is a toggle with neutral greys.

## Signing

- Everything published is signed by `SAUR_KEY`: packages (embedded with `repo-add --include-sigs`), both databases, and `add`, `add-ex`, `packages.json`, `packages.txt` (`.asc`). Any new published file people execute or parse gets a signature too (`SITE_SIGNED`).
- Every database write must end with a valid signature: call `sign_repo` after it. Never use `repo-add -R` (it deletes the new file when the name repeats; `db_gc` cleans up).
- The secret key never reaches a PKGBUILD: `main` moves `$SAUR_GPG_KEY` into a shell variable, `as_builder` strips it, the container gets it by name only. It is never in `CONFIG_VARS`.
- Test signing locally with a throwaway key in a temporary `GNUPGHOME`, never with the real one.

## Local testing

The user is not in the docker group. Use `SAUR_ENGINE="pkexec docker"`, and never `sudo`.
