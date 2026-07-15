# Contributing

This repository is intentionally located inside a Meccha Chameleon game installation. Treat repository hygiene as a release requirement.

## Safety rules

- Never add game executables, packaged assets, Proton-prefix files, ReShade binaries, caches, backups, logs, or local test results.
- Never use `git clean -fd` or `git clean -fdx` from this working tree.
- Keep ReShade and other third-party binaries out of commits and release archives.
- Test only in private or solo contexts until anti-cheat behavior is known.
- Run `scripts/audit-repository.sh --staged` before every commit.

## Source layout

- `reshade/Shaders/`: custom shader source and diagnostics
- `reshade/Presets/`: shared presets
- `scripts/package/`: platform installers and package documentation
- `scripts/build-release.sh`: deterministic release builder
- `docs/`: curated public technical notes

Use tabs for indentation in shell, PowerShell, and shader code where the surrounding file uses indentation. Keep platform installers separate while sharing payload and validation logic where practical.

## Validation

Run:

```bash
bash -n scripts/build-release.sh scripts/audit-repository.sh
bash -n scripts/package/ubuntu/install.sh scripts/package/bazzite/install.sh
bash -n scripts/package/common/install-linux-common.sh
scripts/build-release.sh --force
unzip -t "Obra Chameleon v0.2.zip"
```

Then test the relevant installer on its native platform, launch the game privately, confirm the ReShade overlay opens, toggle the effect, and check menus and representative gameplay.
