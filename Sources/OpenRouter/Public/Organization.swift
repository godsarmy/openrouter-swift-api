/// Settings for the organization associated with the authenticated API key.
public struct OrganizationSettings: Codable, Sendable, Equatable {
  public var id: String
  /// Controls dashboard catalog visibility only. Authenticated `/models` results are
  /// already filtered regardless of this setting; the anonymous catalog remains public.
  public var isFilteredModelCatalogEnabled: Bool

  public init(id: String, isFilteredModelCatalogEnabled: Bool) {
    self.id = id
    self.isFilteredModelCatalogEnabled = isFilteredModelCatalogEnabled
  }

  enum CodingKeys: String, CodingKey {
    case id
    case isFilteredModelCatalogEnabled = "is_filtered_model_catalog_enabled"
  }
}

/// Updates dashboard catalog visibility for the authenticated key's organization.
public struct UpdateOrganizationSettingsRequest: Codable, Sendable, Equatable {
  public var isFilteredModelCatalogEnabled: Bool

  public init(isFilteredModelCatalogEnabled: Bool) {
    self.isFilteredModelCatalogEnabled = isFilteredModelCatalogEnabled
  }

  enum CodingKeys: String, CodingKey {
    case isFilteredModelCatalogEnabled = "is_filtered_model_catalog_enabled"
  }
}

public struct OrganizationSettingsResponse: Codable, Sendable, Equatable {
  public var data: OrganizationSettings

  public init(data: OrganizationSettings) {
    self.data = data
  }
}

/// An organization member. Roles remain strings for forward compatibility.
public struct OrganizationMember: Codable, Sendable, Equatable {
  public var id: String
  public var firstName: String?
  public var lastName: String?
  public var email: String
  /// Currently `org:admin` or `org:member`.
  public var role: String

  public init(
    id: String, firstName: String? = nil, lastName: String? = nil, email: String, role: String
  ) {
    self.id = id
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.role = role
  }

  enum CodingKeys: String, CodingKey {
    case id, email, role
    case firstName = "first_name"
    case lastName = "last_name"
  }
}

/// A page of organization members and the total number available.
public struct OrganizationMembersResponse: Codable, Sendable, Equatable {
  public var data: [OrganizationMember]
  public var totalCount: Int

  public init(data: [OrganizationMember], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }

  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
