# Shader Design

The effect is implemented as a modular ReShade post-process pipeline:

1. Sample scene color at either display or virtual-pixel coordinates.
2. Convert color to perceptual luminance.
3. Apply brightness, contrast, and gamma shaping.
4. Evaluate a stable 2x2, 4x4, or 8x8 Bayer threshold.
5. Map the result to user-selected dark and light palette colors.
6. Optionally detect luminance edges with a Sobel filter.
7. Optionally combine available depth or reconstructed-normal edges.
8. Blend the stylized result with the original frame.

The default preset uses a warm two-color palette, a 1280x720 virtual resolution, stable virtual-pixel dithering, and color-based edges. Its settings are exposed in the ReShade overlay and can be reloaded without reinstalling.

Diagnostic shaders visualize raw color, luminance, Sobel magnitude, depth, depth gradients, and reconstructed normals. Depth-dependent features are optional because usable depth access is not yet confirmed on every renderer and scene.

Known limitations include processing the UI with the world, shimmer from game-side temporal effects, and reduced text readability at very low virtual resolutions.
