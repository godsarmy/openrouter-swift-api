import XCTest

@testable import OpenRouter

final class OpenRouterModelsTests: XCTestCase {
  func testChatCompletionRequestRoundTripWithMultimodalContent() throws {
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o-mini",
      messages: [
        .system("You are helpful."),
        .init(
          role: .user,
          content: .parts([
            .text("Describe this image"),
            .imageURL("https://example.com/image.png"),
            .fileURL("https://example.com/file.pdf"),
          ])
        ),
      ],
      stream: true,
      tools: [
        .init(
          function: .init(
            name: "get_weather",
            description: "Get weather",
            parameters: .object([
              "type": .string("object"),
              "properties": .object([
                "location": .object([
                  "type": .string("string")
                ])
              ]),
            ])
          )
        )
      ],
      toolChoice: .function(name: "get_weather"),
      responseFormat: .init(
        type: "json_schema",
        jsonSchema: .init(
          name: "weather",
          strict: true,
          schema: .object([
            "type": .string("object")
          ])
        )
      )
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(request)
    let decoded = try decoder.decode(ChatCompletionRequest.self, from: data)

    XCTAssertEqual(decoded, request)
  }

  func testContentDecodesFromStringAndArray() throws {
    let stringJSON = "\"hello\"".data(using: .utf8)!
    let arrJSON = "[{\"type\":\"text\",\"text\":\"hello\"}]".data(using: .utf8)!

    let decoder = JSONDecoder()
    XCTAssertEqual(try decoder.decode(Content.self, from: stringJSON), .text("hello"))
    XCTAssertEqual(try decoder.decode(Content.self, from: arrJSON), .parts([.text("hello")]))
  }

  func testEmbeddingInputRoundTrip() throws {
    let request = EmbeddingRequest(model: "text-embedding-3-small", input: .strings(["a", "b"]))
    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(EmbeddingRequest.self, from: data)
    XCTAssertEqual(decoded, request)
  }
}
