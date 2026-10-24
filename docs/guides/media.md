---
type: Guide
title: Media APIs
description: Work with speech, transcription, video jobs, and downloads.
tags: [audio, video, transcription, integration-tests]
---

# Media APIs

With a [configured client](../getting-started/quick-start.md):

- `client.audio.speech(_:)` creates speech and returns audio `Data`.
- `client.audio.transcribe(_:)` uploads an `AudioTranscriptionFile` and returns typed text, usage, and the raw response payload.
- `client.videos.create(_:)` creates a job; `client.videos.get(jobId:)` polls it.
- `client.videos.models.list()` discovers video-model capabilities.
- `client.videos.content(_:)` downloads a completed video as buffered `Data` and preserves its response `Content-Type` in `VideoContentResponse`.

**Video downloads buffer the complete file in memory.** For large downloads,
prefer the completed job's unsigned URLs.

## Live video certification smoke test

The full workflow creates provider work, may take up to 10 minutes, and **incurs
provider cost**. It is opt-in and skipped by default, including during normal
`swift test` runs. Run it only with a supported configured model and an
intentional content download:

```bash
OPENROUTER_RUN_INTEGRATION=true \
OPENROUTER_RUN_VIDEO_INTEGRATION=true \
OPENROUTER_RUN_VIDEO_CONTENT_DOWNLOAD=true \
OPENROUTER_API_KEY="<your-key>" \
OPENROUTER_VIDEO_MODEL="<supported-video-model>" \
swift test --filter OpenRouterIntegrationTests/testIntegrationVideoWorkflow
```

Do not put real secrets in committed scripts or shared shell history. For general
test setup see [building and testing](../development/building-and-testing.md).
For media within chat messages, see [multimodal content](multimodal.md).
