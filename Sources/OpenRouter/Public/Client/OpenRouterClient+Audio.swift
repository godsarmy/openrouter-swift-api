import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createAudioSpeech(
    _ request: AudioSpeechRequest,
    options: RequestOptions? = nil
  ) async throws -> Data {
    try await transport.postData(
      path: "audio/speech",
      requestBody: request,
      accept: "audio/mpeg, audio/pcm",
      options: options
    )
  }

  public func createAudioTranscriptions(
    _ request: AudioTranscriptionRequest,
    options: RequestOptions? = nil
  ) async throws -> AudioTranscriptionResponse {
    let boundary = "OpenRouterBoundary-\(UUID().uuidString)"
    return try await transport.postMultipart(
      path: "audio/transcriptions",
      body: makeAudioTranscriptionMultipartBody(request, boundary: boundary),
      boundary: boundary,
      responseType: AudioTranscriptionResponse.self,
      options: options
    )
  }

  public var audio: AudioResource { AudioResource(client: self) }

  public struct AudioResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func speech(
      _ request: AudioSpeechRequest,
      options: RequestOptions? = nil
    ) async throws -> Data {
      try await client.createAudioSpeech(request, options: options)
    }

    public func transcribe(
      _ request: AudioTranscriptionRequest,
      options: RequestOptions? = nil
    ) async throws -> AudioTranscriptionResponse {
      try await client.createAudioTranscriptions(request, options: options)
    }
  }
}
