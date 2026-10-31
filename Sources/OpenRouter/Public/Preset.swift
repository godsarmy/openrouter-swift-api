/// Preset metadata. Status is extensible; known values are active, disabled, and archived.
public struct Preset: Codable, Sendable, Equatable {
  public var createdAt: String
  public var creatorUserID: String?
  public var description: String?
  public var designatedVersionID: String?
  public var id: String
  public var name: String
  public var slug: String
  public var status: String
  public var statusUpdatedAt: String?
  public var updatedAt: String
  public var workspaceID: String?
  public init(
    createdAt: String, creatorUserID: String? = nil, description: String? = nil,
    designatedVersionID: String? = nil, id: String, name: String, slug: String, status: String,
    statusUpdatedAt: String? = nil, updatedAt: String, workspaceID: String? = nil
  ) {
    self.createdAt = createdAt
    self.creatorUserID = creatorUserID
    self.description = description
    self.designatedVersionID = designatedVersionID
    self.id = id
    self.name = name
    self.slug = slug
    self.status = status
    self.statusUpdatedAt = statusUpdatedAt
    self.updatedAt = updatedAt
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case createdAt = "created_at"
    case creatorUserID = "creator_user_id"
    case description
    case designatedVersionID = "designated_version_id"
    case id
    case name
    case slug
    case status
    case statusUpdatedAt = "status_updated_at"
    case updatedAt = "updated_at"
    case workspaceID = "workspace_id"
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    creatorUserID = try c.decode(String?.self, forKey: .creatorUserID)
    description = try c.decode(String?.self, forKey: .description)
    designatedVersionID = try c.decode(String?.self, forKey: .designatedVersionID)
    id = try c.decode(String.self, forKey: .id)
    name = try c.decode(String.self, forKey: .name)
    slug = try c.decode(String.self, forKey: .slug)
    status = try c.decode(String.self, forKey: .status)
    statusUpdatedAt = try c.decode(String?.self, forKey: .statusUpdatedAt)
    updatedAt = try c.decode(String.self, forKey: .updatedAt)
    workspaceID = try c.decode(String?.self, forKey: .workspaceID)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(creatorUserID, forKey: .creatorUserID)
    try c.encode(description, forKey: .description)
    try c.encode(designatedVersionID, forKey: .designatedVersionID)
    try c.encode(id, forKey: .id)
    try c.encode(name, forKey: .name)
    try c.encode(slug, forKey: .slug)
    try c.encode(status, forKey: .status)
    try c.encode(statusUpdatedAt, forKey: .statusUpdatedAt)
    try c.encode(updatedAt, forKey: .updatedAt)
    try c.encode(workspaceID, forKey: .workspaceID)
  }
}
public struct PresetVersion: Codable, Sendable, Equatable {
  public var config: [String: JSONValue]
  public var createdAt: String
  public var creatorID: String
  public var id: String
  public var presetID: String
  public var systemPrompt: String?
  public var updatedAt: String
  public var version: Int
  public init(
    config: [String: JSONValue], createdAt: String, creatorID: String, id: String, presetID: String,
    systemPrompt: String? = nil, updatedAt: String, version: Int
  ) {
    self.config = config
    self.createdAt = createdAt
    self.creatorID = creatorID
    self.id = id
    self.presetID = presetID
    self.systemPrompt = systemPrompt
    self.updatedAt = updatedAt
    self.version = version
  }
  enum CodingKeys: String, CodingKey {
    case config
    case createdAt = "created_at"
    case creatorID = "creator_id"
    case id
    case presetID = "preset_id"
    case systemPrompt = "system_prompt"
    case updatedAt = "updated_at"
    case version
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    config = try c.decode([String: JSONValue].self, forKey: .config)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    creatorID = try c.decode(String.self, forKey: .creatorID)
    id = try c.decode(String.self, forKey: .id)
    presetID = try c.decode(String.self, forKey: .presetID)
    systemPrompt = try c.decode(String?.self, forKey: .systemPrompt)
    updatedAt = try c.decode(String.self, forKey: .updatedAt)
    version = try c.decode(Int.self, forKey: .version)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(config, forKey: .config)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(creatorID, forKey: .creatorID)
    try c.encode(id, forKey: .id)
    try c.encode(presetID, forKey: .presetID)
    try c.encode(systemPrompt, forKey: .systemPrompt)
    try c.encode(updatedAt, forKey: .updatedAt)
    try c.encode(version, forKey: .version)
  }
}
/// Reuses preset metadata while encoding the API's flattened object (not a nested `preset` key).
public struct PresetWithDesignatedVersion: Codable, Sendable, Equatable {
  public var preset: Preset
  public var designatedVersion: PresetVersion?
  public init(preset: Preset, designatedVersion: PresetVersion?) {
    self.preset = preset
    self.designatedVersion = designatedVersion
  }
  enum CodingKeys: String, CodingKey { case designatedVersion = "designated_version" }
  public init(from decoder: Decoder) throws {
    preset = try Preset(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    designatedVersion = try c.decode(PresetVersion?.self, forKey: .designatedVersion)
  }
  public func encode(to encoder: Encoder) throws {
    try preset.encode(to: encoder)
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(designatedVersion, forKey: .designatedVersion)
  }
}
public struct ListPresetsResponse: Codable, Sendable, Equatable {
  public var data: [Preset]
  public var totalCount: Int
  public init(data: [Preset], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    data = try c.decode([Preset].self, forKey: .data)
    totalCount = try c.decode(Int.self, forKey: .totalCount)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(data, forKey: .data)
    try c.encode(totalCount, forKey: .totalCount)
  }
}
public struct ListPresetVersionsResponse: Codable, Sendable, Equatable {
  public var data: [PresetVersion?]
  public var totalCount: Int
  public init(data: [PresetVersion?], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    data = try c.decode([PresetVersion?].self, forKey: .data)
    totalCount = try c.decode(Int.self, forKey: .totalCount)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(data, forKey: .data)
    try c.encode(totalCount, forKey: .totalCount)
  }
}
public struct GetPresetResponse: Codable, Sendable, Equatable {
  public var data: PresetWithDesignatedVersion
  public init(data: PresetWithDesignatedVersion) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    data = try c.decode(PresetWithDesignatedVersion.self, forKey: .data)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(data, forKey: .data)
  }
}
public struct CreatePresetFromInferenceResponse: Codable, Sendable, Equatable {
  public var data: PresetWithDesignatedVersion
  public init(data: PresetWithDesignatedVersion) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    data = try c.decode(PresetWithDesignatedVersion.self, forKey: .data)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(data, forKey: .data)
  }
}
public struct GetPresetVersionResponse: Codable, Sendable, Equatable {
  public var data: PresetVersion?
  public init(data: PresetVersion? = nil) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    data = try c.decode(PresetVersion?.self, forKey: .data)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(data, forKey: .data)
  }
}
