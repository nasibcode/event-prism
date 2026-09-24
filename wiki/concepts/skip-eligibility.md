---
title: "Skip eligibility"
summary: "When a destination does not receive an event: unregistered, events false, missing mapping, dropped catalog, or dest id mismatch."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - skip
  - eligibility
read_when:
  - "An event is missing from a vendor"
  - "Writing events true/false in catalog JSON"
tldr: "Skip is nil mapping or an unregistered dest; debug logs say skip and never include property values."
confidence: 1.0
concepts:
  - concepts/track
  - concepts/catalog
  - concepts/destination
---
## Overview

A dest logs only if it is currently registered **and** `catalog.mapping` is non-nil for that canonical name and dest id.

Nil mapping happens when:

- `events[name]` is missing or not `true`
- `mappings[name]` is missing
- catalog `id` does not match the dest
- catalog was drop-all after invalid JSON/schema (`strict: false`)

Unregistered dests are not in the dictionary, so they are silent (no skip log). Skip logs fire only for registered dests with nil mapping.

## Key ideas

- Demo UI dest chips toggle `register` / `unregister`. Per-event dest checkboxes in the demo are a **UI filter** on top of catalogs; catalog JSON still owns mapping eligibility.
- Logger messages include dest id and event name only — never property values.

## Related concepts

- [Event Prism logging](concepts/logging)
- [Catalog](concepts/catalog)

## Open questions

None.
