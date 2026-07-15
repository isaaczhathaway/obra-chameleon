# Compatibility

## Current matrix

| Area | Current result |
| --- | --- |
| Game renderer | Direct3D 12 |
| Proton translation | VKD3D-Proton |
| Approximate engine | Unreal Engine 5.6 |
| ReShade | 6.7.3, downloaded from the official site |
| Ubuntu | Locally validated |
| Bazzite | Installer fixture and dry-run validated; native device test pending |
| Windows | Automated PowerShell validation; native device test pending |
| HDR | Development tests used HDR off |
| Depth buffer | Not confirmed; not required by the default effect |
| Anti-cheat | No confirmed result; public multiplayer testing is not recommended |

## Rendering and UI

The default shader uses scene color only, so it can operate without depth, normals, or motion vectors. It affects the complete presented frame, including menus and HUD. Dense menus can be temporarily restored by pressing `Scroll Lock`, or made more legible by increasing the virtual resolution and reducing edge or dither strength.

The current Linux path uses `dxgi.dll` with the game-specific Steam override:

```text
WINEDLLOVERRIDES="dxgi=n,b" %command%
```

No global Wine or Vulkan settings are required.

## Safety

Testing should remain in the main menu, tutorial, solo play, or private sessions until anti-cheat and file-integrity behavior is independently confirmed. The project does not bypass or disable integrity protections.
