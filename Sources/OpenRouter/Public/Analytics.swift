/// An analytics query requiring a management key. Nil options use server defaults; the server validates query constraints.
public struct AnalyticsQueryRequest: Codable, Sendable, Equatable {
  public var metrics: [String]
  public var dimensions: [String]?
  public var filters: [AnalyticsFilter]?
  public var granularity: String?
  public var groupLimit: Int?
  public var limit: Int?
  public var orderBy: AnalyticsOrderBy?
  public var timeRange: AnalyticsTimeRange?
  public var classifierDimensions: AnalyticsClassifierDimensions?
  public var classifierFilters: AnalyticsClassifierFilters?

  public init(
    metrics: [String], dimensions: [String]? = nil, filters: [AnalyticsFilter]? = nil,
    granularity: String? = nil, groupLimit: Int? = nil, limit: Int? = nil,
    orderBy: AnalyticsOrderBy? = nil, timeRange: AnalyticsTimeRange? = nil,
    classifierDimensions: AnalyticsClassifierDimensions? = nil,
    classifierFilters: AnalyticsClassifierFilters? = nil
  ) {
    self.metrics = metrics
    self.dimensions = dimensions
    self.filters = filters
    self.granularity = granularity
    self.groupLimit = groupLimit
    self.limit = limit
    self.orderBy = orderBy
    self.timeRange = timeRange
    self.classifierDimensions = classifierDimensions
    self.classifierFilters = classifierFilters
  }

  enum CodingKeys: String, CodingKey {
    case metrics
    case dimensions
    case filters
    case granularity
    case groupLimit = "group_limit"
    case limit
    case orderBy = "order_by"
    case timeRange = "time_range"
    case classifierDimensions = "classifier_dimensions"
    case classifierFilters = "classifier_filters"
  }
}

/// A dimension filter. Use a string/number value for scalar operators, or an array of strings/numbers for set operators. The server validates operator/value combinations.
public struct AnalyticsFilter: Codable, Sendable, Equatable {
  public var field: String
  public var `operator`: String
  public var value: JSONValue
  public var includeUnset: Bool?

  public init(field: String, `operator`: String, value: JSONValue, includeUnset: Bool? = nil) {
    self.field = field
    self.operator = `operator`
    self.value = value
    self.includeUnset = includeUnset
  }

  enum CodingKeys: String, CodingKey {
    case field
    case `operator`
    case value
    case includeUnset = "include_unset"
  }
}

/// A classifier tag filter with a string/number scalar or an array of strings/numbers. The server validates operator/value combinations.
public struct AnalyticsClassifierFilter: Codable, Sendable, Equatable {
  public var field: String
  public var `operator`: String
  public var value: JSONValue

  public init(field: String, `operator`: String, value: JSONValue) {
    self.field = field
    self.operator = `operator`
    self.value = value
  }
}

public struct AnalyticsClassifierDimensions: Codable, Sendable, Equatable {
  public var classifierID: String
  public var dimensionNames: [String]?
  public var includeNulls: Bool?

  public init(classifierID: String, dimensionNames: [String]? = nil, includeNulls: Bool? = nil) {
    self.classifierID = classifierID
    self.dimensionNames = dimensionNames
    self.includeNulls = includeNulls
  }

  enum CodingKeys: String, CodingKey {
    case classifierID = "classifier_id"
    case dimensionNames = "dimension_names"
    case includeNulls = "include_nulls"
  }
}

public struct AnalyticsClassifierFilters: Codable, Sendable, Equatable {
  public var classifierID: String
  public var filters: [AnalyticsClassifierFilter]

  public init(classifierID: String, filters: [AnalyticsClassifierFilter]) {
    self.classifierID = classifierID
    self.filters = filters
  }

  enum CodingKeys: String, CodingKey {
    case classifierID = "classifier_id"
    case filters
  }
}

/// Ordering direction is normally `asc` or `desc`; strings allow future server values.
public struct AnalyticsOrderBy: Codable, Sendable, Equatable {
  public var field: String
  public var direction: String

  public init(field: String, direction: String) {
    self.field = field
    self.direction = direction
  }
}

/// ISO 8601 UTC timestamps including seconds; strings preserve fractional seconds.
public struct AnalyticsTimeRange: Codable, Sendable, Equatable {
  public var start: String
  public var end: String

  public init(start: String, end: String) {
    self.start = start
    self.end = end
  }
}

public struct AnalyticsMetaResponse: Codable, Sendable, Equatable {
  public var data: AnalyticsMeta

  public init(data: AnalyticsMeta) {
    self.data = data
  }
}

/// Available query vocabulary. Identifiers and display formats remain strings for forward compatibility.
public struct AnalyticsMeta: Codable, Sendable, Equatable {
  public var metrics: [AnalyticsMetric]
  public var dimensions: [AnalyticsDimension]
  public var operators: [AnalyticsOperator]
  public var granularities: [AnalyticsGranularity]

  public init(
    metrics: [AnalyticsMetric], dimensions: [AnalyticsDimension], operators: [AnalyticsOperator],
    granularities: [AnalyticsGranularity]
  ) {
    self.metrics = metrics
    self.dimensions = dimensions
    self.operators = operators
    self.granularities = granularities
  }
}

public struct AnalyticsMetric: Codable, Sendable, Equatable {
  public var name: String
  public var displayLabel: String
  public var isRate: Bool
  public var displayFormat: String

  public init(name: String, displayLabel: String, isRate: Bool, displayFormat: String) {
    self.name = name
    self.displayLabel = displayLabel
    self.isRate = isRate
    self.displayFormat = displayFormat
  }

  enum CodingKeys: String, CodingKey {
    case name
    case displayLabel = "display_label"
    case isRate = "is_rate"
    case displayFormat = "display_format"
  }
}

public struct AnalyticsDimension: Codable, Sendable, Equatable {
  public var name: String
  public var displayLabel: String

  public init(name: String, displayLabel: String) {
    self.name = name
    self.displayLabel = displayLabel
  }

  enum CodingKeys: String, CodingKey {
    case name
    case displayLabel = "display_label"
  }
}

public struct AnalyticsOperator: Codable, Sendable, Equatable {
  public var name: String
  public var valueType: String

  public init(name: String, valueType: String) {
    self.name = name
    self.valueType = valueType
  }

  enum CodingKeys: String, CodingKey {
    case name
    case valueType = "value_type"
  }
}

public struct AnalyticsGranularity: Codable, Sendable, Equatable {
  public var name: String
  public var displayLabel: String

  public init(name: String, displayLabel: String) {
    self.name = name
    self.displayLabel = displayLabel
  }

  enum CodingKeys: String, CodingKey {
    case name
    case displayLabel = "display_label"
  }
}

public struct AnalyticsQueryResponse: Codable, Sendable, Equatable {
  public var data: AnalyticsQueryResult

  public init(data: AnalyticsQueryResult) {
    self.data = data
  }
}

/// Dynamic row objects retain metric, dimension, and classifier columns. Check metadata.truncated and warnings before using results.
public struct AnalyticsQueryResult: Codable, Sendable, Equatable {
  public var data: [[String: JSONValue]]
  public var metadata: AnalyticsQueryMetadata
  public var cachedAt: Double?
  public var warnings: [String]?

  public init(
    data: [[String: JSONValue]], metadata: AnalyticsQueryMetadata, cachedAt: Double? = nil,
    warnings: [String]? = nil
  ) {
    self.data = data
    self.metadata = metadata
    self.cachedAt = cachedAt
    self.warnings = warnings
  }
}

public struct AnalyticsQueryMetadata: Codable, Sendable, Equatable {
  public var queryTimeMS: Double
  public var rowCount: Int
  public var truncated: Bool

  public init(queryTimeMS: Double, rowCount: Int, truncated: Bool) {
    self.queryTimeMS = queryTimeMS
    self.rowCount = rowCount
    self.truncated = truncated
  }

  enum CodingKeys: String, CodingKey {
    case queryTimeMS = "query_time_ms"
    case rowCount = "row_count"
    case truncated
  }
}
