# Changelog

All notable changes to this package will be documented in this file.

This project follows semantic versioning once public releases are tagged.

## 0.3.0 - 2026-08-13

- Added model detail, model count, and user-filtered model discovery APIs.
- Added file uploads with optional workspace targeting.
- Added user activity analytics and daily model-ranking datasets.
- Added current-key metadata and complete management API-key CRUD support.
- Added authorization-code creation with optional PKCE and redacted credential descriptions.
- Added reusable typed PATCH and DELETE transport support with safe dynamic path escaping.
- Improved request-body handling and cross-platform macOS/Linux test coverage.

## 0.2.0 - 2026-07-27

- Added Anthropic-compatible Messages creation and SSE streaming APIs.
- Expanded the beta Responses API with typed/raw events, function tools, stateless function-call/output replay, and reasoning replay support.
- Added reranking and embedding-model discovery APIs.
- Added audio speech synthesis and multipart audio transcription APIs.
- Added the complete video workflow: job creation, polling, buffered content download with Content-Type, and video-model capability discovery.

## 0.1.0-rc.1

- Initial release candidate for core OpenRouter Swift SDK functionality.
- Includes chat completions, streaming chat, embeddings, completions, generations, models, credits, providers, and endpoints.
- Includes reasoning, tool calling, structured output, prompt caching, response caching, web search, multimodal content, usage/cost fields, fallback routing, retries, request options, and typed API error mapping.
- Excludes beta Responses API pending compatibility confirmation.
