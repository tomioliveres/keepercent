# Keepercent

*keeper + percent*: a handball goalkeeper scouting app for iPhone and iPad. Rival shots become percentages.

**Status:** in development. App Store release planned for November 2026. The source code is private and available for review on request; contact me through my GitHub profile.

<!-- Screenshots: add current App Store captures here -->

## The problem

Before a match, a handball goalkeeper wants to know where each rival shooter shoots from, where the shot goes, and how it ends. Generic stats apps rarely record goalkeeper-level detail, such as which post or crossbar segment a shot hit. Keepercent records those shots and turns them into scouting.

## What the app does

- **Fast shot entry.** Pick the shooter, tap the court origin, tap the goal target. Goal or saved is asked only when the shot lands inside the frame. Works live from the bench or from a match video.
- **Detailed targets.** A 3x3 goal grid, post and crossbar segments, and directional misses. 7 m throws are kept separate from field play.
- **Linked scouting cards.** For rival shooters and goalkeepers: selecting a court zone filters the goal view, and the reverse.
- **Sample-aware statistics.** Shooter effectiveness and goalkeeper save rate use different denominators, and missing data is never shown as 0%.
- **Plain-language insights** phrased from the computed statistics.
- **Shareable reports.** A goalkeeper report image for the team, plus a backup file that can be imported on another device.
- **Offline and private.** No account, no ads, no backend. English and Spanish.

## Tech stack

- Swift and SwiftUI, native-first
- SwiftData for local storage, with versioned schemas and migration stages
- Swift Testing for the domain layer; UI flow tests with accessibility audits, plus snapshot tests for views
- iOS and iPadOS 26 minimum, built with Xcode 27
- Offline by design, no backend

## Architecture and engineering practices

Dependencies point from the app into a pure Swift domain package, never the other way:

```text
App target
  SwiftUI views (presentational, receive plain values)
  Feature containers (queries, writes, conversion to domain values)
  SwiftData persistence (primitive codes and coordinates)
        |
        v
Domain package (Foundation only: values, geometry, statistics, insight text)
```

- **Pure domain package.** Shots, rosters, court and goal geometry, the statistics engine and the insight text live in a package that imports only Foundation, so it is unit-tested without a simulator.
- **Deterministic statistics.** Every number comes from tested code. Insight text is produced from facts already computed; no model computes figures.
- **Container and presentational views.** Queries stay in container views. Presentational views only draw the values they are given, and the statistics engine never receives a persistence context.
- **Primitive persistence.** The store keeps codes and normalized coordinates; rich types are exposed by the domain, so zones can be redefined without losing recorded shots.
- **Strict TDD in the domain** with Swift Testing: red, green, refactor.
- **View coverage.** UI flow tests, accessibility audits and snapshot tests run as permanent regression suites.
- **Migration safety.** Schema versions are explicit, and a store-compatibility check opens stores written by earlier versions before a schema change is accepted.
- **One gate script.** A single script runs domain tests, store-compatibility checks, an app build and the UI tests, and every change passes it.

Current size: about 730 domain test cases in 44 test files, plus about 70 UI flow and accessibility tests.

## Origin

Built from scratch for the ACoding Hackathon 2026 (Apple Coding Academy, September 18-27, 2026), then continued as a personal project.

## Links

- Study log (Spanish): https://tomioliveres.github.io/keepercent/
- Privacy policy: [privacy.html](privacy.html) · https://tomioliveres.github.io/keepercent/privacy.html
- Support: [support.html](support.html) · https://tomioliveres.github.io/keepercent/support.html

This repository holds the public site only: `index.html` (study log), `privacy.html` and `support.html`.

Copyright © 2026 Tomás Oliveres. All rights reserved.
