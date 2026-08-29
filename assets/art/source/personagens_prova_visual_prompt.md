# Prompt da prova visual de personagens

Ferramenta: `imagegen` integrada da OpenAI.

## 1. Conceito-base

```text
Use case: stylized-concept
Asset type: first visual-direction proof for two original PC game characters; concept proof, not a final animation sheet
Input image: use the user's screenshot only as a reference for pixel-art density, earthy atmosphere, hard-edged rendering, and isometric 3/4 readability. Do not copy its character, buildings, composition, text, ornaments, or identifiable details.
Primary request: create one clean comparison sheet with two entirely original full-body characters from an arid Brazilian sertao setting: the playable Cangaceiro on the left and the enemy Capanga on the right.
Scene/backdrop: genuinely transparent background; no scenery, no floor panel, no frame, no labels
Composition/framing: characters separate, side by side, same foot baseline, no overlap, facing screen-down/right in a readable isometric three-quarter pose; generous transparent padding
Cangaceiro: natural stylized proportions; upright posture; visually slimmer, equivalent to 48 pixels tall and about 24 pixels wide on a 64x64 logical sprite canvas; distinctive original broad leather cangaceiro hat, worn gibao/leather jacket, simple bandolier, rifle held close to the body without widening the silhouette excessively
Capanga: natural stylized proportions; equivalent to 48 pixels tall and about 26 pixels wide; slightly lower shoulders and broader silhouette; darker worn sertao clothing, reinforced leather vest with a few dull metal plates, low hat; empty hands visible, no invented weapon
Style/medium: authentic low-resolution 2D pixel art with square pixels, crisp clusters, complete one-pixel black outer outline, no anti-aliasing, no soft brushwork, no gradients
Lighting/mood: warm sun fixed from upper-left; hard shadows; selective dithering only on worn leather and cloth; gritty but highly readable
Color palette: one shared palette of at most 16 visible colors, dominated by warm earth browns, ochres, rust, cream, near-black, muted olive, with turquoise used only as a tiny interaction/magical accent
Constraints: original designs, PC game readability, clear silhouettes, natural rather than chibi proportions, coherent scale, no text, no watermark, no logo, no UI, no extra characters, no decorative border, no cast shadow outside the sprites
Avoid: generic American cowboy styling, photorealism, painterly rendering, smooth shading, 3D render, excessive microdetail, giant heads, oversized weapons
```

## 2. Simplificação técnica

```text
Use case: style-transfer
Asset type: technical low-resolution pixel-sprite scale proof, not final animation
Input image: the immediately previous generated Cangaceiro-and-Capanga concept is the edit target. Preserve only the two approved character identities, costume language, relative silhouette difference, and upper-left lighting. Simplify everything else.
Primary request: redraw the same two characters as truly low-resolution production-style sprites for a 64x64 logical game canvas.
Composition/framing: a clean horizontal comparison sheet with exactly two separate square sprite cells, Cangaceiro left and Capanga right. In each logical cell the feet must share the same bottom-center anchor at x=32, y=60. Each character must be exactly about 48 logical pixels tall. Cangaceiro body silhouette about 24 pixels wide; Capanga about 26 pixels wide. Both face screen-down/right in the same isometric three-quarter direction. No overlap.
Rendering method: visibly coarse, deliberate pixel clusters as if authored directly at 64x64; square pixels only; complete one-logical-pixel black outer outline; no antialiasing; no subpixel detail; no smooth curves; no gradients. Show the logical pixels enlarged uniformly for inspection, not high-resolution pseudo-pixel art.
Simplification: reduce hat ornaments to two or three bold clusters; reduce faces to essential light/shadow clusters; simplify bandolier, rifle, vest plates, fingers, fabric texture, and boots so every feature survives at actual 48-pixel height.
Palette: exactly one shared set of no more than 16 flat colors total across both sprites, including transparency and black outline; warm earth browns, ochres, rust, cream, muted olive, dull metal, one tiny turquoise accent.
Lighting: warm hard light from upper-left; two or three shade levels per material at most; selective dithering only in one or two small leather/cloth areas.
Background: genuinely transparent.
Constraints: keep characters natural-proportioned and original; no labels, no grid lines, no checkerboard baked into the image, no frame, no scenery, no cast shadows, no UI, no additional poses, no extra objects, no watermark.
Avoid: high-resolution pixel simulation, hundreds of tiny pixels, painterly shading, soft edges, chibi anatomy, exaggerated heads, American-western cowboy styling, additional colors.
```

O resultado gerado usado como fonte está em `personagens_conceito_simplificado.png`. Seu fundo quadriculado foi removido pelo script `assets/art/tools/build_character_prototype.py`; a extração não alterou os desenhos aprovados.
