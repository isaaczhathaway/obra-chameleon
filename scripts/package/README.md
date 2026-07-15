# Obra Chameleon v0.2

Obra Chameleon is a custom ReShade effect for Meccha Chameleon. It applies a two-color palette, ordered dithering, virtual-resolution sampling, and color-edge enhancement inspired by the visual principles of Return of the Obra Dinn. It does not contain or redistribute assets from that game.

## Before Installing

1. In Steam, open Meccha Chameleon > Manage > Browse local files.
2. Close Meccha Chameleon.
3. Extract `Obra Chameleon v0.2.zip` into that game folder.
4. Confirm that `Obra Chameleon` and `PenguinHotel.exe` are next to each other.
5. Follow exactly one platform guide:

- [Ubuntu](ubuntu/README-Ubuntu.md)
- [Bazzite](bazzite/README-Bazzite.md)
- [Windows](windows/README-Windows.md)

The package contains only the custom shader, presets, configuration, and installer scripts. It downloads the normal ReShade 6.7.3 setup program from the official ReShade website and verifies the tested SHA-256 checksum. It does not bundle ReShade binaries or official shader packs.

Obra Chameleon's original shader code, presets, scripts, and documentation are licensed under GPL-3.0-only. The full license is included as `LICENSE`.

## Default Look

The default preset contains the author's current settings:

- Warm paper and dark-brown palette
- 1280 x 720 virtual resolution
- 2 x 2 virtual pixels at a 2560 x 1440 game resolution
- Brightness `0.10`
- Contrast `1.15`
- Gamma `1.25`
- Ordered dithering and color edges enabled

The effect still works at other aspect ratios and display resolutions. Adjust the virtual width and height in the ReShade overlay if the pixel scale is too large or small.

## Controls

- `Home`: open or close the ReShade overlay
- `Scroll Lock`: toggle all ReShade effects
- `Ctrl+R`: reload the shader
- `Page Up` / `Page Down`: change presets

## Important Warnings

- Anti-cheat has not been confirmed absent. Test in the menu, tutorial, solo play, or a private session rather than public multiplayer.
- The shader affects menus and UI because it is a fullscreen effect.
- Steam's Verify integrity feature does not normally delete extra ReShade files. Each platform guide includes a manual file list for removal.
- Existing ReShade or `dxgi.dll` installations are not overwritten. The installer stops and asks the user to resolve the conflict.

## Package Integrity

`manifest.json` records the expected game executable, pinned ReShade version, default preset, and packaged file checksums. `SHA256SUMS` and `common/PAYLOAD-SHA256SUMS` provide command-line verification on systems with `sha256sum`.
