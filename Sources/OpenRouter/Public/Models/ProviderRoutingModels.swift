import Foundation

public struct ProviderPreferences: Codable, Sendable, Equatable {
  public var allowFallbacks: Bool?
  public var order: [String]?
  public var only: [String]?
  public var ignore: [String]?
  public var requireParameters: Bool?
  public var sort: String?
  public var zdr: Bool?

  enum CodingKeys: String, CodingKey {
    case allowFallbacks = "allow_fallbacks"
    case order
    case only
    case ignore
    case requireParameters = "require_parameters"
    case sort
    case zdr
  }

  public init(
    allowFallbacks: Bool? = nil,
    order: [String]? = nil,
    only: [String]? = nil,
    ignore: [String]? = nil,
    requireParameters: Bool? = nil,
    sort: String? = nil,
    zdr: Bool? = nil
  ) {
    self.allowFallbacks = allowFallbacks
    self.order = order
    self.only = only
    self.ignore = ignore
    self.requireParameters = requireParameters
    self.sort = sort
    self.zdr = zdr
  }
}
