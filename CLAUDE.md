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

- Szmelc dirty cyan `#105c5c` is the brand and stable color (`SAUR_COLOR`).
- Dark red `#750f0f` marks experimental (`SAUR_EX_COLOR`).
- Both colors are dark. Use them as fills with white text. On a dark background, tint them toward white for text.

## Local testing

The user is not in the docker group. Use `SAUR_ENGINE="pkexec docker"`, and never `sudo`.
