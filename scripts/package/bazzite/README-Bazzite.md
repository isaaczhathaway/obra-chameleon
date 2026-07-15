# Bazzite Installation

> **WARNING: THIS MOD MAY GET YOU BANNED. USE AT YOUR OWN RISK. DO NOT USE IT ON PUBLIC SERVERS.** Anti-cheat and integrity behavior has not been confirmed.

These instructions apply to Bazzite using Steam and Proton. Installation stays inside the game directory and does not use `rpm-ostree`, install a global Vulkan layer, or modify the Proton registry.

## Requirements

- Meccha Chameleon installed through Steam
- `bash`, `curl`, `sha256sum`, and either `7z` or `7zz`
- Internet access while installing the official ReShade runtime

If neither `7z` nor `7zz` is available, install a 7-Zip-compatible command-line tool using your preferred Bazzite-supported user-level method, then rerun the installer. The script will stop before changing files when this dependency is missing.

## Install

1. Switch to Desktop Mode.
2. In Steam, open Meccha Chameleon > Manage > Browse local files.
3. Extract `Obra Chameleon v0.2.zip` into the folder Steam opened.
4. Open a terminal in that folder.
5. Preview the installation:

```bash
bash "./Obra Chameleon/bazzite/install.sh" --dry-run
```

6. Install:

```bash
bash "./Obra Chameleon/bazzite/install.sh"
```

7. In Steam, open Meccha Chameleon > Properties > General > Launch Options.
8. Paste this exact launch option:

```text
WINEDLLOVERRIDES="dxgi=n,b" %command%
```

The launch option is required in both Desktop Mode and Gaming Mode. No Proton registry or global graphics setting is changed.

## First Test

1. Launch from Steam in Desktop Mode first.
2. Confirm that ReShade status text appears during startup.
3. Press `Home` and confirm `MecchaObraDinn@MecchaObraDinn.fx` is enabled.
4. Press `Scroll Lock` to toggle the effect.
5. After desktop testing, repeat in Gaming Mode.

A keyboard may be needed for the initial ReShade overlay and toggle test. Test in the menu or private/solo play while anti-cheat compatibility remains unconfirmed.

## Manual Removal

There is no uninstall script in v0.2. Remove the Steam launch option first, then remove these project-installed files from `Chameleon/Binaries/Win64/`:

```text
dxgi.dll
ReShade.ini
Meccha_ObraDinn_Default.ini
Meccha_ObraDinn_HighContrast.ini
Meccha_ObraDinn_SoftDither.ini
Meccha_ObraDinn_Performance.ini
Meccha_ObraDinn_Debug.ini
reshade-shaders/Shaders/MecchaObraDinn.fx
reshade-shaders/Shaders/MecchaCommon.fxh
reshade-shaders/Shaders/MecchaDiagnostics/
```

Only remove `dxgi.dll` and `ReShade.ini` when they belong to this installation. Steam file verification does not normally delete these extra files.
