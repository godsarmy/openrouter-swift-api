---
type: Guide
title: Multimodal content
description: Represent text, image, file, and audio message parts.
tags: [chat, multimodal, images, audio, files]
---

# Multimodal content

The SDK supports simple and object-based multimodal chat payloads.

## Content forms

- Simple text: `Content.text("hello")`
- Multipart text: `.text("hello")`
- Prompt-cached text: `.textWithCache(text: "long context", cacheControl: .init(type: "ephemeral", ttl: "5m"))`
- Image URL: `.imageURL("https://example.com/image.png")`
- Detail-aware image: `.image(.init(url: "https://example.com/image.png", detail: "high"))`
- File URL: `.fileURL("https://example.com/file.pdf")`
- File-parser object: `.file(.init(filename: "paper.pdf", fileData: "<base64>"))`
- Audio input: `.inputAudio(.init(data: "<base64>", format: "wav"))`

## Examples

```swift
let message = ChatMessage(
  role: .user,
  content: .parts([
    .text("Describe this image and PDF"),
    .image(.init(url: "https://example.com/image.png", detail: "high")),
    .file(.init(filename: "paper.pdf", fileData: "<base64>")),
    .inputAudio(.init(data: "<base64>", format: "wav")),
  ])
)
```

Pass the message in a [chat request](chat.md) with a model that supports the
selected modalities. For dedicated speech, transcription, and video endpoints,
see [media APIs](media.md).
