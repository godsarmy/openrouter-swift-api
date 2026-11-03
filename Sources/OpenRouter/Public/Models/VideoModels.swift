import Foundation

public struct VideoRequest: Codable, Sendable, Equatable {
  public var model: String
  public var prompt: String
  public var aspectRatio: AspectRatio?
  public var duration: Int?
  public var resolution: Resolution?
  public var size: String?
  public var generateAudio: Bool?
  public var seed: Int?
  public var callbackURL: String?
  public var frameImages: [JSONValue]?
  public var inputReferences: [JSONValue]?
  public var provider: JSONValue?

  enum CodingKeys: String, CodingKey {
    case model, prompt, duration, resolution, size, seed, provider
    case aspectRatio = "aspect_ratio"
    case generateAudio = "generate_audio"
    case callbackURL = "callback_url"
    case frameImages = "frame_images"
    case inputReferences = "input_references"
  }

  public init(
    model: String,
    prompt: String,
    aspectRatio: AspectRatio? = nil,
    duration: Int? = nil,
    resolution: Resolution? = nil,
    size: String? = nil,
    generateAudio: Bool? = nil,
    seed: Int? = nil,
    callbackURL: String? = nil,
    frameImages: [JSONValue]? = nil,
    inputReferences: [JSONValue]? = nil,
    provider: JSONValue? = nil
  ) {
    self.model = model
    self.prompt = prompt
    self.aspectRatio = aspectRatio
    self.duration = duration
    self.resolution = resolution
    self.size = size
    self.generateAudio = generateAudio
    self.seed = seed
    self.callbackURL = callbackURL
    self.frameImages = frameImages
    self.inputReferences = inputReferences
    self.provider = provider
  }

  public enum AspectRatio: String, Codable, Sendable, Equatable {
    case landscape = "16:9"
    case portrait = "9:16"
    case square = "1:1"
    case standardLandscape = "4:3"
    case standardPortrait = "3:4"
    case photoLandscape = "3:2"
    case photoPortrait = "2:3"
    case ultrawide = "21:9"
    case ultrawidePortrait = "9:21"
  }

  public enum Resolution: String, Codable, Sendable, Equatable {
    case p480 = "480p"
    case p720 = "720p"
    case p1080 = "1080p"
    case k1 = "1K"
    case k2 = "2K"
    case k4 = "4K"
  }
}

public struct VideoResponse: Codable, Sendable, Equatable {
  public var id: String
  public var pollingURL: String
  public var status: Status
  public var generationID: String?
  public var error: String?
  public var unsignedURLs: [String]?
  public var usage: VideoUsage?
  public var rawPayload: JSONValue

  enum CodingKeys: String, CodingKey {
    case id, status, error, usage
    case pollingURL = "polling_url"
    case generationID = "generation_id"
    case unsignedURLs = "unsigned_urls"
  }

  public init(
    id: String,
    pollingURL: String,
    status: Status,
    generationID: String? = nil,
    error: String? = nil,
    unsignedURLs: [String]? = nil,
    usage: VideoUsage? = nil,
    rawPayload: JSONValue? = nil
  ) {
    self.id = id
    self.pollingURL = pollingURL
    self.status = status
    self.generationID = generationID
    self.error = error
    self.unsignedURLs = unsignedURLs
    self.usage = usage
    self.rawPayload =
      rawPayload
      ?? .object([
        "id": .string(id), "polling_url": .string(pollingURL), "status": .string(status.rawValue),
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    pollingURL = try container.decode(String.self, forKey: .pollingURL)
    status = try container.decode(Status.self, forKey: .status)
    generationID = try container.decodeIfPresent(String.self, forKey: .generationID)
    error = try container.decodeIfPresent(String.self, forKey: .error)
    unsignedURLs = try container.decodeIfPresent([String].self, forKey: .unsignedURLs)
    usage = try container.decodeIfPresent(VideoUsage.self, forKey: .usage)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }

  public enum Status: String, Codable, Sendable, Equatable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled
    case expired
  }
}

public struct VideoUsage: Codable, Sendable, Equatable {
  public var cost: Double?
  public var isByok: Bool?

  enum CodingKeys: String, CodingKey {
    case cost
    case isByok = "is_byok"
  }

  public init(cost: Double? = nil, isByok: Bool? = nil) {
    self.cost = cost
    self.isByok = isByok
  }
}

public struct VideoContentRequest: Sendable, Equatable {
  public var jobID: String
  public var index: Int?
  public init(jobID: String, index: Int? = nil) {
    self.jobID = jobID
    self.index = index
  }
}

public struct VideoContentResponse: Sendable, Equatable {
  public var data: Data
  public var contentType: String?
  public init(data: Data, contentType: String? = nil) {
    self.data = data
    self.contentType = contentType
  }
}

public struct VideoModelsListResponse: Codable, Sendable, Equatable {
  public var data: [VideoModel]
  public init(data: [VideoModel]) { self.data = data }
}

public struct VideoModel: Codable, Sendable, Equatable {
  public var id: String
  public var canonicalSlug: String?
  public var name: String
  public var description: String?
  public var created: Int?
  public var generateAudio: Bool?
  public var pricingSKUs: JSONValue?
  public var seed: Bool?
  public var supportedAspectRatios: [String]?
  public var supportedDurations: [Int]?
  public var supportedFrameImages: [String]?
  public var supportedResolutions: [String]?
  public var supportedSizes: [String]?
  public var allowedPassthroughParameters: [String]?

  enum CodingKeys: String, CodingKey {
    case id, name, description, created, seed
    case canonicalSlug = "canonical_slug"
    case generateAudio = "generate_audio"
    case pricingSKUs = "pricing_skus"
    case supportedAspectRatios = "supported_aspect_ratios"
    case supportedDurations = "supported_durations"
    case supportedFrameImages = "supported_frame_images"
    case supportedResolutions = "supported_resolutions"
    case supportedSizes = "supported_sizes"
    case allowedPassthroughParameters = "allowed_passthrough_parameters"
  }

  public init(
    id: String, name: String, canonicalSlug: String? = nil, description: String? = nil,
    created: Int? = nil, generateAudio: Bool? = nil, pricingSKUs: JSONValue? = nil,
    seed: Bool? = nil, supportedAspectRatios: [String]? = nil,
    supportedDurations: [Int]? = nil, supportedFrameImages: [String]? = nil,
    supportedResolutions: [String]? = nil, supportedSizes: [String]? = nil,
    allowedPassthroughParameters: [String]? = nil
  ) {
    self.id = id
    self.name = name
    self.canonicalSlug = canonicalSlug
    self.description = description
    self.created = created
    self.generateAudio = generateAudio
    self.pricingSKUs = pricingSKUs
    self.seed = seed
    self.supportedAspectRatios = supportedAspectRatios
    self.supportedDurations = supportedDurations
    self.supportedFrameImages = supportedFrameImages
    self.supportedResolutions = supportedResolutions
    self.supportedSizes = supportedSizes
    self.allowedPassthroughParameters = allowedPassthroughParameters
  }
}
