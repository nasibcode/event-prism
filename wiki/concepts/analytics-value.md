---
title: "Analytics value"
summary: "JSON-friendly property enum: string, int, double, bool, null, plus stringified for maps and interpolation."
type: concept
status: active
last_updated: "2026-08-31"
tags:
  - analytics-value
  - properties
read_when:
  - "Choosing property types for track"
  - "Understanding value-map lookup keys"
tldr: "Properties are AnalyticsValue; maps and ${} use stringified forms, not Swift equality of enum cases."
confidence: 1.0
concepts:
  - concepts/mapping
  - concepts/track
---
## Overview

`AnalyticsValue` cases: `string`, `int`, `double`, `bool`, `null`. Catalog JSON values decode into the same enum (bool vs number distinguished via `CFBoolean`).

`stringified` is what value maps match and what interpolation inserts: ints/doubles via `String(value)`, bools `true`/`false`, null `""`.

## Key ideas

- Features pass `[String: AnalyticsValue]`, not `[String: Any]`.
- Nested objects and arrays are not in the type. Unexpected JSON catalog values become `String(describing:)`.

## Related concepts

- [Mapping](concepts/mapping)

## Open questions

None.
