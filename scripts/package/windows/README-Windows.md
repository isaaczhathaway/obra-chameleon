# Windows Installation

The Windows installer downloads and opens the official ReShade setup program. One guided ReShade step is required before the script installs the Obra Chameleon shader and default preset.

## Requirements

- Windows 10 or Windows 11
- Meccha Chameleon installed through Steam
- Windows PowerShell 5.1 or newer
- Internet access while installing ReShade

Administrator access should not be required for a normal Steam library owned by your user account.

## Install

1. In Steam, open Meccha Chameleon > Manage > Browse local files.
2. Close the game.
3. Extract `Obra Chameleon v0.2.zip` into the folder Steam opened.
4. Confirm that the extracted `Obra Chameleon` folder is inside the game folder. The installer can also handle one extra `Obra Chameleon v0.2` wrapper folder created by Windows Extract All.
5. Open `Obra Chameleon\windows`.
6. Double-click `Install Obra Chameleon.cmd`. You can also right-click it and select **Open**.

The command launcher is the recommended installation method. It opens PowerShell with a process-scoped execution-policy bypass and keeps the terminal open after success, installer errors, PowerShell parse errors, or a missing PowerShell executable. Administrator access is not requested.

When the official ReShade window opens, select:

```text
Chameleon\Binaries\Win64\PenguinHotel-Win64-Shipping.exe
```

Select `Microsoft DirectX 10/11/12` as the rendering API. Skip the optional effect-package download because Obra Chameleon includes every shader it needs. Finish and close the official setup; the installer will then verify ReShade and install the custom files.

## Advanced PowerShell Use

To preview the custom-file installation without changing anything, open PowerShell in the game root and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Obra Chameleon\windows\install.ps1" -DryRun
```

To install without using the command launcher:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Obra Chameleon\windows\install.ps1"
```

The installer displays its detected package and game paths at startup. It waits for Enter before closing after both success and failure, so error messages remain visible.

## First Test

1. Launch Meccha Chameleon normally from Steam.
2. Confirm that ReShade status text appears during startup.
3. Press `Home` to open the overlay.
4. Confirm that `MecchaObraDinn@MecchaObraDinn.fx` is enabled.
5. Press `Scroll Lock` to toggle the effect.

Test in the menu or private/solo play while anti-cheat compatibility remains unconfirmed.

## Manual Removal

There is no uninstall script in v0.2. Remove these project-installed files from `Chameleon\Binaries\Win64\`:

```text
dxgi.dll
ReShade.ini
Meccha_ObraDinn_Default.ini
Meccha_ObraDinn_HighContrast.ini
Meccha_ObraDinn_SoftDither.ini
Meccha_ObraDinn_Performance.ini
Meccha_ObraDinn_Debug.ini
reshade-shaders\Shaders\MecchaObraDinn.fx
reshade-shaders\Shaders\MecchaCommon.fxh
reshade-shaders\Shaders\MecchaDiagnostics\
```

Only remove `dxgi.dll` and `ReShade.ini` when they belong to this installation. Steam file verification can restore changed game-owned files, but it does not usually remove these extra files.
