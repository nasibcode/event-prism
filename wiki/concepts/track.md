---
title: "Track"
summary: "Canonical track API: name plus properties, returns immediately, delivers on the EventPrism actor."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - track
  - fan-out
read_when:
  - "Calling or changing EventPrism.track"
  - "Reasoning about delivery order or skip"
tldr: "track hops onto the actor, walks registered dests in id order, skips when mapping is nil, otherwise transforms and log."
confidence: 1.0
concepts:
  - concepts/event-prism
  - concepts/catalog
  - concepts/destination
  - concepts/mapping
sources:
  - sources/readme
---
## Overview

`EventPrism.track(_:properties:)` is `nonisolated`. It increments an in-flight counter, starts a `Task` that calls `deliver` on the actor, then returns. Features must not wait for vendor SDKs.

## Key ideas

- Delivery iterates `destinations.keys` sorted by `rawValue`.
- For each dest, `catalog.mapping(for:destination:)` must be non-nil. Nil logs `skip` and continues.
- `EventTransformer.apply` builds a `DestinationPayload`; then `destination.log(payload)`.
- `waitUntilIdle()` waits until in-flight register / unregister / track Tasks finish. It is not a vendor flush.

## Related concepts

- [Catalog](concepts/catalog)
- [Mapping](concepts/mapping)
- [Wait until idle](concepts/wait-until-idle)

## Open questions

None.
