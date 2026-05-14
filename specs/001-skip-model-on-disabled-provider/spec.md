# Feature Specification: Skip model when provider is disabled

**Feature Branch**: `[001-skip-model-on-disabled-provider]`

**Created**: 2026-05-14

**Status**: Draft

**Input**: User description: "bỏ qua model khi provider đang owner bị disable"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Model list hides models from disabled providers (Priority: P1)

As a user, when I disable all connections for a provider, I expect the models owned by that provider to be excluded from the list of available models, so I don't see models that have no working connection.

**Why this priority**: Prevents user confusion by showing only usable models.

**Independent Test**: Can be tested by disabling all connections for a provider and verifying the `/v1/models` endpoint no longer shows models with that provider as `owned_by`.

**Acceptance Scenarios**:

1. **Given** a provider has at least one active connection, **When** I list models via `/v1/models`, **Then** models with `owned_by` matching that provider ARE present.
2. **Given** a provider has all connections disabled (`isActive: false`), **When** I list models via `/v1/models`, **Then** models with `owned_by` matching that provider are NOT present.
3. **Given** a provider has some connections active and some disabled, **When** I list models via `/v1/models`, **Then** models with `owned_by` matching that provider ARE present (at least one active connection suffices).

---

### User Story 2 - Models list consistent with provider state (Priority: P2)

As a user, I expect the models list to accurately reflect which providers can actually be used, so there's no disconnect between what I see and what works.

**Why this priority**: Ensures UI consistency and prevents failed requests.

**Independent Test**: Can be tested by toggling a provider connection's active state and immediately checking the models list reflects the change.

**Acceptance Scenarios**:

1. **Given** I disable a provider connection, **When** I refresh the models list, **Then** models from that provider disappear immediately (if it was the only active connection).
2. **Given** I enable a previously disabled provider connection, **When** I refresh the models list, **Then** models from that provider reappear.

---

### Edge Cases

- What happens when ALL connections for a provider are disabled? Models should not appear in the list.
- What happens when the database has no connections configured at all? Currently returns static models from all providers — this is expected fallback behavior.
- What happens with provider nodes (custom compatible providers)? If a node has no active connections, its models should not appear.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `/v1/models` endpoint MUST filter out models whose `owned_by` provider has no active connections.
- **FR-002**: A provider is considered to have "no active connections" when all its connections have `isActive: false`.
- **FR-003**: If a provider has at least one connection with `isActive: true` (or undefined, which defaults to active), its models MUST be included.
- **FR-004**: This filtering applies to all provider types: built-in providers, OpenAI-compatible providers, and Anthropic-compatible providers.

### Key Entities

- **ProviderConnection**: User's configured connection to an AI provider. Has `isActive` boolean (defaults to `true`).
- **Model**: AI model with `id` (e.g., `openai/gpt-4`) and `owned_by` (provider alias).
- **Provider Alias**: The prefix in model IDs and the `owned_by` value (e.g., `openai`, `claude`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When all connections for a provider are disabled, 0 models with that `owned_by` value appear in `/v1/models` response.
- **SC-002**: When at least one connection for a provider is active, all expected models with that `owned_by` value appear in `/v1/models` response.
- **SC-003**: The `/v1/models` response time must not increase by more than 50ms after this change.

## Assumptions

- The `isActive` flag on a `ProviderConnection` is the sole determinant of whether a connection is usable.
- New connections default to `isActive: true`.
- The current behavior (filtering `connections.filter(c => c.isActive !== false)`) is correct but may need verification for edge cases.
