# Implementation Plan: Skip model when provider is disabled

**Branch**: `001-skip-model-on-disabled-provider` | **Date**: 2026-05-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-skip-model-on-disabled-provider/spec.md`

## Summary

Ensure the `/v1/models` endpoint filters out models from providers that have no active connections. The current code in `src/app/api/v1/models/route.js` already implements this filtering at line 129 (`connections.filter(c => c.isActive !== false)`), but there are edge cases to address: when ALL connections are disabled, the system falls back to static models without provider-level filtering.

## Technical Context

**Language/Version**: JavaScript (Node.js 18+, ESM)

**Primary Dependencies**: Next.js 16 (App Router), SQLite (sql.js / better-sqlite3)

**Storage**: SQLite via `src/lib/db/` (connectionsRepo, nodesRepo, etc.)

**Testing**: Manual smoke testing (no automated test suite)

**Target Platform**: Node.js server (local or Docker deployment)

**Project Type**: Web service (AI proxy/router)

**Performance Goals**: < 50ms added response time for `/v1/models` endpoint

**Constraints**: Must be backward compatible; must not break existing provider fallback chain

**Scale/Scope**: Single user, local deployment

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Reliability-First | ✅ PASS | Feature improves reliability — prevents user from selecting models that would fail |
| II. Token Efficiency | ✅ PASS | No impact on token savings |
| III. Universal Compatibility | ✅ PASS | Standard OpenAI-compatible `/v1/models` response; no breaking changes |
| IV. Transparent Operations | ✅ PASS | Models list accurately reflects available providers |
| V. Secure by Design | ✅ PASS | No credential handling changes |

All gates pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-skip-model-on-disabled-provider/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/api/v1/models/
│   └── route.js           # Primary file to modify — buildModelsList()
├── lib/db/repos/
│   └── connectionsRepo.js # getProviderConnections with isActive filter
└── sse/handlers/
    └── chat.js            # May need to verify routing consistency
```

**Structure Decision**: Single-file change in existing `models/route.js`. No new files needed.

## Complexity Tracking

> No violations to justify.
