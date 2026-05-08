package com.example.buildify_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class AiServerService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val modelPath = intent.getStringExtra(EXTRA_MODEL_PATH) ?: return START_NOT_STICKY
                val port = intent.getIntExtra(EXTRA_PORT, 8080)
                cleanupScheduled.set(false)
                killServerProcess()
                currentModelPath = modelPath
                currentPort = port
                lastError = null
                currentStatus = ServerStatus.STARTING

                startForeground(NOTIFICATION_ID, createNotification(port, ServerStatus.STARTING))

                executor.execute { runLlamaServer(modelPath, port) }
            }

            ACTION_STOP -> {
                killServerProcess()
                currentStatus = ServerStatus.STOPPED
                scheduleServiceStop(this)
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        killServerProcess()
        currentStatus = ServerStatus.STOPPED
        executor.shutdownNow()
        super.onDestroy()
    }

    private fun runLlamaServer(modelPath: String, port: Int) {
        try {
            val install =
                LlamaServerBinary.prepare(this)
                    ?: run {
                        lastError =
                            "Missing llama-server binary. Add assets/binaries/<abi>/llama-server (see assets/binaries/README.txt)."
                        currentStatus = ServerStatus.STOPPED
                        return@runLlamaServer
                    }

            val model = File(modelPath)
            if (!model.exists()) {
                lastError = "Model missing: $modelPath"
                currentStatus = ServerStatus.STOPPED
                return@runLlamaServer
            }

            val cacheDir = File(cacheDir, "llama_cache").apply { mkdirs() }
            val pb =
                ProcessBuilder(
                    install.binary.absolutePath,
                    "-m",
                    model.absolutePath,
                    "--host",
                    "0.0.0.0",
                    "--port",
                    port.toString(),
                )
            pb.directory(install.nativeDir)
            val existingLdPath = System.getenv("LD_LIBRARY_PATH").orEmpty()
            val ldPath =
                if (existingLdPath.isEmpty()) {
                    install.nativeDir.absolutePath
                } else {
                    "${install.nativeDir.absolutePath}:$existingLdPath"
                }
            pb.environment()["LD_LIBRARY_PATH"] = ldPath
            pb.environment()["TMPDIR"] = cacheDir.absolutePath
            pb.redirectErrorStream(true)

            val proc =
                try {
                    pb.start()
                } catch (e: Exception) {
                    Log.e(TAG, "ProcessBuilder.start failed", e)
                    lastError = e.message ?: "failed to start llama-server"
                    currentStatus = ServerStatus.STOPPED
                    return@runLlamaServer
                }

            synchronized(processLock) {
                serverProcess = proc
            }
            currentStatus = ServerStatus.RUNNING
            mainHandler.post {
                val nm = getSystemService(NotificationManager::class.java)
                nm.notify(NOTIFICATION_ID, createNotification(port, ServerStatus.RUNNING))
            }

            val drain =
                Thread {
                    try {
                        proc.inputStream.bufferedReader().forEachLine { line ->
                            Log.i(TAG, line)
                        }
                    } catch (_: Exception) {
                    }
                }
            drain.isDaemon = true
            drain.start()

            val exit = proc.waitFor()
            try {
                drain.join(1500)
            } catch (_: InterruptedException) {
            }

            if (exit != 0 && lastError == null) {
                lastError = "llama-server exited with code $exit"
            }
        } catch (e: Exception) {
            Log.e(TAG, "runLlamaServer failed", e)
            if (lastError == null) {
                lastError = e.message ?: "server error"
            }
        } finally {
            synchronized(processLock) {
                serverProcess = null
            }
            currentStatus = ServerStatus.STOPPED
            scheduleServiceStop(this@AiServerService)
        }
    }

    private fun createNotification(port: Int, status: ServerStatus): Notification {
        createNotificationChannel()
        val openAppIntent = Intent(this, MainActivity::class.java)
        val pendingIntent =
            PendingIntent.getActivity(
                this,
                0,
                openAppIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        val (title, text) =
            when (status) {
                ServerStatus.STARTING -> "AI Server Starting" to "Port $port"
                ServerStatus.RUNNING -> "AI Server Running" to "Port $port · 0.0.0.0"
                else -> "AI Server" to "Port $port"
            }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(status == ServerStatus.RUNNING || status == ServerStatus.STARTING)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "Buildify AI Server",
                NotificationManager.IMPORTANCE_LOW,
            )
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val TAG = "AiServerService"
        private const val ACTION_START = "com.example.buildify_flutter.action.START_AI_SERVER"
        private const val ACTION_STOP = "com.example.buildify_flutter.action.STOP_AI_SERVER"
        private const val EXTRA_MODEL_PATH = "modelPath"
        private const val EXTRA_PORT = "port"
        private const val CHANNEL_ID = "buildify_ai_server_channel"
        private const val NOTIFICATION_ID = 1001

        private val executor = Executors.newSingleThreadExecutor()
        private val processLock = Any()
        private var serverProcess: Process? = null

        private val cleanupScheduled = AtomicBoolean(false)

        @Volatile
        var currentStatus: ServerStatus = ServerStatus.STOPPED
            internal set

        @Volatile
        var currentPort: Int = 8080
            internal set

        @Volatile
        var currentModelPath: String? = null
            internal set

        @Volatile
        var lastError: String? = null
            internal set

        private val mainHandler = Handler(Looper.getMainLooper())

        fun startService(context: Context, modelPath: String, port: Int) {
            val intent =
                Intent(context, AiServerService::class.java).apply {
                    action = ACTION_START
                    putExtra(EXTRA_MODEL_PATH, modelPath)
                    putExtra(EXTRA_PORT, port)
                }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent =
                Intent(context, AiServerService::class.java).apply {
                    action = ACTION_STOP
                }
            context.startService(intent)
        }

        fun killServerProcess() {
            synchronized(processLock) {
                serverProcess?.let { proc ->
                    proc.destroy()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        if (proc.isAlive) {
                            proc.destroyForcibly()
                        }
                    }
                }
                serverProcess = null
            }
        }

        private fun scheduleServiceStop(service: Service) {
            if (!cleanupScheduled.compareAndSet(false, true)) return
            mainHandler.post {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        service.stopForeground(Service.STOP_FOREGROUND_REMOVE)
                    } else {
                        @Suppress("DEPRECATION")
                        service.stopForeground(true)
                    }
                } catch (_: Exception) {
                }
                try {
                    service.stopSelf()
                } catch (_: Exception) {
                }
            }
        }
    }
}

enum class ServerStatus {
    STOPPED,
    STARTING,
    RUNNING,
    STOPPING,
}
