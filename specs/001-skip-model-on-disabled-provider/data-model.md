# Data Model: Skip model when provider is disabled

**Feature**: 001-skip-model-on-disabled-provider

**Date**: 2026-05-14

## Existing Entities (No Changes)

### ProviderConnection

The `ProviderConnection` entity already has the `isActive` field used to determine if a connection is usable.

| Field | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Unique identifier |
| provider | string | Provider ID (e.g., `openai`, `claude`, or node ID) |
| isActive | boolean | Whether this connection is usable (defaults to `true`) |
| priority | number | Fallback order priority |
| authType | string | `oauth` or `apikey` |
| name | string | Display name |
| email | string | Account email (OAuth) |
| providerSpecificData | object | Custom config (baseUrl, prefix, enabledModels, etc.) |

**State Transitions**:
- `isActive: true` (default) → connection participates in routing
- `isActive: false` → connection is excluded from all routing and model listing

### Model (Response Entity)

The `Model` is not a stored entity but a response object in `/v1/models`.

| Field | Type | Description |
|-------|------|-------------|
| id | string | Model ID (e.g., `openai/gpt-4`) |
| object | string | Always `"model"` |
| owned_by | string | Provider alias (derived from connection's `outputAlias`) |
| kind | string | (Optional) Service kind for web search/fetch |

## Relationships

```
ProviderNode (optional)          ProviderConnection
     │                                  │
     │ has many                         │ has many
     ▼                                  ▼
ProviderConnection ────────────► Provider Alias
     │                                  │
     │ determines                       │ determines
     ▼                                  ▼
Model Availability ◄──────────── owned_by field
```

## Filtering Logic

**Rule**: A model with `owned_by: "X"` appears in `/v1/models` response if and only if:
- At least one `ProviderConnection` with `provider` mapping to alias "X" has `isActive: true`

**Pseudocode**:
```javascript
// Get all active connections
const connections = await getProviderConnections();
const activeConnections = connections.filter(c => c.isActive !== false);

// Build provider → connection map
const activeByProvider = new Map();
for (const conn of activeConnections) {
  if (!activeByProvider.has(conn.provider)) {
    activeByProvider.set(conn.provider, conn);
  }
}

// Only include models from providers with active connections
for (const [providerId, conn] of activeByProvider) {
  // Add models for this provider
}
```

## No Schema Changes

This feature requires no database schema changes. It uses the existing `isActive` field on `providerConnections` table.
