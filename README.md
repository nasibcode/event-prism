# EventPrism

Vendor-agnostic analytics mapping for Swift 6. Feature code calls `track` with a **canonical** event name and properties. The app owns one JSON catalog per analytics destination plus thin adapters that wrap vendor SDKs. EventPrism maps names, keys, and values, then fans out to every eligible registered destination.

This repository is a Swift package plus a concept wiki under `wiki/`. The wiki does not replace the package; it explains the same ideas for humans and agents.

## How it works

```
Feature ──track(name, properties)──► EventPrism actor
                                        │
                                        ├─ skip if dest is unregistered or mapping is nil
                                        └─ transform (text / keys / values) ──► destination.log(payload)
```

1. The composition root loads one catalog file per destination (`JSONDestinationCatalog`) and wraps them in `CompositeEventCatalog`.
2. It constructs `EventPrism(catalog:)` and `register`s adapters. Each adapter’s `id` must match the catalog file `"id"`.
3. Features call `prism.track("screen_viewed", properties: …)` and return immediately. Work hops onto the `EventPrism` actor.
4. For each registered destination (sorted by id), the catalog is asked for a mapping. **Nil mapping means skip** (debug log `skip`). Otherwise `EventTransformer` builds a `DestinationPayload` and the adapter’s `log` runs.

Vendor types (Firebase, Braze, and so on) never appear in `Sources/EventPrism/`. Adapters live in the app and must return quickly from `log`; hop to the main actor if the SDK requires it.

## Requirements

- Swift 6.2 tools, Swift 6 language mode
- Library: iOS 16+, macOS 13+
- Demo app: iOS 17+ Simulator (`@Observable`)
- Xcode for the example project; `swift test` for the package tests
- No vendor SDK dependencies in this package

## Quick start

### Use the package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/nasibcode/event-prism.git", branch: "main"),
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "EventPrism", package: "event-prism"),
    ]),
]
```

Or add a local path while developing next to this clone.

### Wire it in the app

```swift
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

Pass `logger:` on `EventPrism` (and catalog load) if you want skip / `log` diagnostics. Pass `strict: true` on `JSONDestinationCatalog` to fail boot on invalid JSON instead of dropping that destination.

After `register`, tests or UI that `track` immediately should `await prism.waitUntilIdle()` so the destination is stored. That wait is **not** a vendor SDK flush.

Features never mention destination ids. `unregister` only removes the adapter from EventPrism; it does not shut down the SDK.

## Catalog format

Do not put every vendor in one megafile. One JSON object per destination. Schema: `Sources/EventPrism/Catalog.schema.json`.

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
|--------|------|
| `id` | Must match `AnalyticsDestination.id` |
| `events[name] == true` **and** `mappings[name]` | Eligibility; otherwise that dest is skipped |
| `text` | Vendor event name |
| `keys` | Canonical property name → vendor key |
| `values` | Canonical value → vendor value; supports `${other_key}` interpolation and `default` |
| Unmapped keys | Always pass through |

A registered destination with no mapping logs `skip`. An unregistered destination is silent.

## Commands

From the repository root:

| Command | Description |
|---------|-------------|
| `swift test` | Run Swift Testing suites (`EventPrismTests`) |
| `swift build` | Build the library |
| Open `Examples/EventPrismDemoApp/EventPrismDemoApp.xcodeproj` | Run the interactive iOS Simulator dashboard |

## Demo app

The example is a Simulator dashboard, not a vendor integration:

1. Open the Xcode project above, pick an iOS Simulator, Run.
2. Destination chips call `register` / `unregister`. Catalog JSON still owns mappings.
3. Open an event, choose which dests should receive that track (UI filter), add optional extra properties, Track.
4. The log shows canonical input vs per-destination payload or skip.

Known dest ids: `firebase`, `braze`, `print`. The print catalog only allows `debug_only`.

## Repository layout

| Path | What it is |
|------|------------|
| `Sources/EventPrism/` | Engine (Foundation only) |
| `Tests/EventPrismTests/` | Swift Testing + JSON fixtures |
| `Examples/EventPrismDemoApp/` | Simulator UI and live catalog JSON |
| `wiki/` | Concept and reference pages |

Harness plans and reports are machine-local (`~/.cursor/harness/event-prism/`), not in this clone.

## Documentation

Start with [wiki/concepts/event-prism.md](wiki/concepts/event-prism.md). Section indexes: [concepts](wiki/concepts.md), [docs](wiki/docs.md), [sources](wiki/sources.md).

## Contributing

Keep the public surface small: catalogs and adapters in the app, mapping in this package. New tests use Swift Testing (`@Test`, `#expect`), not XCTest. Prefer editing the existing wiki slug for a topic instead of adding a duplicate page.
