---
title: "Wait until idle"
summary: "waitUntilIdle drains in-flight register, unregister, and track Tasks. Not a vendor SDK flush."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - concurrency
  - wait-until-idle
read_when:
  - "Tests or UI need mapping to have finished"
  - "Confusing idle with vendor flush"
tldr: "Idle means EventPrism actor work for hopped calls is done; vendor queues may still be open."
confidence: 1.0
concepts:
  - concepts/track
---
## Overview

`register`, `unregister`, and `track` each `enter` an `InflightCounter` before hopping, and `leave` when the actor method returns. `waitUntilIdle` suspends until count is zero.

Use it after register before track in tests, and in the demo after toggling dests. Do not treat it as `Analytics.flush()`.

## Related concepts

- [Track](concepts/track)

## Open questions

None.
