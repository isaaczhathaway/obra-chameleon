# Ubuntu Installation

> **WARNING: THIS MOD MAY GET YOU BANNED. USE AT YOUR OWN RISK. DO NOT USE IT ON PUBLIC SERVERS.** Anti-cheat and integrity behavior has not been confirmed.

These instructions are for the normal Linux Steam client running Meccha Chameleon through Proton.

## Requirements

- Meccha Chameleon installed through Steam
- `bash`, `curl`, `sha256sum`, and either `7z` or `7zz`
- Internet access while installing the official ReShade runtime

On Ubuntu, the required 7-Zip command is normally provided by the `p7zip-full` or `7zip` package available for your Ubuntu release.

## Install

1. Extract `Obra Chameleon v0.2.zip` directly into the Meccha Chameleon game root.
2. Open a terminal in the game root.
3. Preview the installation:

```bash
bash "./Obra Chameleon/ubuntu/install.sh" --dry-run
```

4. Install:

```bash
bash "./Obra Chameleon/ubuntu/install.sh"
```

5. In Steam, open Meccha Chameleon > Properties > General > Launch Options.
6. Paste this exact launch option:

```text
WINEDLLOVERRIDES="dxgi=n,b" %command%
```

The Steam launch option is required. The installer deliberately does not change the Proton prefix or global graphics configuration.

## First Test

1. Launch the game through Steam.
2. Confirm that the ReShade status text appears while the game starts.
3. Press `Home` to open the overlay.
4. Confirm that `MecchaObraDinn@MecchaObraDinn.fx` is enabled.
5. Press `Scroll Lock` to compare the original and processed image.

Test in the menu or private/solo play while anti-cheat compatibility remains unconfirmed.

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

Only remove `dxgi.dll` and `ReShade.ini` when they belong to this installation. Steam file verification can restore changed game-owned files, but it does not usually remove these extra files.
