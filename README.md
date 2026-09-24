# EventPrism

Vendor-agnostic analytics mapping for Swift 6. Features `track` a canonical event name and properties. The app owns one JSON file per destination plus destination adapters. Core applies `events`, `text` / `keys` / `values`, then fans out.

This repository also contains a concept wiki under `wiki/`. The Swift package sits alongside that wiki; it does not replace it.

## Package

- Library: `EventPrism`
- iOS demo: open `Examples/EventPrismDemoApp/EventPrismDemoApp.xcodeproj`, pick an iOS Simulator, Run; the interactive dashboard registers destinations, attaches them to events, and tracks on one screen
- Platforms: iOS 16+ (library), macOS 13+; the Simulator app target is iOS 17+ (`@Observable`)
- No vendor SDK dependencies (no Firebase, Braze, or Datadog in this package)

## One JSON file per destination

Do not put every vendor in one megafile. Load `Firebase.json`, `Braze.json`, … and wrap them in `CompositeEventCatalog`. The destination id is the file’s `"id"` field; it must match `AnalyticsDestination.id`.

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

JSON Schema: `Sources/EventPrism/Catalog.schema.json`.

Eligibility: `events[name] == true` **and** `mappings[name]` exists. Unmapped keys always pass through.

## App composition

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

Features never mention destination ids. Vendor adapters live in the app: they hold the SDK instance and translate `DestinationPayload` in `log`. `unregister` only removes the adapter from EventPrism.

## Layout

- `Sources/EventPrism/` — engine (Foundation only)
- `Examples/EventPrismDemoApp/` — iOS Simulator app (interactive dashboard: register dests, attach dests to an event, Track event; log shows canonical input and per-destination payload or skip)
- `Tests/EventPrismTests/` — Swift Testing

Harness plans and reports are not in this package. They live on the machine at `~/.cursor/harness/event-prism/` (one markdown file per work item).
