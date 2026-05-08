Buildify AI Server — bundled llama-server (Android arm64)

Why this folder (and not assets/):
  Android 10+ refuses to execute files from app writable storage
  (W^X + SELinux). Files shipped under jniLibs/<abi>/ are extracted
  by the package manager into ApplicationInfo.nativeLibraryDir at
  install time, which IS allowed to execute.

Required files in this folder:
  libllama-server.so          (renamed from llama.cpp's "llama-server")
  libllama.so
  libllama-common.so
  libggml.so
  libggml-base.so
  libggml-cpu-android_armv8.0_1.so
  libggml-cpu-android_armv8.2_1.so
  libggml-cpu-android_armv8.2_2.so
  libggml-cpu-android_armv8.6_1.so
  libggml-cpu-android_armv9.0_1.so
  libggml-cpu-android_armv9.2_1.so
  libggml-cpu-android_armv9.2_2.so
  libggml-rpc.so       (optional but small, keep)
  libmtmd.so           (optional, only for multimodal models)
  LICENSE              (keep for legal)

Quick copy script (PowerShell, edit $src to match your tarball folder):

  $src = "C:\Users\navad\Buildify\llama-b9075"
  $dst = "C:\Users\navad\Buildify\android\app\src\main\jniLibs\arm64-v8a"
  New-Item -ItemType Directory -Force -Path $dst | Out-Null

  # The executable -> rename to libllama-server.so
  Copy-Item -Force (Join-Path $src "llama-server") `
            -Destination (Join-Path $dst "libllama-server.so")

  # All the .so files
  $libs = @(
    "libllama.so","libllama-common.so","libggml.so","libggml-base.so",
    "libggml-cpu-android_armv8.0_1.so","libggml-cpu-android_armv8.2_1.so",
    "libggml-cpu-android_armv8.2_2.so","libggml-cpu-android_armv8.6_1.so",
    "libggml-cpu-android_armv9.0_1.so","libggml-cpu-android_armv9.2_1.so",
    "libggml-cpu-android_armv9.2_2.so","libggml-rpc.so","libmtmd.so",
    "LICENSE"
  )
  foreach ($f in $libs) { Copy-Item -Force (Join-Path $src $f) -Destination $dst }

After updating these files, fully rebuild the APK (flutter run).

The app:
  1. Resolves nativeLibraryDir at runtime.
  2. Launches:  libllama-server.so -m <model.gguf> --host 0.0.0.0 --port <port>
  3. Sets LD_LIBRARY_PATH to nativeLibraryDir so the .so files are found.
