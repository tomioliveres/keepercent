# Final layered app icon

The production source is [`Keepercent/AppIcon.icon`](../../Keepercent/AppIcon.icon), an editable native Icon Composer package with three independent SVG planes. It was first integrated on 2026-10-15 and revised for Liquid Glass on 2026-10-23.

## Final artwork

- The composition is unchanged: goal with striped posts, net, white chevron and percentage sign, and the court with the 6 m, 7 m and 9 m lines.
- The white chevron has symmetric arm geometry.
- The percentage sign is 12 % larger and uses a brighter cyan; both dots carry handball seams.
- The 7 m mark is centered at x=627 on the 1254-unit artwork canvas.
- No flat PNG replaces the layered asset.

## Liquid Glass revision (2026-10-23)

- **Background:** a deep navy arena with a soft top spotlight replaces the near-black crowd; the crowd texture stays at 40 % strength.
- **Court:** the goal-area band uses the court's blue family instead of grey teal; the 4 m mark is removed (it stacked with the 7 m mark into an "="); the 7 m mark is wider; a soft contact shadow and faint post reflections ground the goal on a glossy floor.
- **Symbols layer:** baked cast shadows and depth outlines are removed, and the layer has `glass` and `specular` on, so Icon Composer draws depth once instead of twice.
- **Tinted and Clear appearances:** the symbols fill white, the goal drops to 55 % opacity and the court to 35 %, so the chevron and percentage sign stay legible ([native renders](integration/evidence/glass-revision-appearances.png): Default, Dark, Tinted, Clear).

## Verification

See [the final evidence record](integration/evidence/final-verification.md) for artifact hashes, native preview, installed Light/Dark evidence, and the exact distinction between the installed pre-centering package and the final single-coordinate correction. The user explicitly requested no repeated Simulator run for the correction or integration.

The legacy appiconset remains intact as a reversible fallback. Xcode already uses the `AppIcon` asset name; no project-setting changes were needed.

## Local historical material

The approved raster, candidate packages, recovery copies, and original experiment logs are preserved locally. They are not alternate production assets and are excluded from the closing commit. Historical task entries may refer to these local-only paths. The native package format was initially checked against Apple's official Landmarks sample; no sample artwork or downloaded archive is shipped in the app.
