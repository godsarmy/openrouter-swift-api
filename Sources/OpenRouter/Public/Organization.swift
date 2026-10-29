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
