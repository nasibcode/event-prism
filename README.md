# EventPrism _(event-prism)_

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](./LICENSE)

**EventPrism** maps a canonical `track` call onto per-destination JSON catalogs, then fans out to app-owned adapters.

It is not a vendor SDK, not a megafile of every analytics provider, and not a flush of Firebase/Braze queues. SPM product: **`EventPrism`**. Package: **`event-prism`**.

## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
- [Features](#features)
- [Repository map](#repository-map)
- [What this will not do](#what-this-will-not-do)
- [Docs](#docs)
- [Contributing](#contributing)
- [License](#license)

## Background

Feature modules should speak product language (`screen_viewed`, `page_name`). Vendor event names and key remaps belong in JSON the composition root loads — one file per destination — wrapped in `CompositeEventCatalog`.

```
Feature ──track(name, properties)──► EventPrism actor
                                        │
                                        ├─ skip if dest is unregistered or mapping is nil
                                        └─ transform (text / keys / values) ──► destination.log(payload)
```

`track`, `register`, and `unregister` return immediately. Delivery walks registered destinations by id, skips when `catalog.mapping` is nil, otherwise builds a `DestinationPayload` and calls `log`. Vendor types never appear in `Sources/EventPrism/`.

## Install

Requires Swift 6.2 tools (Swift 6 language mode). Library platforms: iOS 16+, macOS 13+. Demo app: iOS 17+ Simulator.

### Dependencies

- Xcode or a Swift 6.2 toolchain
- No Firebase, Braze, or Datadog packages in this repo

### From source

```bash
git clone https://github.com/nasibcode/event-prism.git
cd event-prism
swift build
swift test
```

### As a package dependency

```swift
// Package.swift
.package(url: "https://github.com/nasibcode/event-prism.git", branch: "main")
```

```swift
.product(name: "EventPrism", package: "event-prism")
```

Until a version tag exists, depend on `branch: "main"`. A local `path:` dependency works while developing next to this clone.

## Usage

First win: load two catalogs, register adapters, `track` a canonical event.

```swift
import EventPrism

let firebaseMap = try JSONDestinationCatalog(url: firebaseJSON)
let brazeMap = try JSONDestinationCatalog(url: brazeJSON)
let catalog = CompositeEventCatalog(firebaseMap, brazeMap)
let prism = EventPrism(catalog: catalog)
prism.register(FirebaseDestination(analytics: firebase))
prism.register(BrazeDestination(braze: braze))

prism.track("screen_viewed", properties: [
    "page_name": .string("home"),
    "page_title": .string("Welcome"),
])
```

Each adapter’s `id` must match the catalog file `"id"`. Features never mention destination ids. `unregister` only removes the adapter from EventPrism.

Pass `logger:` on `EventPrism` (and catalog load) for skip / `log` diagnostics. Pass `strict: true` on `JSONDestinationCatalog` to fail boot on invalid JSON instead of dropping that destination.

After `register`, tests or UI that `track` immediately should `await prism.waitUntilIdle()` so the destination is stored. That wait is **not** a vendor SDK flush. Adapters must return quickly from `log`; hop to the main actor if the SDK requires it.

### Catalog JSON

One object per destination. Schema: [`Sources/EventPrism/Catalog.schema.json`](./Sources/EventPrism/Catalog.schema.json).

```json
{
  "schemaVersion": 1,
  "id": "firebase",
  "events": {
    "screen_viewed": true
  },
  "mappings": {
    "screen_viewed": {
      "text": "screen_view",
      "keys": {
        "page_name": "screen_name"
      },
      "values": {
        "page_name": {
          "home": "home page: ${page_title}",
          "default": "other page"
        }
      }
    }
  }
}
```

| Field | Role |
| --- | --- |
| `id` | Must match `AnalyticsDestination.id` |
| `events[name] == true` **and** `mappings[name]` | Eligible; otherwise that dest is skipped |
| `text` | Vendor event name |
| `keys` | Canonical property name → vendor key |
| `values` | Canonical value → vendor value; `${other_key}` interpolation and `default` |
| Unmapped keys | Always pass through |

A registered destination with no mapping logs `skip`. An unregistered destination is silent.

### Demo app

Interactive Simulator dashboard (not a vendor integration):

1. Open [`Examples/EventPrismDemoApp/EventPrismDemoApp.xcodeproj`](./Examples/EventPrismDemoApp/EventPrismDemoApp.xcodeproj), pick an iOS Simulator, Run.
2. Destination chips call `register` / `unregister`. Catalog JSON still owns mappings.
3. Open an event, choose which dests receive that track (UI filter), Track.
4. The log shows canonical input vs per-destination payload or skip.

Known dest ids: `firebase`, `braze`, `print`. The print catalog only allows `debug_only`.

### Commands

| Command | Use when |
| --- | --- |
| `swift test` | Run Swift Testing (`EventPrismTests`) |
| `swift build` | Build the library |
| Open the demo `.xcodeproj` | Inspect mapping and skip on a Simulator |

## Features

| Piece | Role |
| --- | --- |
| **`EventPrism`** | Actor fan-out: map then `log` |
| **`JSONDestinationCatalog`** | One destination file (`schemaVersion` 1) |
| **`CompositeEventCatalog`** | Merge catalogs without a megafile |
| **`EventTransformer`** | `text` / `keys` / `values` + pass-through |
| **`RecordingDestination`** | Test sink; pair with `waitUntilIdle` |
| **Demo app** | Register dests, attach dests to an event, inspect payloads |

## Repository map

```text
Sources/EventPrism/          Engine (Foundation only) + Catalog.schema.json
Tests/EventPrismTests/       Swift Testing + Fixtures/
Examples/EventPrismDemoApp/  Simulator UI + live catalog JSON
wiki/                        Concept and reference pages
```

Harness plans and reports stay machine-local (`~/.cursor/harness/event-prism/`), not in this clone.

## What this will not do

- Ship or initialize Firebase, Braze, Datadog, or any vendor SDK
- Put every vendor in one catalog file
- Wait for vendor queues (`waitUntilIdle` is in-flight EventPrism work only)
- Let feature modules name destination ids
- Redesign your analytics taxonomy for you

## Docs

| Document | Description |
| --- | --- |
| [wiki/concepts/event-prism.md](./wiki/concepts/event-prism.md) | What EventPrism is and is not |
| [wiki/concepts.md](./wiki/concepts.md) | Concept index (track, catalog, mapping, …) |
| [wiki/docs.md](./wiki/docs.md) | Reference index |
| [wiki/sources.md](./wiki/sources.md) | Source index |

## Contributing

Questions and bugs: [GitHub Issues](https://github.com/nasibcode/event-prism/issues). Pull requests are welcome.

Keep catalogs and vendor adapters in the app; mapping stays in this package. New tests use Swift Testing (`@Test`, `#expect`), not XCTest. Prefer editing an existing wiki slug instead of adding a duplicate page. README shape: [standard-readme](https://github.com/RichardLitt/standard-readme) (see `.cursor/rules/standard-readme.mdc`).

## License

[MIT](./LICENSE) © 2026 Nasib Ali Ansari
