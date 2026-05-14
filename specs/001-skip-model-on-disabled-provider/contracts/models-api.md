# API Contract: /v1/models

**Feature**: 001-skip-model-on-disabled-provider

**Date**: 2026-05-14

## Endpoint

```
GET /v1/models
GET /v1/models?owned_by={provider_alias}
GET /v1/models?search={keyword}
```

## Response Format (OpenAI-Compatible)

```json
{
  "object": "list",
  "data": [
    {
      "id": "openai/gpt-4",
      "object": "model",
      "owned_by": "openai"
    },
    {
      "id": "openai/o3-pro",
      "object": "model",
      "kind": "webSearch",
      "owned_by": "openai"
    }
  ]
}
```

## Contract: Model Filtering

**Rule**: Models are included in `data[]` if and only if at least one `ProviderConnection` with the corresponding provider has `isActive: true`.

**Pre-conditions for provider inclusion**:
- `providerId` maps to `owned_by` alias (via `getProviderAlias()` or `providerSpecificData.prefix`)
- At least one connection for `providerId` has `isActive !== false`

**Post-conditions**:
- Models from providers with all connections disabled are absent from `data[]`
- Models from providers with at least one active connection are present
- Toggling `isActive` on a connection immediately affects subsequent requests

**Edge cases**:
- `owned_by` filter: Only filters by `owned_by`; if requested `owned_by` provider has no active connections, returns empty `data[]`
- `search` filter: Combines with `isActive` filtering — searches only active models
- All connections disabled: Falls back to static model list (DB-unavailable behavior)
- No connections: Falls back to static model list

## Backward Compatibility

- Response format unchanged
- No new fields added to response
- No existing fields removed
- The only behavioral change: fewer models may appear in the list
