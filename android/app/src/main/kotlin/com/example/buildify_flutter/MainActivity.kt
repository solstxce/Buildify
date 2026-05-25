package com.example.buildify_flutter

import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.text.format.Formatter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val channelName = "buildify.ai/server"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startServer" -> {
                        val modelPath = call.argument<String>("modelPath")
                        val port = call.argument<Int>("port") ?: 8080
                        val apiKey = call.argument<String>("apiKey")
                        val idleMinutes = call.argument<Int>("idleMinutes") ?: 0
                        val batteryStopPct = call.argument<Int>("batteryStopPct") ?: 0
                        val thermalStop = call.argument<Boolean>("thermalStop") ?: true
                        if (modelPath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "modelPath is required", null)
                            return@setMethodCallHandler
                        }
                        AiServerService.startService(
                            this,
                            modelPath,
                            port,
                            apiKey = apiKey,
                            idleMinutes = idleMinutes,
                            batteryStopPct = batteryStopPct,
                            thermalStop = thermalStop,
                        )
                        result.success(
                            mapOf(
                                "ok" to true,
                                "status" to AiServerService.currentStatus.name.lowercase(),
                                "port" to AiServerService.currentPort,
                            ),
                        )
                    }

                    "stopServer" -> {
                        AiServerService.stopService(this)
                        result.success(
                            mapOf(
                                "ok" to true,
                                "status" to AiServerService.currentStatus.name.lowercase(),
                            ),
                        )
                    }

                    "getServerStatus" -> {
                        result.success(
                            mapOf(
                                "status" to AiServerService.currentStatus.name.lowercase(),
                                "port" to AiServerService.currentPort,
                                "modelPath" to AiServerService.currentModelPath,
                                "lastError" to AiServerService.lastError,
                                "stopReason" to AiServerService.stopReason,
                            ),
                        )
                    }

                    "getModelBasePath" -> {
                        val dir = File(applicationContext.filesDir, "models")
                        dir.mkdirs()
                        result.success(dir.absolutePath)
                    }

                    "getLocalIp" -> {
                        result.success(getLocalIpAddress())
                    }

                    "startTunnel" -> {
                        val port = call.argument<Int>("port") ?: 8080
                        val tunnelUrl = call.argument<String>("tunnelUrl")
                        CloudflareTunnelService.startTunnel(this, port, tunnelUrl)
                        result.success(
                            mapOf(
                                "ok" to true,
                                "status" to CloudflareTunnelService.currentStatus.name.lowercase(),
                            ),
                        )
                    }

                    "stopTunnel" -> {
                        CloudflareTunnelService.stopTunnel(this)
                        result.success(
                            mapOf(
                                "ok" to true,
                                "status" to CloudflareTunnelService.currentStatus.name.lowercase(),
                            ),
                        )
                    }

                    "getTunnelStatus" -> {
                        result.success(
                            mapOf(
                                "status" to CloudflareTunnelService.currentStatus.name.lowercase(),
                                "publicUrl" to CloudflareTunnelService.lastPublicUrl,
                                "lastError" to CloudflareTunnelService.lastError,
                            ),
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getLocalIpAddress(): String {
        NetworkInterface.getNetworkInterfaces()?.toList()?.forEach { intf ->
            intf.inetAddresses.toList().forEach { address ->
                if (!address.isLoopbackAddress && address is Inet4Address) {
                    return address.hostAddress ?: "0.0.0.0"
                }
            }
        }

        val wifi = applicationContext.getSystemService(WIFI_SERVICE) as? WifiManager
        val ip = wifi?.connectionInfo?.ipAddress ?: 0
        return if (ip != 0) Formatter.formatIpAddress(ip) else "0.0.0.0"
    }
}
