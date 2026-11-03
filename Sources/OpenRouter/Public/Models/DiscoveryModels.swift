import Foundation

public struct ModelsResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterModel]

  public init(data: [OpenRouterModel]) {
    self.data = data
  }
}

/// A paginated list of models filtered for the authenticated user.
public struct UserModelsResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterModel]
  public var links: Links
  public var totalCount: Int

  enum CodingKeys: String, CodingKey {
    case data
    case links
    case totalCount = "total_count"
  }

  public init(data: [OpenRouterModel], links: Links, totalCount: Int) {
    self.data = data
    self.links = links
    self.totalCount = totalCount
  }

  public struct Links: Codable, Sendable, Equatable {
    public var next: String?

    public init(next: String? = nil) {
      self.next = next
    }
  }
}

public struct ModelsCountResponse: Codable, Sendable, Equatable {
  public var data: ModelsCount

  public init(data: ModelsCount) {
    self.data = data
  }
}

public struct ModelsCount: Codable, Sendable, Equatable {
  public var count: Int

  public init(count: Int) {
    self.count = count
  }
}

/// A paginated list of embedding-capable models.
public struct EmbeddingsModelsResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterModel]
  public var links: Links
  public var totalCount: Int

  enum CodingKeys: String, CodingKey {
    case data
    case links
    case totalCount = "total_count"
  }

  public init(data: [OpenRouterModel], links: Links, totalCount: Int) {
    self.data = data
    self.links = links
    self.totalCount = totalCount
  }

  public struct Links: Codable, Sendable, Equatable {
    public var next: String?

    public init(next: String? = nil) {
      self.next = next
    }
  }
}

public struct OpenRouterModel: Codable, Sendable, Equatable {
  public var id: String
  public var name: String?
  public var description: String?
  public var contextLength: Int?
  public var architecture: JSONValue?
  public var pricing: ModelPricing?
  public var topProvider: JSONValue?
  public var perRequestLimits: JSONValue?
  public var supportedParameters: [String]?
  public var canonicalSlug: String?
  public var created: Int?
  public var defaultParameters: JSONValue?
  public var expirationDate: String?
  public var benchmarks: JSONValue?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case contextLength = "context_length"
    case architecture
    case pricing
    case topProvider = "top_provider"
    case perRequestLimits = "per_request_limits"
    case supportedParameters = "supported_parameters"
    case canonicalSlug = "canonical_slug"
    case created
    case defaultParameters = "default_parameters"
    case expirationDate = "expiration_date"
    case benchmarks
  }
}

public struct ModelResponse: Codable, Sendable, Equatable {
  public var data: OpenRouterModel
  public init(data: OpenRouterModel) { self.data = data }
}

public struct ModelPricing: Codable, Sendable, Equatable {
  public var prompt: String?
  public var completion: String?
  public var image: String?
  public var request: String?
  public var inputCacheRead: String?
  public var inputCacheWrite: String?
  public var webSearch: String?
  public var internalReasoning: String?

  enum CodingKeys: String, CodingKey {
    case prompt
    case completion
    case image
    case request
    case inputCacheRead = "input_cache_read"
    case inputCacheWrite = "input_cache_write"
    case webSearch = "web_search"
    case internalReasoning = "internal_reasoning"
  }
}

public struct ProvidersResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterProvider]

  public init(data: [OpenRouterProvider]) {
    self.data = data
  }
}

public struct OpenRouterProvider: Codable, Sendable, Equatable {
  public var name: String
  public var slug: String
  public var privacyPolicyURL: String?
  public var statusPageURL: String?
  public var termsOfServiceURL: String?
  public var datacenters: JSONValue?
  public var headquarters: JSONValue?

  enum CodingKeys: String, CodingKey {
    case name
    case slug
    case privacyPolicyURL = "privacy_policy_url"
    case statusPageURL = "status_page_url"
    case termsOfServiceURL = "terms_of_service_url"
    case datacenters
    case headquarters
  }

  public init(
    name: String,
    slug: String,
    privacyPolicyURL: String? = nil,
    statusPageURL: String? = nil,
    termsOfServiceURL: String? = nil,
    datacenters: JSONValue? = nil,
    headquarters: JSONValue? = nil
  ) {
    self.name = name
    self.slug = slug
    self.privacyPolicyURL = privacyPolicyURL
    self.statusPageURL = statusPageURL
    self.termsOfServiceURL = termsOfServiceURL
    self.datacenters = datacenters
    self.headquarters = headquarters
  }
}

public struct ModelEndpointsResponse: Codable, Sendable, Equatable {
  public var data: ModelEndpoints

  public init(data: ModelEndpoints) {
    self.data = data
  }
}

public struct ZDREndpointsResponse: Codable, Sendable, Equatable {
  public var data: [PublicEndpoint]

  public init(data: [PublicEndpoint]) {
    self.data = data
  }
}

public struct ModelEndpoints: Codable, Sendable, Equatable {
  public var id: String?
  public var name: String?
  public var description: String?
  public var created: Int?
  public var architecture: JSONValue?
  public var endpoints: [PublicEndpoint]

  public init(
    id: String? = nil,
    name: String? = nil,
    description: String? = nil,
    created: Int? = nil,
    architecture: JSONValue? = nil,
    endpoints: [PublicEndpoint] = []
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.created = created
    self.architecture = architecture
    self.endpoints = endpoints
  }
}

public struct PublicEndpoint: Codable, Sendable, Equatable {
  public var name: String?
  public var providerName: String?
  public var contextLength: Int?
  public var maxCompletionTokens: Int?
  public var pricing: ModelPricing?
  public var supportedParameters: [String]?
  public var extra: JSONValue?

  enum CodingKeys: String, CodingKey {
    case name
    case providerName = "provider_name"
    case contextLength = "context_length"
    case maxCompletionTokens = "max_completion_tokens"
    case pricing
    case supportedParameters = "supported_parameters"
    case extra
  }

  public init(
    name: String? = nil,
    providerName: String? = nil,
    contextLength: Int? = nil,
    maxCompletionTokens: Int? = nil,
    pricing: ModelPricing? = nil,
    supportedParameters: [String]? = nil,
    extra: JSONValue? = nil
  ) {
    self.name = name
    self.providerName = providerName
    self.contextLength = contextLength
    self.maxCompletionTokens = maxCompletionTokens
    self.pricing = pricing
    self.supportedParameters = supportedParameters
    self.extra = extra
  }
}
