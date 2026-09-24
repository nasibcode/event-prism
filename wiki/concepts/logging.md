---
title: "Logging"
summary: "EventPrismLogging is a Sendable handler; default is no-op; never logs property values."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - logging
  - privacy
read_when:
  - "Wiring debug logs"
  - "Checking skip vs log lines"
tldr: "Inject EventPrismLogging at init; messages are dest, event name, and skip or log vendorName."
confidence: 1.0
concepts:
  - concepts/track
  - concepts/skip-eligibility
---
## Overview

`EventPrismLogging.Handler` is `(DestinationID?, String?, String) -> Void`. Default discards. Catalog parse failures log a one-line drop message without dest context.

Delivery logs `skip` or `log \(payload.name)` per dest. Property bags are excluded on purpose.

## Related concepts

- [Skip eligibility](concepts/skip-eligibility)

## Open questions

None.
