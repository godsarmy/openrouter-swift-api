# Swift / Zig API parity TODOs

## Goal and review baseline

Both SDKs should implement the same OpenRouter HTTP API and observable wire
contracts, with idiomatic language-specific interfaces. Matching method names,
memory ownership, or async iteration syntax is not required. Endpoint presence
alone does not establish request, response, error, or streaming parity.

Source review on **2026-10-30**:

- Swift: `2532304ac772dc597477e829473787e9d6435732`.
- Zig: `5ae5da52523c28cc8dcd7cf7cf971d9f32a64a70`, reviewed locally at
  `/home/amyma/proj/openrouter-zig-sdk`.
- Zig evidence: `src/client.zig`, endpoint modules in `src/`, and
  `docs/api/coverage.md`. Paths prefixed with `Zig:` below refer to that repository.
- Swift evidence: [client implementation](Sources/OpenRouter/Public/OpenRouterClient.swift)
  and [endpoint coverage](docs/reference/endpoint-coverage.md).

This is a source-level planning review, not live-service authorization testing
or an exhaustive field-by-field audit. Zig is a useful implementation reference,
not the authority for upstream contracts. Keep the endpoint tracker canonical for
implemented status; this plan owns cross-language priorities and acceptance work.
No Zig files were changed by this review.

## P0 — Establish a comparable baseline

- [x] Compare both method/path inventories against the **same saved OpenAPI
  snapshot**, recording its date and digest. Normalize path parameter names and
  expand combined HTTP verbs. Distinguish current-spec, retained/non-spec,
  deprecated, and unimplemented operations rather than comparing headline counts.
  Results and limitations: [shared snapshot baseline](docs/reference/sdk-parity.md).
- [x] Record a repeatable cross-SDK route diff with
  `scripts/compare_api_coverage.py`; snapshot auth and the known server override
  are recorded in the baseline. This is an explicit review tool, not a CI gate
  or a full auth/server-override validator.
- [ ] Resolve known contract disagreements before porting behavior: preset POSTs
  are labeled inference in Zig's coverage but configuration-only in Swift's
  tracker; Zig transcription serializes JSON `input_audio` (`Zig: src/audio.zig`),
  whereas Swift constructs a multipart file upload. Check the current official
  contract, not whichever SDK was implemented first.
- [ ] Track common upstream gaps, not just differences: neither SDK implements
  `GET /vault/interns/{internId}/connections`, listed in Swift's dated spec
  inventory and acknowledged as missing in Zig's coverage. Reconfirm its contract
  and availability in the shared snapshot before scheduling implementation.

## P1 — Close coherent Swift management API gaps

These groups are implemented in Zig and absent from Swift at the review baseline.
BYOK and guardrails are implemented. **Next implementation: observability
destinations**, ahead of expanding pagination convenience APIs.

- [x] **BYOK (5 operations):** list/create at `/byok`; get/update/delete at
  `/byok/{id}`. Reference: `Zig: src/byok.zig`, `ByokResource` in `src/client.zig`.
  Preserve management authentication, workspace/provider filters, explicit-null
  versus omitted update values, and request-only provider secrets.
  Swift follows the October 30 schema, including policy fields absent from the
  reviewed Zig models; Zig still needs a BYOK field-parity follow-up.
- [x] **Guardrails (13 operations):** CRUD, global key/member assignment reads,
  per-guardrail assignment reads, and bulk key/member assignment/removal.
  Reference: `Zig: src/guardrails.zig`, `GuardrailsResource`.
  Swift follows the October 31 schema, with typed filters, nullable PATCH fields,
  and current privacy/region/training policies. See [guardrails](docs/guides/guardrails.md).
- [ ] **Observability destinations (5 operations):** list/create/get/update/delete.
  Reference: `Zig: src/observability.zig`, `ObservabilityDestinationsResource`.

For each group, add Swift resource aliases and models, request/response fixtures,
authentication/query/path tests, omission/null tests where applicable, and error
tests. Keep secrets out of descriptions and logs. Document destructive operations
and ambiguous-mutation retry risks. Update endpoint counts only when implemented.

## P2 — Close remaining Swift endpoint-family gaps

All groups below have Zig implementations; account access and contract stability
must be checked independently before implementation. Split these into bounded
milestones rather than one large port.

- [ ] **Presets:** list/get, version list/get, and the three POST configuration
  routes. Resolve configuration-versus-inference semantics first.
  Reference: `Zig: src/presets.zig`.
- [ ] **External users:** list/create/get/update/delete under `/external-users`.
  Preserve soft-deactivation and HTTP 204 semantics; do not describe deletion as
  revoking inference access. Reference: `Zig: src/end_users.zig`.
- [ ] **Organization settings:** GET/PATCH `/organization/settings`.
  Reference: `Zig: src/organization.zig`.
- [ ] **Data and discovery:** analytics meta/query, benchmarks, task
  classifications, app rankings, session costs, tool catalog list/get, and
  generation feedback. Reference: `Zig: src/analytics.zig`, `src/benchmarks.zig`,
  `src/classifications.zig`, `src/datasets.zig`, `src/tools.zig`,
  `src/generation.zig`. Retain attribution requirements and feedback retry cautions.
- [ ] **Private endpoints:** list/get/create/update/delete, activate, disable,
  enable, validate, and pricing update. Preserve entitlement requirements,
  decimal-string pricing, and partial-failure draft data.
  Reference: `Zig: src/private_endpoints.zig`.
- [ ] **SCIM:** group listing, mapping CRUD/list, and sync-job create/get.
  Preserve explicit membership-retention choices and asynchronous job semantics.
  Reference: `Zig: src/scim.zig`.
- [ ] **Container files:** list/get/content/promote; preserve cursor behavior,
  buffered binary responses, and quota-affecting promotion semantics.
  Reference: `Zig: src/containers.zig`.
- [ ] **Vault:** workspace/intern secret metadata, put/delete, effective metadata,
  and secret copy. Preserve secret boundaries, workspace scope, and HTTP 204.
  Reference: `Zig: src/vault.zig`.
- [ ] **OAuth infrastructure:** public JWKS and token exchange, separate from the
  existing authorization-code exchange. Verify form encoding and suppression of
  client API-key headers. Reference: `Zig: src/oauth.zig`.
- [ ] **System One / alpha Decisions:** preserve the alpha operation's server
  override, rather than blindly using the normal `/api/v1` base.
  Reference: `Zig: src/decisions.zig`.
- [ ] **Retained Zig routes outside Swift's dated spec inventory:** evaluate intern
  lifecycle/chat/daemon/invoke/provision/suspend and the Artificial Analysis and
  Design Arena dataset routes. Decide explicitly whether to support them in both
  SDKs; absence from a newer spec alone does not prove removal.
  Reference: `Zig: src/interns.zig`, `src/datasets.zig`.

## P3 — Align behavior on shared endpoints

- [ ] **Zig follow-up: guardrail policies.** Add the snapshot-backed region, xAI
  ZDR, safety-retention, publication/training, first-party-harness, and BYOK-budget
  fields missing from the reviewed Zig models. Align nullable PATCH clearing,
  required response/count fields, path escaping, and typed builtin scan scopes.
  Zig already accepts create `workspace_id`; do not treat that as an endpoint gap.
- [ ] **Zig follow-up: BYOK policies.** Match Swift's snapshot-backed fields:
  `allowed_api_key_hashes`, `is_required`, `is_byok_only`, `declared_region`, and
  `declared_zdr`, and nullable PATCH name/policy handling. Check required response
  fields as well; endpoint presence in both SDKs does not establish field parity.
- [ ] **Zig follow-up: image SSE.** Swift already supports incremental image
  events, terminal/error validation, and buffered JSON fallback; Zig currently
  forces buffered `stream: false`. Match observable behavior, not Swift types.
- [ ] **Both: Responses field/event parity.** Compare request/input/output fields,
  function tools, function-call/output and reasoning replay, event deltas, unknown
  fields, and completion/error handling. Keep additional beta Responses fields
  explicitly deferred until confirmed; raw payload access is not full typed parity.
- [ ] **Both: chat and embeddings models.** Compare routing/privacy/filter/price
  options, embedding options, tool calls, usage/cache metadata, and stream errors
  with shared JSON fixtures. Current review does not establish field-level parity.
- [ ] **Both: audio/files/batches.** Settle transcription encoding; compare binary
  Content-Type, provider file variants, nullability, batch serialization ordering,
  and deletion outcomes. Raw versus typed payloads may differ if wire behavior agrees.
- [ ] **Zig follow-up: fallback helpers.** Evaluate Swift's opt-in chat fallback
  behavior, especially forbidding fallback after stream output has been emitted.
- [ ] **Legacy policy:** Swift retains `POST /completions`, absent from Zig. Decide
  whether to add it to Zig or document it as an intentional compatibility exception.

## Completion and verification

- [ ] For each milestone, use equivalent offline fixtures in both SDKs to check
  method/path, auth, headers, query/body serialization, response/error decoding,
  and streaming termination where applicable. Do not infer parity from compilation.
- [ ] Run each SDK's relevant tests for implementations changed there. Live tests
  remain opt-in, account/entitlement-dependent, and potentially chargeable.
- [ ] Refresh both inventories at the same baseline and record any intentional
  exceptions. Do not mark parity complete while endpoint or contract gaps remain.

Pagination helpers for other offset-based resources and cursor-based files/batches
remain useful but secondary to API parity. Apple-platform validation remains a
Swift release requirement, independent of cross-language parity.
