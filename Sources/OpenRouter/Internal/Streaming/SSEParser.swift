import Foundation

enum SSEEvent: Equatable {
  case data(String)
  case done
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
}
