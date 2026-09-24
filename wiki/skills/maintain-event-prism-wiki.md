---
title: "Maintain Event Prism wiki"
name: maintain-event-prism-wiki
description: "Update wiki concepts and docs when EventPrism APIs, catalog schema, or demo wiring change."
type: skill
status: active
last_updated: "2026-08-31"
when_to_use: "After changing Sources/EventPrism, Catalog.schema.json, README, or the demo app."
tags:
  - wiki
  - skill
read_when:
  - "Finishing a change to EventPrism public API or catalog format"
---
## Overview

Keep `wiki/` aligned with the Swift package. Prefer editing the existing slug for a topic; do not spawn duplicate concept pages.

## Workflow

1. Identify which concept or doc the change touches (`track`, `catalog`, `mapping`, `destination`, `composition`, catalog schema, wiring, demo, tests).
2. Update frontmatter `last_updated` and any `claims`.
3. Run `llm-wiki ingest wiki --wiki event-prism` (repo `wiki.toml` has `auto_commit = false`).
4. If search looks stale, `llm-wiki index rebuild --wiki event-prism`.

Do not put harness plans in this repository.
