---
title: "Destination payload"
summary: "Mapped name and parameters delivered to AnalyticsDestination.log."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - payload
read_when:
  - "Implementing log on an adapter"
  - "Asserting test payloads"
tldr: "DestinationPayload is dest id, vendor event name, and transformed parameters."
confidence: 1.0
concepts:
  - concepts/destination
  - concepts/mapping
---
## Overview

`DestinationPayload` is `Sendable` and `Equatable`: `destination`, `name` (from mapping `text`), `parameters` (after key rename and value map).

Adapters translate this into vendor API calls. Tests compare payloads on `RecordingDestination`.

## Related concepts

- [Destination](concepts/destination)
- [Mapping](concepts/mapping)

## Open questions

None.
