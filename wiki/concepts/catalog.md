---
title: "Catalog"
summary: "EventCatalog lookup: JSONDestinationCatalog per dest file, CompositeEventCatalog to union them."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - catalog
  - json
  - composite
read_when:
  - "Loading destination JSON"
  - "Deciding why an event did not reach a dest"
  - "Choosing strict vs drop-all parse"
tldr: "A dest receives an event only when events[name] is true and mappings[name] exists; composite returns the first matching catalog."
confidence: 1.0
concepts:
  - concepts/event-prism
  - concepts/mapping
  - concepts/destination
sources:
  - sources/readme
---
## Overview

`EventCatalog` answers `mapping(for:destination:)`. Nil means skip that dest for that canonical name.

`JSONDestinationCatalog` parses one file: `schemaVersion`, `id`, `events`, `mappings`. `id` is the dest identity. `mapping` returns nil unless `destination == id`, `events[eventName] == true`, and `mappings[eventName]` exists.

`CompositeEventCatalog` holds several catalogs and returns the first non-nil mapping. Prism still iterates registered dests; the composite only supplies the mapping for each id.

## Key ideas

- **Eligibility is two gates.** `promo_seen` on firebase has a mapping row but `events` is false → skip.
- **Wrong dest id is nil.** A firebase catalog never answers for `braze`.
- **Invalid JSON.** Default `strict: false` drops the dest (empty id, all mappings nil) and logs once. `strict: true` throws `JSONDestinationCatalogError`.
- **Unreadable file.** Same drop vs throw as invalid JSON.

## Related concepts

- [Mapping](concepts/mapping)
- [Skip eligibility](concepts/skip-eligibility)
- [Catalog JSON schema](docs/catalog-schema)

## Open questions

None.
