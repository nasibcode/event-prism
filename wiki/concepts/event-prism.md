---
title: "Event Prism"
summary: "Vendor-agnostic analytics mapping: features track a canonical event; the app owns JSON catalogs and destination adapters."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - event-prism
  - analytics
  - mapping
read_when:
  - "Starting work in this repository"
  - "Explaining what Event Prism is and is not"
tldr: "Features call track with canonical names; EventPrism maps per destination and fans out; vendor SDKs stay in the app."
confidence: 1.0
concepts:
  - concepts/track
  - concepts/catalog
  - concepts/destination
  - concepts/mapping
  - concepts/composition
sources:
  - sources/readme
claims:
  - text: "EventPrism is a Swift 6 library with no vendor SDK dependencies."
    confidence: 1.0
    source: sources/readme
    section: Package
  - text: "The destination id is the catalog file id field and must match AnalyticsDestination.id."
    confidence: 1.0
    source: sources/readme
    section: One JSON file per destination
---
## Overview

Event Prism sits between feature code and analytics vendors. A feature emits a canonical event name and `AnalyticsValue` properties. The composition root loads one JSON catalog per destination, registers adapters that hold vendor SDKs, and `EventPrism` maps then calls `log` on each eligible destination.

The library target is Foundation-only. Firebase, Braze, and similar types never appear in `Sources/EventPrism/`.

## Key ideas

- **Canonical in, vendor out.** Event names and keys in feature code stay product language. Vendor names live in JSON `text` / `keys` / `values`.
- **One file per destination.** Do not merge vendors into one megafile. Wrap catalogs in `CompositeEventCatalog`.
- **Skip is a nil mapping.** If `catalog.mapping(for:destination:)` returns nil, that dest is skipped (`skip` in debug logs).
- **Fire and forget.** `track`, `register`, and `unregister` return immediately; work hops onto the `EventPrism` actor.

## Related concepts

- [Track](concepts/track)
- [Catalog](concepts/catalog)
- [Destination](concepts/destination)
- [Mapping](concepts/mapping)
- [Composition](concepts/composition)

## Open questions

None from the current package surface. New vendors are app work: a JSON file plus an adapter, not a library change.
