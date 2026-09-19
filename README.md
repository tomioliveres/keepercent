# Keepercent

> *keeper + percent* — a handball goalkeeper's scouting tool: rival shots turned into percentages.

**ACoding Hackathon 2026** · Solo project · 100% native Swift & SwiftUI, zero third-party dependencies.

## The problem

Amateur handball goalkeepers scout rival teams before every match: who shoots from where, towards which part of the goal, and how it ends. The existing tools are built for coaches keeping full match statistics. They record a shot that hits the frame as a single "post" event, and they hide goalkeeper analysis behind a paid plan.

A goalkeeper needs the detail those tools drop: *which* post, *which* part of the crossbar, and how the rival goalkeeper behaves, so the team knows where to shoot.

## What it does

- **Record a shot in 3–4 taps**: shooter, court origin, goal target, outcome. Live from the bench, or calmly while watching a rival's match video.
- **Goal-frame detail no other app has**: left/right post (top, middle, bottom), crossbar (left, center, right), and misses by direction.
- **Shooter card**: court and goal heatmaps that filter each other. Pick a court zone, see where those shots went.
- **Rival goalkeeper card**: save rate per goal zone, so you can tell your teammates where to shoot.
- **Insights in plain language**, generated on device.

## Status

Work in progress during the hackathon (Sep 18–27, 2026). See [docs/mvp.md](docs/mvp.md) for the full definition, scope and plan.

## Requirements

- Xcode 26, iOS/iPadOS 26
- No dependencies, no account, no backend. All data stays on the device.

## AI usage

Generative AI was used as a coding assistant during development, and Apple's on-device Foundation Models power the natural-language insights inside the app. All statistics are computed by tested, deterministic code; the model only phrases results it is given.
