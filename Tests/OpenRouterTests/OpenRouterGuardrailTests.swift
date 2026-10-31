import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
final class OpenRouterGuardrailTests: XCTestCase {

  private func json(_ text: String) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: Data(text.utf8)) as! [String: Any]
  }
  func testAllOperationsAndAliases() async throws {
    for alias in [false, true] {
      for filtered in [false, true] {
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET", "X-Path": "/api/v1/guardrails",
            "X-Query": filtered ? #"{"offset":"2","limit":"3","workspace_id":"workspace"}"# : "{}",
            "X-Body": #"{}"#,
            "X-Response":
              #"{"data":[{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}],"total_count":1}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.list(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil,
              workspaceID: filtered ? "workspace" : nil, options: options)
            : client().listGuardrails(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil,
              workspaceID: filtered ? "workspace" : nil, options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              ListGuardrailsResponse.self,
              from: Data(
                #"{"data":[{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}],"total_count":1}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "POST", "X-Path": "/api/v1/guardrails", "X-Query": filtered ? #"{}"# : "{}",
            "X-Body": #"{"name":"future-value"}"#,
            "X-Response":
              #"{"data":{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"A guardrail for limiting API usage","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":50,"name":"My New Guardrail","reset_interval":"monthly","updated_at":null,"workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}}"#,
            "X-Success": "201",
          ])
          let a =
            try await alias
            ? client().guardrails.create(
              CreateGuardrailRequest(name: "future-value"), options: options)
            : client().createGuardrail(
              CreateGuardrailRequest(name: "future-value"), options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              CreateGuardrailResponse.self,
              from: Data(
                #"{"data":{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"A guardrail for limiting API usage","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":50,"name":"My New Guardrail","reset_interval":"monthly","updated_at":null,"workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "DELETE", "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{}"#,
            "X-Response": #"{"deleted":true}"#, "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.delete(id: "a/b?#%雪", options: options)
            : client().deleteGuardrail(id: "a/b?#%雪", options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              DeleteGuardrailResponse.self, from: Data(#"{"deleted":true}"#.utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET", "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.get(id: "a/b?#%雪", options: options)
            : client().getGuardrail(id: "a/b?#%雪", options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              GetGuardrailResponse.self,
              from: Data(
                #"{"data":{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "PATCH", "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":{"allowed_models":null,"allowed_providers":["openai"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Updated description","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":true,"enforce_zdr_openai":true,"enforce_zdr_other":true,"enforce_zdr_xai":true,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":true,"limit_usd":75,"name":"Updated Guardrail Name","reset_interval":"weekly","updated_at":"2025-08-24T16:00:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.update(id: "a/b?#%雪", UpdateGuardrailRequest(), options: options)
            : client().updateGuardrail(id: "a/b?#%雪", UpdateGuardrailRequest(), options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              UpdateGuardrailResponse.self,
              from: Data(
                #"{"data":{"allowed_models":null,"allowed_providers":["openai"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Updated description","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":true,"enforce_zdr_openai":true,"enforce_zdr_other":true,"enforce_zdr_xai":true,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":true,"limit_usd":75,"name":"Updated Guardrail Name","reset_interval":"weekly","updated_at":"2025-08-24T16:00:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET",
            "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA/assignments/keys",
            "X-Query": filtered ? #"{"offset":"2","limit":"3"}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","key_hash":"c56454edb818d6b14bc0d61c46025f1450b0f4012d12304ab40aacb519fcbc93","key_label":"prod-key","key_name":"Production Key"}],"total_count":1}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.listKeyAssignments(
              id: "a/b?#%雪", offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options
            )
            : client().listGuardrailKeyAssignments(
              id: "a/b?#%雪", offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options
            )
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              ListKeyAssignmentsResponse.self,
              from: Data(
                #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","key_hash":"c56454edb818d6b14bc0d61c46025f1450b0f4012d12304ab40aacb519fcbc93","key_label":"prod-key","key_name":"Production Key"}],"total_count":1}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "POST",
            "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA/assignments/keys",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{"key_hashes":["future-value"]}"#,
            "X-Response": #"{"assigned_count":3}"#, "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.bulkAssignKeysToGuardrail(
              id: "a/b?#%雪", BulkAssignKeysRequest(keyHashes: ["future-value"]), options: options)
            : client().bulkAssignKeysToGuardrail(
              id: "a/b?#%雪", BulkAssignKeysRequest(keyHashes: ["future-value"]), options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              BulkAssignKeysResponse.self, from: Data(#"{"assigned_count":3}"#.utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "POST",
            "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA/assignments/keys/remove",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{"key_hashes":["future-value"]}"#,
            "X-Response": #"{"unassigned_count":3}"#, "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.bulkUnassignKeysFromGuardrail(
              id: "a/b?#%雪", BulkUnassignKeysRequest(keyHashes: ["future-value"]), options: options)
            : client().bulkUnassignKeysFromGuardrail(
              id: "a/b?#%雪", BulkUnassignKeysRequest(keyHashes: ["future-value"]), options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              BulkUnassignKeysResponse.self, from: Data(#"{"unassigned_count":3}"#.utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET",
            "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA/assignments/members",
            "X-Query": filtered ? #"{"offset":"2","limit":"3"}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","organization_id":"org_xyz789","user_id":"user_abc123"}],"total_count":1}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.listMemberAssignments(
              id: "a/b?#%雪", offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options
            )
            : client().listGuardrailMemberAssignments(
              id: "a/b?#%雪", offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options
            )
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              ListMemberAssignmentsResponse.self,
              from: Data(
                #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","organization_id":"org_xyz789","user_id":"user_abc123"}],"total_count":1}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "POST",
            "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA/assignments/members",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{"member_user_ids":["future-value"]}"#,
            "X-Response": #"{"assigned_count":2}"#, "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.bulkAssignMembersToGuardrail(
              id: "a/b?#%雪", BulkAssignMembersRequest(memberUserIDs: ["future-value"]),
              options: options)
            : client().bulkAssignMembersToGuardrail(
              id: "a/b?#%雪", BulkAssignMembersRequest(memberUserIDs: ["future-value"]),
              options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              BulkAssignMembersResponse.self, from: Data(#"{"assigned_count":2}"#.utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "POST",
            "X-Path": "/api/v1/guardrails/a%2Fb%3F%23%25%E9%9B%AA/assignments/members/remove",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{"member_user_ids":["future-value"]}"#,
            "X-Response": #"{"unassigned_count":2}"#, "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.bulkUnassignMembersFromGuardrail(
              id: "a/b?#%雪", BulkUnassignMembersRequest(memberUserIDs: ["future-value"]),
              options: options)
            : client().bulkUnassignMembersFromGuardrail(
              id: "a/b?#%雪", BulkUnassignMembersRequest(memberUserIDs: ["future-value"]),
              options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              BulkUnassignMembersResponse.self, from: Data(#"{"unassigned_count":2}"#.utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET", "X-Path": "/api/v1/guardrails/assignments/keys",
            "X-Query": filtered ? #"{"offset":"2","limit":"3"}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","key_hash":"c56454edb818d6b14bc0d61c46025f1450b0f4012d12304ab40aacb519fcbc93","key_label":"prod-key","key_name":"Production Key"}],"total_count":1}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.listKeyAssignments(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options)
            : client().listKeyAssignments(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              ListKeyAssignmentsResponse.self,
              from: Data(
                #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","key_hash":"c56454edb818d6b14bc0d61c46025f1450b0f4012d12304ab40aacb519fcbc93","key_label":"prod-key","key_name":"Production Key"}],"total_count":1}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET", "X-Path": "/api/v1/guardrails/assignments/members",
            "X-Query": filtered ? #"{"offset":"2","limit":"3"}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","organization_id":"org_xyz789","user_id":"user_abc123"}],"total_count":1}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().guardrails.listMemberAssignments(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options)
            : client().listMemberAssignments(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil, options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              ListMemberAssignmentsResponse.self,
              from: Data(
                #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","organization_id":"org_xyz789","user_id":"user_abc123"}],"total_count":1}"#
                  .utf8)))
        }
      }
    }
  }
  func testEveryPatchPropertyOmitNullValueAndCreateCoverage() throws {
    var update = UpdateGuardrailRequest()
    XCTAssertTrue(try object(update).isEmpty)
    update.allowSafetyRetentionGoogle = .null
    update.allowSafetyRetentionOther = .null
    update.allowedDataRegions = .null
    update.allowedModels = .null
    update.allowedProviders = .null
    update.contentFilterBuiltins = .null
    update.contentFilters = .null
    update.description = .null
    update.enableFreeModelPublication = .null
    update.enableFreeModelTraining = .null
    update.enablePaidModelTraining = .null
    update.enforceFirstPartyHarnessModels = .null
    update.enforceZDR = .null
    update.enforceZDRAnthropic = .null
    update.enforceZDRGoogle = .null
    update.enforceZDROpenAI = .null
    update.enforceZDROther = .null
    update.enforceZDRXAI = .null
    update.ignoredModels = .null
    update.ignoredProviders = .null
    update.limitUSD = .null
    update.resetInterval = .null
    let cleared = try object(update)
    XCTAssertEqual(
      Set(cleared.keys),
      Set([
        "allow_safety_retention_google", "allow_safety_retention_other", "allowed_data_regions",
        "allowed_models", "allowed_providers", "content_filter_builtins", "content_filters",
        "description", "enable_free_model_publication", "enable_free_model_training",
        "enable_paid_model_training", "enforce_first_party_harness_models", "enforce_zdr",
        "enforce_zdr_anthropic", "enforce_zdr_google", "enforce_zdr_openai", "enforce_zdr_other",
        "enforce_zdr_xai", "ignored_models", "ignored_providers", "limit_usd", "reset_interval",
      ]))
    XCTAssertTrue(cleared.values.allSatisfy { $0 is NSNull })
    update.allowSafetyRetentionGoogle = .value(false)
    update.allowSafetyRetentionOther = .value(false)
    update.allowedDataRegions = .value(["future-value"])
    update.allowedModels = .value(["future-value"])
    update.allowedProviders = .value(["future-value"])
    update.contentFilterBuiltins = .value([
      .init(action: "block", scanScope: "user_only", slug: "regex-prompt-injection")
    ])
    update.contentFilters = .value([.init(action: "flag", pattern: "secret")])
    update.description = .value("future-value")
    update.enableFreeModelPublication = .value(false)
    update.enableFreeModelTraining = .value(false)
    update.enablePaidModelTraining = .value(false)
    update.enforceFirstPartyHarnessModels = .value(false)
    update.enforceZDR = .value(false)
    update.enforceZDRAnthropic = .value(false)
    update.enforceZDRGoogle = .value(false)
    update.enforceZDROpenAI = .value(false)
    update.enforceZDROther = .value(false)
    update.enforceZDRXAI = .value(false)
    update.ignoredModels = .value(["future-value"])
    update.ignoredProviders = .value(["future-value"])
    update.includeBYOKInBudgets = false
    update.limitUSD = .value(0.5)
    update.name = "future-value"
    update.resetInterval = .value("future-value")
    let updated = try object(update)
    XCTAssertEqual(
      Set(updated.keys),
      Set([
        "allow_safety_retention_google", "allow_safety_retention_other", "allowed_data_regions",
        "allowed_models", "allowed_providers", "content_filter_builtins", "content_filters",
        "description", "enable_free_model_publication", "enable_free_model_training",
        "enable_paid_model_training", "enforce_first_party_harness_models", "enforce_zdr",
        "enforce_zdr_anthropic", "enforce_zdr_google", "enforce_zdr_openai", "enforce_zdr_other",
        "enforce_zdr_xai", "ignored_models", "ignored_providers", "include_byok_in_budgets",
        "limit_usd", "name", "reset_interval",
      ]))
    XCTAssertEqual(updated["allow_safety_retention_google"] as? Bool, false)
    XCTAssertEqual(updated["allow_safety_retention_other"] as? Bool, false)
    XCTAssertEqual(updated["allowed_data_regions"] as? [String], ["future-value"])
    XCTAssertEqual(updated["allowed_models"] as? [String], ["future-value"])
    XCTAssertEqual(updated["allowed_providers"] as? [String], ["future-value"])
    XCTAssertNotNil(updated["content_filter_builtins"])
    XCTAssertNotNil(updated["content_filters"])
    XCTAssertEqual(updated["description"] as? String, "future-value")
    XCTAssertEqual(updated["enable_free_model_publication"] as? Bool, false)
    XCTAssertEqual(updated["enable_free_model_training"] as? Bool, false)
    XCTAssertEqual(updated["enable_paid_model_training"] as? Bool, false)
    XCTAssertEqual(updated["enforce_first_party_harness_models"] as? Bool, false)
    XCTAssertEqual(updated["enforce_zdr"] as? Bool, false)
    XCTAssertEqual(updated["enforce_zdr_anthropic"] as? Bool, false)
    XCTAssertEqual(updated["enforce_zdr_google"] as? Bool, false)
    XCTAssertEqual(updated["enforce_zdr_openai"] as? Bool, false)
    XCTAssertEqual(updated["enforce_zdr_other"] as? Bool, false)
    XCTAssertEqual(updated["enforce_zdr_xai"] as? Bool, false)
    XCTAssertEqual(updated["ignored_models"] as? [String], ["future-value"])
    XCTAssertEqual(updated["ignored_providers"] as? [String], ["future-value"])
    XCTAssertEqual(updated["include_byok_in_budgets"] as? Bool, false)
    XCTAssertEqual(updated["limit_usd"] as? Double, 0.5)
    XCTAssertEqual(updated["name"] as? String, "future-value")
    XCTAssertEqual(updated["reset_interval"] as? String, "future-value")
    XCTAssertEqual(
      try object(CreateGuardrailRequest(name: "name")) as NSDictionary,
      ["name": "name"] as NSDictionary)
    let create = CreateGuardrailRequest(
      allowSafetyRetentionGoogle: false, allowSafetyRetentionOther: false,
      allowedDataRegions: ["future-value"], allowedModels: ["future-value"],
      allowedProviders: ["future-value"],
      contentFilterBuiltins: [
        .init(action: "block", scanScope: "user_only", slug: "regex-prompt-injection")
      ], contentFilters: [.init(action: "flag", pattern: "secret")], description: "future-value",
      enableFreeModelPublication: false, enableFreeModelTraining: false,
      enablePaidModelTraining: false, enforceFirstPartyHarnessModels: false, enforceZDR: false,
      enforceZDRAnthropic: false, enforceZDRGoogle: false, enforceZDROpenAI: false,
      enforceZDROther: false, enforceZDRXAI: false, ignoredModels: ["future-value"],
      ignoredProviders: ["future-value"], includeBYOKInBudgets: false, limitUSD: 0.5,
      name: "future-value", resetInterval: "future-value", workspaceID: "future-value")
    var expected = updated
    expected["workspace_id"] = "future-value"
    XCTAssertEqual(try object(create) as NSDictionary, expected as NSDictionary)
  }
  func testResponseSchemasAndRequiredNullRoundTrips() throws {
    do {
      let fixture =
        #"{"allowed_data_regions":null,"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":null}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(Guardrail.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(Guardrail.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertTrue(encoded["workspace_id"] is NSNull)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["id", "name", "include_byok_in_budgets", "created_at", "workspace_id"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            Guardrail.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture =
        #"{"assigned_by":null,"created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","key_hash":"c56454edb818d6b14bc0d61c46025f1450b0f4012d12304ab40aacb519fcbc93","key_label":"prod-key","key_name":"Production Key"}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(KeyAssignment.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(KeyAssignment.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertTrue(encoded["assigned_by"] is NSNull)
      XCTAssertFalse(encoded.isEmpty)
      for field in [
        "id", "key_hash", "guardrail_id", "key_name", "key_label", "assigned_by", "created_at",
      ] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            KeyAssignment.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture =
        #"{"assigned_by":null,"created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","organization_id":"org_xyz789","user_id":"user_abc123"}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(MemberAssignment.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(MemberAssignment.self, from: JSONEncoder().encode(decoded)),
        decoded)
      let encoded = try object(decoded)
      XCTAssertTrue(encoded["assigned_by"] is NSNull)
      XCTAssertFalse(encoded.isEmpty)
      for field in [
        "id", "user_id", "organization_id", "guardrail_id", "assigned_by", "created_at",
      ] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            MemberAssignment.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture =
        #"{"data":[{"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"action":"redact","label":"[EMAIL]","slug":"email"}],"content_filters":null,"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11"}],"total_count":1}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(ListGuardrailsResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(ListGuardrailsResponse.self, from: JSONEncoder().encode(decoded)),
        decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["data", "total_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            ListGuardrailsResponse.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture =
        #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","key_hash":"c56454edb818d6b14bc0d61c46025f1450b0f4012d12304ab40aacb519fcbc93","key_label":"prod-key","key_name":"Production Key"}],"total_count":1}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(ListKeyAssignmentsResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(
          ListKeyAssignmentsResponse.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["data", "total_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            ListKeyAssignmentsResponse.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture =
        #"{"data":[{"assigned_by":"user_abc123","created_at":"2025-08-24T10:30:00Z","guardrail_id":"550e8400-e29b-41d4-a716-446655440001","id":"550e8400-e29b-41d4-a716-446655440000","organization_id":"org_xyz789","user_id":"user_abc123"}],"total_count":1}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(ListMemberAssignmentsResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(
          ListMemberAssignmentsResponse.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["data", "total_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            ListMemberAssignmentsResponse.self,
            from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture = #"{"assigned_count":3}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(BulkAssignKeysResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(BulkAssignKeysResponse.self, from: JSONEncoder().encode(decoded)),
        decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["assigned_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            BulkAssignKeysResponse.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture = #"{"assigned_count":2}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(BulkAssignMembersResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(
          BulkAssignMembersResponse.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["assigned_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            BulkAssignMembersResponse.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture = #"{"unassigned_count":3}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(BulkUnassignKeysResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(
          BulkUnassignKeysResponse.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["unassigned_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            BulkUnassignKeysResponse.self, from: JSONSerialization.data(withJSONObject: missing)))
      }
    }
    do {
      let fixture = #"{"unassigned_count":2}"#
      let data = Data(fixture.utf8)
      let decoded = try JSONDecoder().decode(BulkUnassignMembersResponse.self, from: data)
      XCTAssertEqual(
        try JSONDecoder().decode(
          BulkUnassignMembersResponse.self, from: JSONEncoder().encode(decoded)), decoded)
      let encoded = try object(decoded)
      XCTAssertFalse(encoded.isEmpty)
      for field in ["unassigned_count"] {
        var missing = try json(fixture)
        missing.removeValue(forKey: field)
        XCTAssertThrowsError(
          try JSONDecoder().decode(
            BulkUnassignMembersResponse.self, from: JSONSerialization.data(withJSONObject: missing))
        )
      }
    }
    for invalid in ["{}", #"{"deleted":false}"#, #"{"deleted":"true"}"#] {
      XCTAssertThrowsError(
        try JSONDecoder().decode(DeleteGuardrailResponse.self, from: Data(invalid.utf8)))
    }
  }
  func testFiltersAndOptionalResponseFields() throws {
    let input = ContentFilterBuiltinEntryInput(
      action: "flag", label: "ignored", scanScope: "user_only", slug: "regex-prompt-injection")
    XCTAssertEqual(try object(input)["scan_scope"] as? String, "user_only")
    let custom = ContentFilterEntry(action: "redact", label: "[SECRET]", pattern: "secret")
    XCTAssertNil(try object(custom)["scan_scope"])
    let guardrail = try JSONDecoder().decode(
      Guardrail.self,
      from: Data(
        #"{"allowed_data_regions":["future-region"],"allowed_models":null,"allowed_providers":["openai","anthropic","google"],"content_filter_builtins":[{"slug":"future-detector","action":"future-action","scan_scope":"future-scope","label":"[SYSTEM]"}],"content_filters":[{"pattern":"secret","action":"flag","label":null}],"created_at":"2025-08-24T10:30:00Z","description":"Guardrail for production environment","enable_free_model_publication":false,"enable_free_model_training":true,"enable_paid_model_training":true,"enforce_zdr":null,"enforce_zdr_anthropic":true,"enforce_zdr_google":false,"enforce_zdr_openai":true,"enforce_zdr_other":false,"enforce_zdr_xai":false,"id":"550e8400-e29b-41d4-a716-446655440000","ignored_models":null,"ignored_providers":null,"include_byok_in_budgets":false,"limit_usd":100,"name":"Production Guardrail","reset_interval":"monthly","updated_at":"2025-08-24T15:45:00Z","workspace_id":"0df9e665-d932-5740-b2c7-b52af166bc11","allow_safety_retention_google":false,"allow_safety_retention_other":false,"enforce_first_party_harness_models":false}"#
          .utf8))
    XCTAssertEqual(guardrail.contentFilterBuiltins?.first?.scanScope, "future-scope")
    XCTAssertEqual(guardrail.contentFilterBuiltins?.first?.label, "[SYSTEM]")
    XCTAssertEqual(guardrail.allowedDataRegions, ["future-region"])
    XCTAssertEqual(guardrail.allowSafetyRetentionGoogle, false)
    XCTAssertEqual(guardrail.enforceFirstPartyHarnessModels, false)
    XCTAssertEqual(guardrail.contentFilters?.first?.pattern, "secret")
    let minimal = try JSONDecoder().decode(
      Guardrail.self,
      from: Data(
        #"{"id":"id","name":"name","created_at":"now","include_byok_in_budgets":false,"workspace_id":null}"#
          .utf8))
    XCTAssertNil(minimal.updatedAt)
    XCTAssertNil(minimal.allowedModels)
  }
  func testServerValidationPassThrough() async throws {
    func options(
      method: String, path: String, body: [String: Any] = [:], query: [String: String] = [:]
    ) throws -> RequestOptions {
      RequestOptions(extraHeaders: [
        "X-Status": "400", "X-Method": method, "X-Path": "/api/v1/guardrails" + path,
        "X-Body": String(decoding: try JSONSerialization.data(withJSONObject: body), as: UTF8.self),
        "X-Query": String(
          decoding: try JSONSerialization.data(withJSONObject: query), as: UTF8.self),
      ])
    }
    func expectBadRequest(_ operation: () async throws -> Void) async {
      do {
        try await operation()
        XCTFail("Expected server validation error")
      } catch let error as OpenRouterError {
        guard case .apiError(let status, _, _, _) = error else {
          return XCTFail("Expected server API error, got \(error)")
        }
        XCTAssertEqual(status, 400)
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
    }
    await expectBadRequest {
      _ = try await self.client().guardrails.create(
        CreateGuardrailRequest(limitUSD: 1, name: "name"),
        options: options(method: "POST", path: "", body: ["name": "name", "limit_usd": 1]))
    }
    for identifiers in [[], Array(repeating: "id", count: 501), [""]] {
      await expectBadRequest {
        _ = try await self.client().guardrails.bulkAssignKeysToGuardrail(
          id: "id", BulkAssignKeysRequest(keyHashes: identifiers),
          options: options(
            method: "POST", path: "/id/assignments/keys", body: ["key_hashes": identifiers]))
      }
      await expectBadRequest {
        _ = try await self.client().guardrails.bulkUnassignKeysFromGuardrail(
          id: "id", BulkUnassignKeysRequest(keyHashes: identifiers),
          options: options(
            method: "POST", path: "/id/assignments/keys/remove", body: ["key_hashes": identifiers]))
      }
      await expectBadRequest {
        _ = try await self.client().guardrails.bulkAssignMembersToGuardrail(
          id: "id", BulkAssignMembersRequest(memberUserIDs: identifiers),
          options: options(
            method: "POST", path: "/id/assignments/members", body: ["member_user_ids": identifiers])
        )
      }
      await expectBadRequest {
        _ = try await self.client().guardrails.bulkUnassignMembersFromGuardrail(
          id: "id", BulkUnassignMembersRequest(memberUserIDs: identifiers),
          options: options(
            method: "POST", path: "/id/assignments/members/remove",
            body: ["member_user_ids": identifiers]))
      }
    }
    for (offset, limit) in [(-1, 50), (0, 0), (0, 101)] {
      await expectBadRequest {
        _ = try await self.client().guardrails.list(
          offset: offset, limit: limit,
          options: options(
            method: "GET", path: "", query: ["offset": String(offset), "limit": String(limit)]))
      }
    }
  }

  func testErrors() async throws {
    for status in [400, 401, 403, 404, 409, 500] {
      do {
        _ = try await client().guardrails.get(
          id: "id", options: RequestOptions(extraHeaders: ["X-Status": String(status)]))
        XCTFail("Expected error")
      } catch let error as OpenRouterError {
        guard case .apiError(let actual, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(actual, status)
      }
    }
    do {
      _ = try await client(key: nil).guardrails.list()
      XCTFail("Expected missing key")
    } catch let error as OpenRouterError {
      guard case .missingAPIKey = error else { return XCTFail("Unexpected error") }
    }
  }

  private func object<T: Encodable>(_ value: T) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as! [String: Any]
  }
  private func client(key: String? = "management-key") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [GuardrailOfflineProtocol.self]
    let session = URLSession(configuration: config)
    return key.map { OpenRouterClient(apiKey: $0, session: session) }
      ?? OpenRouterClient(session: session)
  }
}
private final class GuardrailOfflineProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer management-key")
      if let method = request.value(forHTTPHeaderField: "X-Method") {
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Path"))
        let actual = Dictionary(
          uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        let expected =
          try JSONSerialization.jsonObject(
            with: Data(request.value(forHTTPHeaderField: "X-Query")!.utf8)) as! [String: String]
        XCTAssertEqual(actual, expected)
        if method == "POST" || method == "PATCH" {
          var data = request.httpBody ?? Data()
          if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
              let n = stream.read(&buffer, maxLength: buffer.count)
              if n <= 0 { break }
              data.append(contentsOf: buffer.prefix(n))
            }
          }
          let actualBody = try JSONSerialization.jsonObject(with: data) as! NSDictionary
          let expectedBody =
            try JSONSerialization.jsonObject(
              with: Data(request.value(forHTTPHeaderField: "X-Body")!.utf8)) as! NSDictionary
          XCTAssertEqual(actualBody, expectedBody)
        }
      }
      let status = Int(
        request.value(forHTTPHeaderField: "X-Status") ?? request.value(
          forHTTPHeaderField: "X-Success") ?? "200")!
      let json =
        status >= 400
        ? "{\"error\":{\"code\":\(status),\"message\":\"guardrail failure\"}}"
        : request.value(forHTTPHeaderField: "X-Response") ?? "{\"data\":[],\"total_count\":0}"
      client?.urlProtocol(
        self,
        didReceive: HTTPURLResponse(
          url: url, statusCode: status,
          httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
        cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data(json.utf8))
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
