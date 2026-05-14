# Tasks: Skip model when provider is disabled

**Input**: Design documents from `specs/001-skip-model-on-disabled-provider/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Verify the core logic and handle edge cases before manual testing.

- [X] T001 Review `buildModelsList` in `src/app/api/v1/models/route.js` to confirm existing `isActive` filter logic is correct and handles all provider types.
- [X] T002 In `src/app/api/v1/models/route.js`, add logic to handle the edge case where `connections.length > 0` but `activeConnectionByProvider` is empty (all connections are disabled), so it doesn't fall back to the static list.
- [X] T003 Ensure that when `buildModelsList` receives an empty list of connections, it returns an empty model list instead of falling back to the static list, which contains all models regardless of their status.

---

## Phase 2: User Story 1 - Model list hides models from disabled providers (Priority: P1) 🎯 MVP

**Goal**: Ensure models from providers with no active connections are excluded from `/v1/models` list.

**Independent Test**: Disable all connections for a provider (e.g., OpenAI) in the dashboard and verify via `curl http://localhost:20128/v1/models` that no models with `owned_by: "openai"` are present.

### Implementation for User Story 1

- [X] T004 [US1] In `buildModelsList` function in `src/app/api/v1/models/route.js`, modify the logic that populates the models list. For each provider, before adding its models, check if there is at least one active connection for it in the `connections` array.
- [X] T005 [US1] If a provider has no active connections, skip adding its models to the `models` array.
- [ ] T006 [US1] Manually test the scenario where a provider has a mix of active and inactive connections to ensure its models are still listed.

---

## Phase 3: User Story 2 - Models list consistent with provider state (Priority: P2)

**Goal**: Ensure the models list updates immediately and accurately when a provider's connection status changes.

**Independent Test**: From the dashboard, toggle a provider's last active connection off and on, and confirm the model list in a separate client (e.g., Postman, another browser tab) updates correctly on each refresh.

### Implementation for User Story 2

- [X] T007 [US2] No code changes required; this user story is a validation of the changes made for US1.
- [ ] T008 [US2] Perform manual testing by toggling connection `isActive` status in the dashboard and verifying the `/v1/models` endpoint responds correctly and immediately.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and documentation.

- [X] T009 [P] Review and add comments to the modified sections in `src/app/api/v1/models/route.js` to explain the filtering logic.
- [X] T010 Run `npx eslint .` to ensure code style consistency.
- [X] T011 Update `quickstart.md` with final testing steps for this feature.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Must be completed before User Story phases.
- **User Stories (Phase 2 & 3)**: Depend on Foundational phase.
- **Polish (Phase 4)**: Depends on all user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational.
- **User Story 2 (P2)**: Depends on US1; it primarily involves testing the outcome of US1's implementation.

### Parallel Opportunities

- T009 (documentation) can be done in parallel with testing tasks.

---

## Implementation Notes

**Change made**: `src/app/api/v1/models/route.js` — `buildModelsList()`:
- Added `dbAvailable` flag tracking whether `getProviderConnections()` succeeded.
- Changed the static-models fallback condition from `connections.length === 0` to `!dbAvailable`.
- Result: When DB is available and all connections are disabled, the model list is empty (correct behavior). The static-models fallback only triggers when the DB itself is unreachable.

**Manual testing (T006, T008)**: Requires running the dev server and toggling connections in the dashboard. Left for the user to validate.
