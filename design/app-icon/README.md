# Final layered app icon

The production source is [`Keepercent/AppIcon.icon`](../../Keepercent/AppIcon.icon), an editable native Icon Composer package with three independent SVG planes. It is integrated and closed at the user's request on 2026-10-15.

## Final artwork

- The white chevron has symmetric arm geometry and matching depth/shadow outlines.
- Both percentage dots use the same material treatment, preserving their positions and radii.
- The 7 m mark is centered at x=627 on the 1254-unit artwork canvas.
- The approved goal, net, court, palette, and native layer configuration are retained. No flat PNG replaces the layered asset.

## Verification

See [the final evidence record](integration/evidence/final-verification.md) for artifact hashes, native preview, installed Light/Dark evidence, and the exact distinction between the installed pre-centering package and the final single-coordinate correction. The user explicitly requested no repeated Simulator run for the correction or integration.

The legacy appiconset remains intact as a reversible fallback. Xcode already uses the `AppIcon` asset name; no project-setting changes were needed.

## Local historical material

The approved raster, candidate packages, recovery copies, and original experiment logs are preserved locally. They are not alternate production assets and are excluded from the closing commit. Historical task entries may refer to these local-only paths. The native package format was initially checked against Apple's official Landmarks sample; no sample artwork or downloaded archive is shipped in the app.
