Buildify AI Server — bundled native binaries (Android armeabi-v7a / arm32)

This folder holds the 32-bit ARM variants of native executables for
devices running on older ARMv7 SoCs.

Required files:
  libcloudflared.so    (Cloudflare tunnel client for Android arm32)

Notes:
  - Filenames MUST start with "lib" and end with ".so" for Android's
    package manager to extract them into ApplicationInfo.nativeLibraryDir.
  - The llama.cpp engine is currently only shipped for arm64-v8a.
    32-bit devices can still use the Cloudflare tunnel client from this
    folder but cannot run the local LLM server.
  - cloudflared for arm32 must be built with CGO_ENABLED=1 using the
    Android NDK toolchain (armv7a-linux-androideabi21-clang).