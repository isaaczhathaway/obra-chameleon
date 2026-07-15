# Testing

## Automated checks

The repository validation workflow:

- audits every tracked path and scans text files for local paths, credentials, and private keys;
- syntax-checks and lints shell scripts;
- builds the v0.2 release archive;
- rejects bundled ReShade executables and DLLs;
- verifies package checksums and the JSON manifest;
- runs the Windows installer in a fixture with `-DryRun -NoPause`;
- verifies that the CMD launcher invokes PowerShell and pauses.

## Manual scene matrix

Native testing should include bright outdoor and dark indoor scenes, silhouettes, fine geometry, fast camera motion, particles, transparent materials, characters, dense HUD, menus, combat, and large depth ranges.

For each supported platform:

1. Extract the package directly into the game root.
2. Run the platform installer and retain its terminal output.
3. Launch through Steam in a private or solo context.
4. Open the ReShade overlay with `Home`.
5. Toggle the shader with `Scroll Lock`.
6. Check the default and performance presets.
7. Confirm stationary dithering, acceptable menu readability, and stable frame pacing.
8. Capture the renderer, resolution, graphics settings, average FPS, 1% low, and GPU frame time when available.

A platform is marked validated only after native installation, launch, toggle, screenshot, and representative play-session checks pass.
