---
title: "README"
summary: "In-repo README: vendor-agnostic track, one JSON per dest, app composition, layout."
type: documentation
status: active
last_updated: "2026-08-31"
tags:
  - readme
  - source
read_when:
  - "Tracing a wiki claim back to the package README"
tldr: "Features track canonical events; one JSON file per destination; app owns SDKs and adapters."
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
    section: One JSON file per destination
  - text: "Eligibility is events[name] == true and mappings[name] exists. Unmapped keys always pass through."
    confidence: 1.0
    section: One JSON file per destination
  - text: "Features never mention destination ids. Vendor adapters live in the app."
    confidence: 1.0
    section: App composition
  - text: "No vendor SDK dependencies in this package."
    confidence: 1.0
    section: Package
---
## Summary

The repository README is the product contract: canonical `track`, per-dest JSON (`events`, `text` / `keys` / `values`), `CompositeEventCatalog`, and app-owned adapters. JSON Schema path: `Sources/EventPrism/Catalog.schema.json`. Demo is an iOS Simulator dashboard.

## Key claims

See frontmatter `claims`. Composition snippet in README matches `docs/wiring`.

## Related concepts

- [Event Prism](concepts/event-prism)
- [Catalog JSON schema](docs/catalog-schema)
