---
title: "Recording destination"
summary: "In-memory test sink with waitUntilCount for async track."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - testing
  - recording-destination
read_when:
  - "Writing EventPrism tests"
  - "Waiting for async log after track"
tldr: "Use RecordingDestination plus waitUntilIdle or waitUntilCount; do not test vendor types."
confidence: 1.0
concepts:
  - concepts/destination
  - concepts/track
  - concepts/wait-until-idle
---
## Overview

`RecordingDestination` is `Sendable`. `log` appends under an unfair lock and resumes waiters when `stored.count` reaches the requested count.

`payloads` is a snapshot of logs so far. After `track`, prefer `await waitUntilCount(n)` because delivery is asynchronous.

## Related concepts

- [Wait until idle](concepts/wait-until-idle)
- [Testing](docs/testing)

## Open questions

None.
