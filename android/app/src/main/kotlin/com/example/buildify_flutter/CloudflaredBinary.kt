package com.example.buildify_flutter

import android.content.Context
import android.os.Build
import android.util.Log
import java.io.File

object CloudflaredBinary {
    private const val TAG = "CloudflaredBinary"
    private const val EXEC_LIB_NAME = "libcloudflared.so"

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
            binary.setExecutable(true, false)
        }
        Log.i(TAG, "Using cloudflared at ${binary.absolutePath}")
        return Install(binary = binary, nativeDir = nativeDir)
    }
}