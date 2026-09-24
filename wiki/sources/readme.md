---
title: "README"
summary: "In-repo README: standard-readme Background, Install, Usage, Features, map, Docs, Contributing, License."
type: documentation
status: active
last_updated: "2026-09-24"
tags:
  - readme
  - source
read_when:
  - "Tracing a wiki claim back to the package README"
tldr: "Features track canonical events; one JSON file per destination; app owns SDKs and adapters; README follows standard-readme."
confidence: 1.0
concepts:
  - concepts/event-prism
  - concepts/catalog
  - concepts/composition
  - concepts/mapping
claims:
  - text: "Vendor-agnostic analytics mapping for Swift 6. Features track a canonical event name and properties."
    confidence: 1.0
    section: Pitch
  - text: "Do not put every vendor in one megafile. Load one JSON per destination and wrap in CompositeEventCatalog."
    confidence: 1.0
    section: Background
  - text: "Eligibility is events[name] == true and mappings[name] exists. Unmapped keys always pass through."
    confidence: 1.0
    section: Catalog JSON
  - text: "Features never mention destination ids. Vendor adapters live in the app."
    confidence: 1.0
    section: Usage
  - text: "No vendor SDK dependencies in this package."
    confidence: 1.0
    section: Install
  - text: "track returns immediately; waitUntilIdle waits for in-flight work, not a vendor SDK flush."
    confidence: 1.0
    section: Usage
---
## Summary

The repository README follows [standard-readme](https://github.com/RichardLitt/standard-readme): how mapping works, SPM install from GitHub, per-dest JSON, app-owned adapters, commands, demo, and MIT license. JSON Schema path: `Sources/EventPrism/Catalog.schema.json`.

## Key claims

See frontmatter `claims`. Composition snippet in README Usage matches wiring docs.

## Related concepts

- [Event Prism](concepts/event-prism)
- [Catalog](concepts/catalog)
- [Composition](concepts/composition)
