---
title: "Mapping"
summary: "Per-event DestinationMapping: vendor event name, key rename, value cases plus default, then interpolate."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - mapping
  - transformer
  - interpolation
read_when:
  - "Editing mappings in destination JSON"
  - "Debugging renamed keys or interpolated values"
tldr: "text is the vendor event name; keys rename properties; values remap by stringified original; ${canonical_key} interpolates from the original bag."
confidence: 1.0
concepts:
  - concepts/catalog
  - concepts/analytics-value
  - concepts/track
sources:
  - sources/readme
---
## Overview

`DestinationMapping` is parsed from `mappings[canonicalName]`: `text` (required), `keys` (canonical → vendor), `values` (per canonical property: from-value → to-value, reserved key `default`).

`EventTransformer.apply` walks every property in the incoming bag:

1. Look up `values[canonicalKey]`. Match `original.stringified` against cases; else use `default`; else keep original.
2. If the resolved value is a string, interpolate `${canonical_key}` from the **original** property bag. Missing keys become empty strings. One pass only.
3. Emit under `keys[canonicalKey] ?? canonicalKey`.

Unmapped keys always pass through with the same name. There is no drop-unlisted-keys mode.

## Key ideas

- Value lookup uses `stringified` (`true`/`false` for bool, empty for null).
- Interpolation runs on the template after value-map resolution, including `default` templates.
- Non-string resolved values skip interpolation.

## Related concepts

- [Analytics value](concepts/analytics-value)
- [Skip eligibility](concepts/skip-eligibility)
- [Catalog JSON schema](docs/catalog-schema)

## Open questions

None.
