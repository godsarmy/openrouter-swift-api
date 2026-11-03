import Foundation

public struct Usage: Codable, Sendable, Equatable {
  public var promptTokens: Int?
  public var completionTokens: Int?
  public var totalTokens: Int?
  public var promptTokensDetails: PromptTokenDetails?
  public var completionTokensDetails: CompletionTokenDetails?
  public var cost: Double?
  public var costDetails: UsageCostDetails?
  public var isByok: Bool?

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
    case promptTokensDetails = "prompt_tokens_details"
    case completionTokensDetails = "completion_tokens_details"
    case cost
    case costDetails = "cost_details"
    case isByok = "is_byok"
  }

  public init(
    promptTokens: Int? = nil,
    completionTokens: Int? = nil,
    totalTokens: Int? = nil,
    promptTokensDetails: PromptTokenDetails? = nil,
    completionTokensDetails: CompletionTokenDetails? = nil,
    cost: Double? = nil,
    costDetails: UsageCostDetails? = nil,
    isByok: Bool? = nil
  ) {
    self.promptTokens = promptTokens
    self.completionTokens = completionTokens
    self.totalTokens = totalTokens
    self.promptTokensDetails = promptTokensDetails
    self.completionTokensDetails = completionTokensDetails
    self.cost = cost
    self.costDetails = costDetails
    self.isByok = isByok
  }
}

public struct UsageCostDetails: Codable, Sendable, Equatable {
  public var upstreamInferenceCost: Double?

  enum CodingKeys: String, CodingKey {
    case upstreamInferenceCost = "upstream_inference_cost"
  }

  public init(upstreamInferenceCost: Double? = nil) {
    self.upstreamInferenceCost = upstreamInferenceCost
  }
}

public struct TokenDetails: Codable, Sendable, Equatable {
  public var cachedTokens: Int?
  public var audioTokens: Int?
  public var cacheWriteTokens: Int?
  public var videoTokens: Int?
  public var acceptedPredictionTokens: Int?
  public var reasoningTokens: Int?
  public var rejectedPredictionTokens: Int?

  enum CodingKeys: String, CodingKey {
    case cachedTokens = "cached_tokens"
    case audioTokens = "audio_tokens"
    case cacheWriteTokens = "cache_write_tokens"
    case videoTokens = "video_tokens"
    case acceptedPredictionTokens = "accepted_prediction_tokens"
    case reasoningTokens = "reasoning_tokens"
    case rejectedPredictionTokens = "rejected_prediction_tokens"
  }

  public init(
    cachedTokens: Int? = nil,
    audioTokens: Int? = nil,
    cacheWriteTokens: Int? = nil,
    videoTokens: Int? = nil,
    acceptedPredictionTokens: Int? = nil,
    reasoningTokens: Int? = nil,
    rejectedPredictionTokens: Int? = nil
  ) {
    self.cachedTokens = cachedTokens
    self.audioTokens = audioTokens
    self.cacheWriteTokens = cacheWriteTokens
    self.videoTokens = videoTokens
    self.acceptedPredictionTokens = acceptedPredictionTokens
    self.reasoningTokens = reasoningTokens
    self.rejectedPredictionTokens = rejectedPredictionTokens
  }
}

public typealias PromptTokenDetails = TokenDetails
public typealias CompletionTokenDetails = TokenDetails
