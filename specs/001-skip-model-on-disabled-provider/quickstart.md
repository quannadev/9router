# Quickstart: Skip model when provider is disabled

**Feature**: 001-skip-model-on-disabled-provider

**Date**: 2026-05-14

## Overview

This feature ensures the `/v1/models` endpoint only returns models from providers that have at least one active connection. It improves user experience by preventing users from seeing models they cannot actually use.

## How It Works

1. When a user calls `/v1/models`, the system fetches all provider connections
2. Connections with `isActive: false` are filtered out
3. Only models from providers with remaining (active) connections are included in the response
4. If all connections for a provider are disabled, that provider's models disappear from the list

## Testing

### Manual Test: Disable a Provider

1. Open the 9Router dashboard
2. Navigate to provider settings
3. Disable all connections for a provider (e.g., OpenAI)
4. Call `/v1/models` or refresh the model list in your AI tool
5. Verify models with `owned_by: "openai"` no longer appear

### Manual Test: Re-enable Provider

1. Enable at least one connection for the disabled provider
2. Refresh the model list
3. Verify the provider's models reappear

## Implementation Location

- **Primary file**: `src/app/api/v1/models/route.js`
- **Key function**: `buildModelsList(kindFilter)`
- **Key line**: Line 129 — `connections.filter(c => c.isActive !== false)`

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| All connections disabled | Falls back to static model list (existing behavior) |
| No connections configured | Shows static model list from all providers |
| Some providers disabled, some active | Only active providers' models shown |
| Mixed connections (some active, some disabled) per provider | Provider's models shown (at least one active) |

## Rollback

If issues arise, the filtering is controlled by a single line. Setting `isActive: true` on all connections restores all models immediately.
