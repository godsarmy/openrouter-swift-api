/// Supported workspace budget intervals. Lifetime budgets have no reset interval.
public enum WorkspaceBudgetInterval: String, Codable, Sendable, Equatable, CaseIterable {
  case daily, weekly, monthly, lifetime
}

public struct WorkspaceBudget: Codable, Sendable, Equatable {
  public var id: String
  public var workspaceID: String
  public var limitUSD: Double
  /// `daily`, `weekly`, `monthly`, or nil for a lifetime budget.
  public var resetInterval: String?
  public var createdAt: String
  public var updatedAt: String

  public init(
    id: String, workspaceID: String, limitUSD: Double, resetInterval: String?, createdAt: String,
    updatedAt: String
  ) {
    self.id = id
    self.workspaceID = workspaceID
    self.limitUSD = limitUSD
    self.resetInterval = resetInterval
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  enum CodingKeys: String, CodingKey {
    case id
    case workspaceID = "workspace_id"
    case limitUSD = "limit_usd"
    case resetInterval = "reset_interval"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// A positive USD limit. The server validates strict interval hierarchy and applies changes immediately.
public struct UpsertWorkspaceBudgetRequest: Codable, Sendable, Equatable {
  public var limitUSD: Double
  /// Workspace-wide, not per interval. Nil leaves the current setting unchanged.
  public var includeBYOKInBudgets: Bool?

  public init(limitUSD: Double, includeBYOKInBudgets: Bool? = nil) {
    self.limitUSD = limitUSD
    self.includeBYOKInBudgets = includeBYOKInBudgets
  }

  enum CodingKeys: String, CodingKey {
    case limitUSD = "limit_usd"
    case includeBYOKInBudgets = "include_byok_in_budgets"
  }
}

public struct WorkspaceBudgetsResponse: Codable, Sendable, Equatable {
  public var data: [WorkspaceBudget]
  public var includeBYOKInBudgets: Bool?

  public init(data: [WorkspaceBudget], includeBYOKInBudgets: Bool? = nil) {
    self.data = data
    self.includeBYOKInBudgets = includeBYOKInBudgets
  }

  enum CodingKeys: String, CodingKey {
    case data
    case includeBYOKInBudgets = "include_byok_in_budgets"
  }
}

public struct WorkspaceBudgetResponse: Codable, Sendable, Equatable {
  public var data: WorkspaceBudget
  public var includeBYOKInBudgets: Bool?

  public init(data: WorkspaceBudget, includeBYOKInBudgets: Bool? = nil) {
    self.data = data
    self.includeBYOKInBudgets = includeBYOKInBudgets
  }

  enum CodingKeys: String, CodingKey {
    case data
    case includeBYOKInBudgets = "include_byok_in_budgets"
  }
}

/// Deletion succeeds even if the interval was already absent. Other intervals and BYOK settings remain.
public struct DeleteWorkspaceBudgetResponse: Codable, Sendable, Equatable {
  public var deleted: Bool
  public init(deleted: Bool) { self.deleted = deleted }
}
