package com.example.buildify_flutter

import android.content.Context
import android.util.Log
import java.io.File

/**
 * Resolves the bundled `llama-server` binary location.
 *
 * Why jniLibs and not assets:
 *   Android (10+) blocks execve() on files inside an app's writable storage.
 *   Files shipped under jniLibs/<abi>/ are extracted by the package manager
 *   into [ApplicationInfo.nativeLibraryDir], which IS allowed to execute.
 *
 * Required layout (drop the contents of llama.cpp android-arm64 release here):
 *   android/app/src/main/jniLibs/arm64-v8a/libllama-server.so   (the executable)
 *   android/app/src/main/jniLibs/arm64-v8a/libllama.so
 *   android/app/src/main/jniLibs/arm64-v8a/libllama-common.so
 *   android/app/src/main/jniLibs/arm64-v8a/libggml.so
 *   android/app/src/main/jniLibs/arm64-v8a/libggml-base.so
 *   android/app/src/main/jniLibs/arm64-v8a/libggml-cpu-android_armv8.0_1.so
 *   android/app/src/main/jniLibs/arm64-v8a/libggml-cpu-android_armv8.2_1.so
 *   ... (all CPU variants and any other libs the build needs)
 *
 * Filenames MUST start with `lib` and end with `.so` for the packager to ship
 * them and Android to extract them at install time.
 */
object LlamaServerBinary {
    private const val TAG = "LlamaServerBinary"
    private const val EXEC_LIB_NAME = "libllama-server.so"

    data class Install(val binary: File, val nativeDir: File)

    fun prepare(context: Context): Install? {
        val nativeDirPath = context.applicationInfo.nativeLibraryDir
        if (nativeDirPath.isNullOrEmpty()) {
            Log.e(TAG, "applicationInfo.nativeLibraryDir is null/empty")
            return null
        }
        val nativeDir = File(nativeDirPath)
        val binary = File(nativeDir, EXEC_LIB_NAME)
        if (!binary.exists()) {
            Log.e(TAG, "Missing $EXEC_LIB_NAME in $nativeDirPath")
            return null
        }
        if (!binary.canExecute()) {
            // Best-effort, but native lib dir is already exec-allowed.
            binary.setExecutable(true, false)
        }
        Log.i(TAG, "Using llama-server at ${binary.absolutePath}")
        return Install(binary = binary, nativeDir = nativeDir)
    }
}
