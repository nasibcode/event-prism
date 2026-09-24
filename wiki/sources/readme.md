---
title: "README"
summary: "In-repo README: how EventPrism works, quick start, catalog format, commands, demo, layout."
type: documentation
status: active
last_updated: "2026-09-24"
tags:
  - readme
  - source
read_when:
  - "Tracing a wiki claim back to the package README"
tldr: "Features track canonical events; one JSON file per destination; app owns SDKs and adapters; README covers quick start and commands."
confidence: 1.0
concepts:
  - concepts/event-prism
  - concepts/catalog
  - concepts/composition
  - concepts/mapping
claims:
  - text: "Vendor-agnostic analytics mapping for Swift 6. Features track a canonical event name and properties."
    confidence: 1.0
    section: Intro
  - text: "Do not put every vendor in one megafile. Load one JSON per destination and wrap in CompositeEventCatalog."
    confidence: 1.0
    section: Catalog format
  - text: "Eligibility is events[name] == true and mappings[name] exists. Unmapped keys always pass through."
    confidence: 1.0
    section: Catalog format
  - text: "Features never mention destination ids. Vendor adapters live in the app."
    confidence: 1.0
    section: Wire it in the app
  - text: "No vendor SDK dependencies in this package."
    confidence: 1.0
    section: Requirements
  - text: "track returns immediately; waitUntilIdle waits for in-flight work, not a vendor SDK flush."
    confidence: 1.0
    section: Wire it in the app
---
## Summary

The repository README is the product contract: how mapping works, SPM quick start, per-dest JSON (`events`, `text` / `keys` / `values`), `CompositeEventCatalog`, app-owned adapters, `swift test` / demo commands, and layout. JSON Schema path: `Sources/EventPrism/Catalog.schema.json`. Demo is an iOS Simulator dashboard.

## Key claims

See frontmatter `claims`. Composition snippet in README matches wiring docs.

## Related concepts

- [Event Prism](concepts/event-prism)
- [Catalog](concepts/catalog)
- [Composition](concepts/composition)
