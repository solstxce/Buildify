# Buildify documentation

Index of guides for **Buildify AI Server** (Flutter Android → local LLM HTTP server).

| Doc | What it covers |
|-----|----------------|
| [architecture.md](architecture.md) | End-to-end flow: UI, MethodChannel, service, engine, model |
| [android-llama-engine.md](android-llama-engine.md) | Why jniLibs, `libllama-server.so`, tarball layout, Gradle packaging |
| [models-and-downloads.md](models-and-downloads.md) | GGUF only, curated URLs, `files/models/`, ADB copy tricks |
| [api-and-testing.md](api-and-testing.md) | LAN URLs, Postman, `/health`, `/v1/chat/completions`, response fields |
| [security-and-safety.md](security-and-safety.md) | API key, auto‑stop (idle / battery / thermal), Authorization header |
| [troubleshooting.md](troubleshooting.md) | Common errors (`Permission denied`, missing `.so`, Wi‑Fi) |
| [product-vision.md](product-vision.md) | Goals, constraints (local-only), what we do *not* ship |
| [roadmap.md](roadmap.md) | Implemented vs planned phases |

Project root [README.md](../README.md) has **quick start** and **contributing** (Git workflow, PR checklist).
