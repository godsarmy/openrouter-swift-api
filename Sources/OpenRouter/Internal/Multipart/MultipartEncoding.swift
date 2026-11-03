import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  func makeAudioTranscriptionMultipartBody(
    _ request: AudioTranscriptionRequest, boundary: String
  ) -> Data {
    var body = Data()
    func append(_ value: String) { body.append(contentsOf: value.utf8) }
    func field(_ name: String, _ value: String) {
      append(
        "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n")
    }
    let filename = sanitizeMultipartFilename(request.file.filename)
    append("--\(boundary)\r\n")
    append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
    append("Content-Type: \(request.file.mediaType ?? "application/octet-stream")\r\n\r\n")
    body.append(request.file.data)
    append("\r\n")
    field("model", request.model)
    if let language = request.language { field("language", language) }
    if let temperature = request.temperature { field("temperature", String(temperature)) }
    if let responseFormat = request.responseFormat {
      field("response_format", responseFormat.rawValue)
    }
    for granularity in request.timestampGranularities ?? [] {
      field("timestamp_granularities[]", granularity.rawValue)
    }
    if let prompt = request.prompt { field("prompt", prompt) }
    append("--\(boundary)--\r\n")
    return body
  }

  func makeFileUploadMultipartBody(_ file: FileUpload, boundary: String) -> Data {
    var body = Data()
    func append(_ value: String) { body.append(contentsOf: value.utf8) }
    append("--\(boundary)\r\n")
    append(
      "Content-Disposition: form-data; name=\"file\"; filename=\"\(sanitizeMultipartFilename(file.filename))\"\r\n"
    )
    append("Content-Type: \(file.mediaType ?? "application/octet-stream")\r\n\r\n")
    body.append(file.data)
    append("\r\n--\(boundary)--\r\n")
    return body
  }

  private func sanitizeMultipartFilename(_ filename: String) -> String {
    filename
      .replacingOccurrences(of: "\"", with: "%22")
      .replacingOccurrences(of: "\r", with: "")
      .replacingOccurrences(of: "\n", with: "")
  }
}
