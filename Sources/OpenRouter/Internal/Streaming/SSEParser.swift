import Foundation

enum SSEEvent: Equatable {
  case data(String)
  case done
}

struct SSEFrame: Equatable {
  var event: String?
  var id: String?
  var retry: Int?
  var data: String?
}

struct SSEParser {
  static func parse(line: String) -> SSEEvent? {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("data:") else { return nil }
    let payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
    if payload == "[DONE]" {
      return .done
    }
    return .data(payload)
  }

  static func parseFrame(lines: [String]) -> SSEEvent? {
    let frame = parseMetadataFrame(lines: lines)
    guard let payload = frame.data?.trimmingCharacters(in: .whitespacesAndNewlines),
      !payload.isEmpty
    else { return nil }
    if payload == "[DONE]" {
      return .done
    }
    return .data(payload)
  }

  static func parseMetadataFrame(lines: [String]) -> SSEFrame {
    var event: String?
    var id: String?
    var retry: Int?
    var dataLines: [String] = []

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .newlines)
      guard !trimmed.isEmpty, !trimmed.hasPrefix(":") else { continue }

      if trimmed.hasPrefix("data:") {
        dataLines.append(String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces))
      } else if trimmed.hasPrefix("event:") {
        event = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
      } else if trimmed.hasPrefix("id:") {
        id = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
      } else if trimmed.hasPrefix("retry:") {
        retry = Int(String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces))
      }
    }

    return SSEFrame(
      event: event,
      id: id,
      retry: retry,
      data: dataLines.isEmpty ? nil : dataLines.joined(separator: "\n")
    )
  }
}
