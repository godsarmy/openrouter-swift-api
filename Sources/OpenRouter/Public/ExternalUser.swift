import Foundation

/// A registration, not an inference authorization decision or login account.
public struct ExternalUser: Codable, Sendable, Equatable {
  public var user: String
  public var isActive: Bool
  public var createdAt: String
  public var updatedAt: String
  public init(user: String, isActive: Bool, createdAt: String, updatedAt: String) {
    self.user = user
    self.isActive = isActive
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  enum CodingKeys: String, CodingKey {
    case user
    case isActive = "is_active"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
public struct CreateExternalUserRequest: Codable, Sendable, Equatable {
  public var user: String
  public init(user: String) { self.user = user }
}
/// Changes registration state only; does not enforce inference access.
public struct UpdateExternalUserRequest: Codable, Sendable, Equatable {
  public var isActive: Bool
  public init(isActive: Bool) { self.isActive = isActive }
  enum CodingKeys: String, CodingKey { case isActive = "is_active" }
}
public struct ExternalUserResponse: Codable, Sendable, Equatable {
  public var data: ExternalUser
  public init(data: ExternalUser) { self.data = data }
}
public struct ListExternalUsersResponse: Codable, Sendable, Equatable {
  public var data: [ExternalUser]
  public var totalCount: Int
  public init(data: [ExternalUser], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
