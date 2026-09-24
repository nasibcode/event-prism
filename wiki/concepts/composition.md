---
title: "Composition"
summary: "App composition root loads catalogs, constructs EventPrism, and registers adapters that own SDKs."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - composition
  - wiring
  - app
read_when:
  - "Integrating EventPrism into an app"
  - "Deciding where JSON files and adapters live"
tldr: "Library is mapping plus fan-out; the app owns files, CompositeEventCatalog, adapters, and register calls."
confidence: 1.0
concepts:
  - concepts/event-prism
  - concepts/catalog
  - concepts/destination
sources:
  - sources/readme
---
## Overview

Typical boot:

1. Load `JSONDestinationCatalog(url:)` per dest file.
2. `CompositeEventCatalog(firebase, braze, …)`.
3. `EventPrism(catalog:)`.
4. Construct adapters with live SDKs; `prism.register(adapter)`.
5. Features call `track` only. They never mention dest ids.

Platforms: library iOS 16+ / macOS 13+; Swift 6 language mode. Demo Simulator target is iOS 17+ because of `@Observable`.

## Key ideas

- Feature modules import EventPrism for `track` and `AnalyticsValue` only.
- Catalog JSON is app (or demo) resources, not compiled into the library except as `Catalog.schema.json` for validation docs.
- Harness plans live in `~/.cursor/harness/event-prism/`, not in this package.

## Related concepts

- [App wiring](docs/wiring)
- [Demo app](docs/demo-app)

## Open questions

None.
