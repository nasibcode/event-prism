---
title: "Destination"
summary: "App-owned AnalyticsDestination adapters hold vendor SDKs; DestinationID matches catalog id."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - destination
  - adapter
  - destination-id
read_when:
  - "Writing a vendor adapter"
  - "Registering or unregistering dests"
tldr: "Adapters implement id plus non-blocking log; EventPrism never constructs vendor SDKs."
confidence: 1.0
concepts:
  - concepts/event-prism
  - concepts/track
  - concepts/composition
sources:
  - sources/readme
---
## Overview

`AnalyticsDestination` is a class protocol: `id: DestinationID` and `log(_ payload: DestinationPayload)`. `log` must return quickly. If the vendor requires the main actor, hop off the EventPrism actor inside the adapter.

`DestinationID` is a string newtype (`RawRepresentable`, string literal). The same string is catalog `"id"`, `destination.id`, and `register` / `unregister`.

`unregister` only removes the adapter from EventPrism. It does not tear down the SDK.

## Key ideas

- **Ownership inversion.** The app creates SDKs and adapters; EventPrism stores them by id.
- **Demo `PrintDestination`** is the same protocol as a production adapter: it appends payloads to a collector instead of calling a vendor.
- **`RecordingDestination`** is the test sink: thread-safe append plus `waitUntilCount`.

## Related concepts

- [Composition](concepts/composition)
- [Destination payload](concepts/destination-payload)
- [Recording destination](concepts/recording-destination)

## Open questions

None.
