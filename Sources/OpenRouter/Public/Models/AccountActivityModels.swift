import Foundation

public struct GenerationResponse: Codable, Sendable, Equatable {
  public var data: Generation?

  public init(data: Generation? = nil) {
    self.data = data
  }
}

public struct Generation: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var providerName: String?
  public var createdAt: String?
  public var updatedAt: String?
  public var status: String?
  public var totalCost: Double?
  public var usage: Usage?
  public var nativeFinishReason: String?
  public var finishReason: String?
  public var tokensPrompt: Int?
  public var tokensCompletion: Int?
  public var metadata: JSONValue?

  enum CodingKeys: String, CodingKey {
    case id
    case model
    case providerName = "provider_name"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case status
    case totalCost = "total_cost"
    case usage
    case nativeFinishReason = "native_finish_reason"
    case finishReason = "finish_reason"
    case tokensPrompt = "tokens_prompt"
    case tokensCompletion = "tokens_completion"
    case metadata
  }
}

public struct GenerationContentResponse: Codable, Sendable, Equatable {
  public var data: GenerationContent?

  public init(data: GenerationContent? = nil) {
    self.data = data
  }
}

public struct GenerationContent: Codable, Sendable, Equatable {
  public var id: String?
  public var input: JSONValue?
  public var output: JSONValue?
  public var prompt: JSONValue?
  public var completion: JSONValue?
  public var messages: JSONValue?
  public var rawContent: JSONValue?

  enum CodingKeys: String, CodingKey {
    case id
    case input
    case output
    case prompt
    case completion
    case messages
    case rawContent = "raw_content"
  }
}

public struct ActivityResponse: Codable, Sendable, Equatable {
  public var data: [ActivityItem]

  public init(data: [ActivityItem]) {
    self.data = data
  }
}

public struct ActivityItem: Codable, Sendable, Equatable {
  public var date: String
  public var model: String
  public var modelPermaslug: String
  public var endpointID: String
  public var providerName: String
  public var usage: Double
  public var byokUsageInference: Double
  public var requests: Int
  public var promptTokens: Int
  public var completionTokens: Int
  public var reasoningTokens: Int
  public var workspaceID: String?

  enum CodingKeys: String, CodingKey {
    case date, model, usage, requests
    case modelPermaslug = "model_permaslug"
    case endpointID = "endpoint_id"
    case providerName = "provider_name"
    case byokUsageInference = "byok_usage_inference"
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case reasoningTokens = "reasoning_tokens"
    case workspaceID = "workspace_id"
  }

  public init(
    date: String,
    model: String,
    modelPermaslug: String,
    endpointID: String,
    providerName: String,
    usage: Double,
    byokUsageInference: Double,
    requests: Int,
    promptTokens: Int,
    completionTokens: Int,
    reasoningTokens: Int,
    workspaceID: String? = nil
  ) {
    self.date = date
    self.model = model
    self.modelPermaslug = modelPermaslug
    self.endpointID = endpointID
    self.providerName = providerName
    self.usage = usage
    self.byokUsageInference = byokUsageInference
    self.requests = requests
    self.promptTokens = promptTokens
    self.completionTokens = completionTokens
    self.reasoningTokens = reasoningTokens
    self.workspaceID = workspaceID
  }
}

public struct RankingsDailyResponse: Codable, Sendable, Equatable {
  public var data: [RankingsDailyItem]
  public var meta: RankingsDailyMeta

  public init(data: [RankingsDailyItem], meta: RankingsDailyMeta) {
    self.data = data
    self.meta = meta
  }
}

public struct RankingsDailyItem: Codable, Sendable, Equatable {
  public var date: String
  public var modelPermaslug: String
  public var totalTokens: String

  enum CodingKeys: String, CodingKey {
    case date
    case modelPermaslug = "model_permaslug"
    case totalTokens = "total_tokens"
  }

  public init(date: String, modelPermaslug: String, totalTokens: String) {
    self.date = date
    self.modelPermaslug = modelPermaslug
    self.totalTokens = totalTokens
  }
}

public struct RankingsDailyMeta: Codable, Sendable, Equatable {
  public var asOf: String
  public var version: String
  public var startDate: String
  public var endDate: String

  enum CodingKeys: String, CodingKey {
    case version
    case asOf = "as_of"
    case startDate = "start_date"
    case endDate = "end_date"
  }

  public init(asOf: String, version: String, startDate: String, endDate: String) {
    self.asOf = asOf
    self.version = version
    self.startDate = startDate
    self.endDate = endDate
  }
}

public struct CreditsResponse: Codable, Sendable, Equatable {
  public var data: Credits?
  public var totalCredits: Double?
  public var totalUsage: Double?

  enum CodingKeys: String, CodingKey {
    case data
    case totalCredits = "total_credits"
    case totalUsage = "total_usage"
  }

  public init(data: Credits? = nil, totalCredits: Double? = nil, totalUsage: Double? = nil) {
    self.data = data
    self.totalCredits = totalCredits
    self.totalUsage = totalUsage
  }
}

public struct Credits: Codable, Sendable, Equatable {
  public var totalCredits: Double?
  public var totalUsage: Double?

  enum CodingKeys: String, CodingKey {
    case totalCredits = "total_credits"
    case totalUsage = "total_usage"
  }

  public init(totalCredits: Double? = nil, totalUsage: Double? = nil) {
    self.totalCredits = totalCredits
    self.totalUsage = totalUsage
  }
}
