DEPRECATED: do not put llama-server here.

Android 10+ blocks execve() on files extracted from app assets into
the app's writable storage. Use the jniLibs path instead:

  android/app/src/main/jniLibs/arm64-v8a/

See android/app/src/main/jniLibs/arm64-v8a/README.txt
