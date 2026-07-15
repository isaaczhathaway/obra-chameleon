# Packaging

Version 0.2 ships one archive containing a shared shader payload and separate Ubuntu, Bazzite, and Windows installers.

The archive contains:

- custom shaders and presets;
- shared ReShade configuration;
- platform-specific installer scripts and guides;
- GPL-3.0-only license;
- package and payload checksum manifests.

It does not contain ReShade executables or DLLs. Each installer obtains official ReShade 6.7.3 components and verifies pinned SHA-256 values.

Build from the repository root:

```bash
scripts/build-release.sh --force
sha256sum "Obra Chameleon v0.2.zip" > "Obra Chameleon v0.2.zip.sha256"
```

Before publishing, run the repository audit, inspect `zipinfo -1`, validate the internal checksum files, test the native installers, and compare the downloadable archive against the published `.sha256` asset.
