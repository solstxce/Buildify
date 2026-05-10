# Roadmap (reference)

Rough phases discussed during development. Status is indicative — check the codebase for truth.

| Phase | Topic | Status |
|-------|--------|--------|
| 1 | Flutter ↔ Kotlin MethodChannel (`buildify.ai/server`) | Done |
| 2 | Foreground service, notification, status | Done |
| 3 | Run llama.cpp server on device | Done (jniLibs + `libllama-server.so`) |
| 4 | Real GGUF download + progress + verify | Done (HTTP stream in `lib/main.dart`) |
| 5 | JNI / `libllama.so` in-process (performance) | Not started |
| — | Chat tab calls real HTTP instead of simulated text | Done (Self test tab) |
| — | API key for LAN (`Authorization: Bearer …`) | Done (`docs/security-and-safety.md`) |
| — | Idle / thermal / battery auto-stop | Done (`docs/security-and-safety.md`) |
| — | Wi‑Fi-only download toggle | Optional |
| — | Rate limiting / per-client keys | Optional |
| — | QR code for base URL | Optional |

## Native binary source of truth

- Prefer **official** [llama.cpp Android arm64 release tarball](https://github.com/ggml-org/llama.cpp/releases).
- Document exact copy list in `android/app/src/main/jniLibs/arm64-v8a/README.txt`.
