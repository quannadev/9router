# Research: Skip model when provider is disabled

**Feature**: 001-skip-model-on-disabled-provider

**Date**: 2026-05-14

## Research Items

### 1. Current state of `isActive` filtering in models endpoint

**Decision**: The core filtering is already implemented at `src/app/api/v1/models/route.js:129`.

```javascript
connections = connections.filter(c => c.isActive !== false);
```

**Rationale**: This filter removes disabled connections before building the model list. The `activeConnectionByProvider` map (line 163-168) only includes providers with at least one active connection. Models are built only from providers in this map (line 222).

**Alternatives considered**: None — the existing pattern is correct.

### 2. Edge case: All connections disabled

**Decision**: When ALL connections in the system are disabled, `connections.length === 0` triggers the static fallback path (line 186-203), which shows ALL static models from `PROVIDER_MODELS` without any provider-level filtering.

This is an edge case but should be evaluated: if the user intentionally disabled ALL connections, showing all static models is misleading.

**Rationale**: This is the existing fallback for DB-unavailable scenarios. The behavior is debatable but arguably safer than returning an empty models list (which would break client tools).

**Alternatives considered**:
- Return empty list when all connections disabled: too aggressive, breaks tools
- Keep current fallback: matches spec's "expected fallback behavior" assumption

### 3. Provider alias mapping between connections and models

**Decision**: The `owned_by` field in the models response is derived from the provider alias (not the raw provider ID). The mapping chain is:

1. `conn.provider` (provider ID, e.g., `openai`)
2. `PROVIDER_ID_TO_ALIAS[providerId]` → static alias
3. `conn.providerSpecificData.prefix` → user-defined prefix (customizable)
4. `outputAlias` → final value used as `owned_by`

**Rationale**: Must use `outputAlias` consistently when checking if a provider has active connections vs building model entries. The current code does this correctly.

### 4. Compatibility with provider nodes

**Decision**: Provider nodes (custom OpenAI-compatible / Anthropic-compatible providers) are handled via connections. A node defines the endpoint, connections provide auth. When a node has no active connections, its models should not appear.

The current code handles this because:
- Connections to nodes have the node's provider ID
- `activeConnectionByProvider` groups by provider ID
- No active connection → provider absent from map → models skipped

### 5. Performance impact

**Decision**: No additional database queries needed. The current implementation already fetches all connections once and filters in-memory. Any change should maintain single-query performance.

## Resolved Clarifications

None — no NEEDS CLARIFICATION markers in spec.

## Summary

The feature is largely already implemented. The plan should focus on:
1. Code review to confirm correctness
2. Fix any identified edge cases
3. Manual smoke testing to verify behavior
