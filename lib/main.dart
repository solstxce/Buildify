import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ProviderScope(child: BuildifyApp()));
}

class BuildifyApp extends ConsumerWidget {
  const BuildifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buildify AI Server',
      theme: base.copyWith(
        scaffoldBackgroundColor: AppPalette.bg,
        colorScheme: base.colorScheme.copyWith(
          primary: AppPalette.primary,
          secondary: AppPalette.teal,
          surface: AppPalette.surface,
          error: AppPalette.error,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppPalette.bg,
          indicatorColor: AppPalette.primary.withValues(alpha: 0.16),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppPalette.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
      ),
      home: const AiServerShell(),
    );
  }
}

class AppPalette {
  static const bg = Color(0xFF0B0F12);
  static const surface = Color(0xFF121820);
  static const surfaceAlt = Color(0xFF18222D);
  static const border = Color(0xFF263241);
  static const text = Color(0xFFE8EEF2);
  static const muted = Color(0xFF8B99A8);
  static const primary = Color(0xFFFF8A5B);
  static const teal = Color(0xFF54D3B4);
  static const blue = Color(0xFF7AA8FF);
  static const amber = Color(0xFFFFC857);
  static const error = Color(0xFFFF6B6B);
}

final aiServerProvider =
    StateNotifierProvider<AiServerController, AiServerState>((ref) {
      return AiServerController();
    });

enum ServerStatus { stopped, starting, running, stopping }

enum ModelDownloadStatus { notDownloaded, downloading, downloaded }

class ModelProfile {
  const ModelProfile({
    required this.id,
    required this.name,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeLabel,
    required this.speed,
    required this.quality,
    required this.requiredRamGb,
    required this.description,
  });

  final String id;
  final String name;
  final String fileName;
  final String downloadUrl;
  final String sizeLabel;
  final String speed;
  final String quality;
  final int requiredRamGb;
  final String description;
}

class ModelDownload {
  const ModelDownload({required this.status, required this.progress});

  final ModelDownloadStatus status;
  final double progress;

  ModelDownload copyWith({ModelDownloadStatus? status, double? progress}) {
    return ModelDownload(
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

class DeviceSnapshot {
  const DeviceSnapshot({
    required this.ramGb,
    required this.freeStorageGb,
    required this.batteryPercent,
    required this.ipAddress,
    required this.cpuLabel,
  });

  final int ramGb;
  final double freeStorageGb;
  final int batteryPercent;
  final String ipAddress;
  final String cpuLabel;

  DeviceSnapshot copyWith({
    int? ramGb,
    double? freeStorageGb,
    int? batteryPercent,
    String? ipAddress,
    String? cpuLabel,
  }) {
    return DeviceSnapshot(
      ramGb: ramGb ?? this.ramGb,
      freeStorageGb: freeStorageGb ?? this.freeStorageGb,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      ipAddress: ipAddress ?? this.ipAddress,
      cpuLabel: cpuLabel ?? this.cpuLabel,
    );
  }
}

class ServerLog {
  const ServerLog(this.message, this.type);

  final String message;
  final LogType type;
}

enum LogType { system, request, warning }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.createdAt,
  });

  final String text;
  final bool fromUser;
  final DateTime createdAt;
}

class SecuritySettings {
  const SecuritySettings({
    required this.requireApiKey,
    required this.apiKey,
    required this.idleTimeoutMinutes,
    required this.batteryStopPercent,
    required this.thermalStop,
  });

  final bool requireApiKey;
  final String apiKey;
  final int idleTimeoutMinutes;
  final int batteryStopPercent;
  final bool thermalStop;

  static const empty = SecuritySettings(
    requireApiKey: false,
    apiKey: '',
    idleTimeoutMinutes: 0,
    batteryStopPercent: 0,
    thermalStop: true,
  );

  String get maskedApiKey {
    if (apiKey.isEmpty) return '—';
    if (apiKey.length <= 6) return '••••••';
    return '${apiKey.substring(0, 4)}…${apiKey.substring(apiKey.length - 4)}';
  }

  SecuritySettings copyWith({
    bool? requireApiKey,
    String? apiKey,
    int? idleTimeoutMinutes,
    int? batteryStopPercent,
    bool? thermalStop,
  }) {
    return SecuritySettings(
      requireApiKey: requireApiKey ?? this.requireApiKey,
      apiKey: apiKey ?? this.apiKey,
      idleTimeoutMinutes: idleTimeoutMinutes ?? this.idleTimeoutMinutes,
      batteryStopPercent: batteryStopPercent ?? this.batteryStopPercent,
      thermalStop: thermalStop ?? this.thermalStop,
    );
  }
}

class AiServerState {
  const AiServerState({
    required this.models,
    required this.downloads,
    required this.device,
    required this.selectedModelId,
    required this.status,
    required this.port,
    required this.requestCount,
    required this.requestsPerSecond,
    required this.uptime,
    required this.lowPowerMode,
    required this.temperature,
    required this.tokenLimit,
    required this.logs,
    required this.chat,
    required this.security,
  });

  final List<ModelProfile> models;
  final Map<String, ModelDownload> downloads;
  final DeviceSnapshot device;
  final String selectedModelId;
  final ServerStatus status;
  final int port;
  final int requestCount;
  final double requestsPerSecond;
  final Duration uptime;
  final bool lowPowerMode;
  final double temperature;
  final int tokenLimit;
  final List<ServerLog> logs;
  final List<ChatMessage> chat;
  final SecuritySettings security;

  AiServerState copyWith({
    List<ModelProfile>? models,
    Map<String, ModelDownload>? downloads,
    DeviceSnapshot? device,
    String? selectedModelId,
    ServerStatus? status,
    int? port,
    int? requestCount,
    double? requestsPerSecond,
    Duration? uptime,
    bool? lowPowerMode,
    double? temperature,
    int? tokenLimit,
    List<ServerLog>? logs,
    List<ChatMessage>? chat,
    SecuritySettings? security,
  }) {
    return AiServerState(
      models: models ?? this.models,
      downloads: downloads ?? this.downloads,
      device: device ?? this.device,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      status: status ?? this.status,
      port: port ?? this.port,
      requestCount: requestCount ?? this.requestCount,
      requestsPerSecond: requestsPerSecond ?? this.requestsPerSecond,
      uptime: uptime ?? this.uptime,
      lowPowerMode: lowPowerMode ?? this.lowPowerMode,
      temperature: temperature ?? this.temperature,
      tokenLimit: tokenLimit ?? this.tokenLimit,
      logs: logs ?? this.logs,
      chat: chat ?? this.chat,
      security: security ?? this.security,
    );
  }
}

class AiServerController extends StateNotifier<AiServerState> {
  AiServerController()
    : super(
        AiServerState(
          models: _modelCatalog,
          downloads: {
            for (final model in _modelCatalog)
              model.id: const ModelDownload(
                status: ModelDownloadStatus.notDownloaded,
                progress: 0,
              ),
          },
          device: const DeviceSnapshot(
            ramGb: 8,
            freeStorageGb: 43.6,
            batteryPercent: 72,
            ipAddress: '192.168.0.121',
            cpuLabel: '8-core ARM',
          ),
          selectedModelId: _modelCatalog.first.id,
          status: ServerStatus.stopped,
          port: 8080,
          requestCount: 0,
          requestsPerSecond: 0,
          uptime: Duration.zero,
          lowPowerMode: false,
          temperature: 0.7,
          tokenLimit: 100,
          logs: const [
            ServerLog(
              'runtime ready: waiting for model selection',
              LogType.system,
            ),
          ],
          chat: const [],
          security: SecuritySettings.empty,
        ),
      ) {
    unawaited(_hydrateNativeState());
    unawaited(_loadSecuritySettings());
  }

  static const _modelCatalog = [
    ModelProfile(
      id: 'tinyllama-q4',
      name: 'TinyLlama 1.1B Q4',
      fileName: 'tinyllama-1.1b-chat-v1.0-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
      sizeLabel: '~669 MB',
      speed: 'Fast',
      quality: 'Basic',
      requiredRamGb: 4,
      description: 'Small, quick, and practical for low-memory phones.',
    ),
    ModelProfile(
      id: 'qwen2-1_5b-q4',
      name: 'Qwen2 1.5B Q4',
      fileName: 'qwen2-1_5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2-1.5B-Instruct-GGUF/resolve/main/qwen2-1_5b-instruct-q4_k_m.gguf',
      sizeLabel: '~986 MB',
      speed: 'Medium',
      quality: 'Balanced',
      requiredRamGb: 4,
      description: 'Multilingual, balanced quality for short answers.',
    ),
    ModelProfile(
      id: 'phi-3-mini-q4',
      name: 'Phi-3 Mini 4K Q4',
      fileName: 'phi-3-mini-4k-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF/resolve/main/Phi-3-mini-4k-instruct-Q4_K_M.gguf',
      sizeLabel: '~2.4 GB',
      speed: 'Medium',
      quality: 'Reasoning',
      requiredRamGb: 6,
      description: 'Stronger reasoning if the device has enough RAM.',
    ),
  ];

  Timer? _uptimeTimer;
  DateTime? _startedAt;
  final _native = const NativeServerBridge();
  String? _modelBasePath;
  final Map<String, http.Client> _downloadClients = {};
  final Map<String, StreamSubscription<List<int>>> _downloadSubs = {};
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kSecRequire = 'sec_require_api_key';
  static const _kSecApiKey = 'sec_api_key';
  static const _kSecIdleMinutes = 'sec_idle_minutes';
  static const _kSecBatteryPct = 'sec_battery_pct';
  static const _kSecThermal = 'sec_thermal_stop';

  ModelProfile get selectedModel =>
      state.models.firstWhere((model) => model.id == state.selectedModelId);

  String get apiBaseUrl => 'http://${state.device.ipAddress}:${state.port}';

  Future<void> _hydrateNativeState() async {
    final ip = await _native.getLocalIp();
    final base = await _native.getModelBasePath();
    if (base != null && base.isNotEmpty) {
      _modelBasePath = base;
    }
    final status = await _native.getServerStatus();
    if (status != null) {
      state = state.copyWith(
        port: status.port,
        status: _statusFromNative(status.status),
        device: state.device.copyWith(ipAddress: ip ?? state.device.ipAddress),
      );
      _appendLog(
        'native bridge ready: ${status.status} on ${state.device.ipAddress}:${status.port}',
        LogType.system,
      );
      if (status.lastError != null && status.lastError!.isNotEmpty) {
        _appendLog('native: ${status.lastError}', LogType.warning);
      }
    }
    await _scanExistingModels();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final require = (await _secure.read(key: _kSecRequire)) == '1';
      var key = (await _secure.read(key: _kSecApiKey)) ?? '';
      if (key.isEmpty) {
        key = _generateApiKey();
        await _secure.write(key: _kSecApiKey, value: key);
      }
      final idle =
          int.tryParse((await _secure.read(key: _kSecIdleMinutes)) ?? '') ?? 0;
      final battery =
          int.tryParse((await _secure.read(key: _kSecBatteryPct)) ?? '') ?? 0;
      final thermal = (await _secure.read(key: _kSecThermal)) != '0';
      state = state.copyWith(
        security: SecuritySettings(
          requireApiKey: require,
          apiKey: key,
          idleTimeoutMinutes: idle,
          batteryStopPercent: battery,
          thermalStop: thermal,
        ),
      );
      _appendLog(
        'security loaded: '
        'apiKey=${require ? "required" : "off"}, '
        'idle=${idle == 0 ? "off" : "${idle}m"}, '
        'battery=${battery == 0 ? "off" : "$battery%"}, '
        'thermal=${thermal ? "on" : "off"}',
        LogType.system,
      );
    } catch (e) {
      _appendLog('security load failed: $e', LogType.warning);
    }
  }

  String _generateApiKey() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    final buf = StringBuffer('bk_');
    for (var i = 0; i < 32; i++) {
      buf.write(chars[r.nextInt(chars.length)]);
    }
    return buf.toString();
  }

  Future<void> setRequireApiKey(bool value) async {
    state = state.copyWith(security: state.security.copyWith(requireApiKey: value));
    await _secure.write(key: _kSecRequire, value: value ? '1' : '0');
    _appendLog(
      value ? 'api key required for incoming requests' : 'api key disabled',
      LogType.system,
    );
    if (state.status == ServerStatus.running) {
      _appendLog(
        'restart the server to apply api key change',
        LogType.warning,
      );
    }
  }

  Future<void> regenerateApiKey() async {
    final next = _generateApiKey();
    state = state.copyWith(security: state.security.copyWith(apiKey: next));
    await _secure.write(key: _kSecApiKey, value: next);
    _appendLog('new api key generated', LogType.system);
    if (state.status == ServerStatus.running && state.security.requireApiKey) {
      _appendLog('restart the server to apply new key', LogType.warning);
    }
  }

  Future<void> setIdleTimeoutMinutes(int minutes) async {
    final clamped = minutes.clamp(0, 240);
    state = state.copyWith(
      security: state.security.copyWith(idleTimeoutMinutes: clamped),
    );
    await _secure.write(key: _kSecIdleMinutes, value: '$clamped');
  }

  Future<void> setBatteryStopPercent(int pct) async {
    final clamped = pct.clamp(0, 80);
    state = state.copyWith(
      security: state.security.copyWith(batteryStopPercent: clamped),
    );
    await _secure.write(key: _kSecBatteryPct, value: '$clamped');
  }

  Future<void> setThermalStop(bool value) async {
    state = state.copyWith(security: state.security.copyWith(thermalStop: value));
    await _secure.write(key: _kSecThermal, value: value ? '1' : '0');
  }

  Future<void> _scanExistingModels() async {
    final base = _modelBasePath;
    if (base == null || base.isEmpty) return;
    final dir = Directory(base);
    if (!await dir.exists()) return;
    final downloads = {...state.downloads};
    var found = 0;
    for (final m in state.models) {
      final f = File('$base/${m.fileName}');
      if (await f.exists() && (await f.length()) > 1024 * 1024) {
        downloads[m.id] = const ModelDownload(
          status: ModelDownloadStatus.downloaded,
          progress: 1,
        );
        found++;
      }
    }
    if (found > 0) {
      state = state.copyWith(downloads: downloads);
      _appendLog(
        'detected $found existing model file(s) in $base',
        LogType.system,
      );
    }
  }

  void selectModel(String modelId) {
    if (state.status == ServerStatus.running) {
      _appendLog('stop the server before switching models', LogType.warning);
      return;
    }
    state = state.copyWith(selectedModelId: modelId);
    _appendLog('selected model: ${selectedModel.name}', LogType.system);
  }

  Future<void> downloadModel(String modelId) async {
    final current = state.downloads[modelId];
    if (current == null ||
        current.status == ModelDownloadStatus.downloaded ||
        current.status == ModelDownloadStatus.downloading) {
      return;
    }
    final model = state.models.firstWhere((m) => m.id == modelId);

    _modelBasePath ??= await _native.getModelBasePath();
    final base = _modelBasePath;
    if (base == null || base.isEmpty) {
      _appendLog('cannot resolve models directory', LogType.warning);
      return;
    }
    await Directory(base).create(recursive: true);

    final target = File('$base/${model.fileName}');
    if (await target.exists() && (await target.length()) > 1024 * 1024) {
      _setDownload(
        modelId,
        const ModelDownload(
          status: ModelDownloadStatus.downloaded,
          progress: 1,
        ),
      );
      _appendLog('already present: ${model.name}', LogType.system);
      return;
    }
    final part = File('${target.path}.part');
    if (await part.exists()) {
      try {
        await part.delete();
      } catch (_) {}
    }

    _setDownload(
      modelId,
      const ModelDownload(
        status: ModelDownloadStatus.downloading,
        progress: 0.0,
      ),
    );
    _appendLog('download started: ${model.name}', LogType.system);

    final client = http.Client();
    _downloadClients[modelId] = client;

    http.StreamedResponse resp;
    try {
      final req = http.Request('GET', Uri.parse(model.downloadUrl));
      req.followRedirects = true;
      resp = await client.send(req);
    } catch (e) {
      _downloadClients.remove(modelId)?.close();
      _setDownload(
        modelId,
        const ModelDownload(
          status: ModelDownloadStatus.notDownloaded,
          progress: 0,
        ),
      );
      _appendLog('download failed: $e', LogType.warning);
      return;
    }

    if (resp.statusCode != 200) {
      _downloadClients.remove(modelId)?.close();
      _setDownload(
        modelId,
        const ModelDownload(
          status: ModelDownloadStatus.notDownloaded,
          progress: 0,
        ),
      );
      _appendLog(
        'download error HTTP ${resp.statusCode} for ${model.name}',
        LogType.warning,
      );
      return;
    }

    final total = resp.contentLength ?? 0;
    final sink = part.openWrite();
    var received = 0;
    var lastReportedProgress = -1.0;

    final completer = Completer<void>();
    final sub = resp.stream.listen(
      (chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final progress = (received / total).clamp(0.0, 1.0);
          if (progress - lastReportedProgress >= 0.005) {
            lastReportedProgress = progress;
            _setDownload(
              modelId,
              ModelDownload(
                status: ModelDownloadStatus.downloading,
                progress: progress,
              ),
            );
          }
        }
      },
      onDone: () async {
        try {
          await sink.flush();
          await sink.close();
          await part.rename(target.path);
          _setDownload(
            modelId,
            const ModelDownload(
              status: ModelDownloadStatus.downloaded,
              progress: 1,
            ),
          );
          state = state.copyWith(selectedModelId: modelId);
          _appendLog('model ready: ${model.name}', LogType.system);
        } catch (e) {
          _appendLog('finalize failed: $e', LogType.warning);
          _setDownload(
            modelId,
            const ModelDownload(
              status: ModelDownloadStatus.notDownloaded,
              progress: 0,
            ),
          );
        } finally {
          _downloadClients.remove(modelId)?.close();
          _downloadSubs.remove(modelId);
          if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (Object e) async {
        try {
          await sink.close();
        } catch (_) {}
        try {
          if (await part.exists()) await part.delete();
        } catch (_) {}
        _setDownload(
          modelId,
          const ModelDownload(
            status: ModelDownloadStatus.notDownloaded,
            progress: 0,
          ),
        );
        _appendLog('download failed: $e', LogType.warning);
        _downloadClients.remove(modelId)?.close();
        _downloadSubs.remove(modelId);
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    _downloadSubs[modelId] = sub;
    await completer.future;
  }

  Future<void> cancelDownload(String modelId) async {
    final sub = _downloadSubs.remove(modelId);
    final client = _downloadClients.remove(modelId);
    try {
      await sub?.cancel();
    } catch (_) {}
    try {
      client?.close();
    } catch (_) {}
    final base = _modelBasePath;
    if (base != null) {
      final model = state.models.firstWhere(
        (m) => m.id == modelId,
        orElse: () => state.models.first,
      );
      final part = File('$base/${model.fileName}.part');
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
    }
    _setDownload(
      modelId,
      const ModelDownload(
        status: ModelDownloadStatus.notDownloaded,
        progress: 0,
      ),
    );
    _appendLog('download canceled: ${_modelName(modelId)}', LogType.warning);
  }

  Future<void> startServer() async {
    if (state.status == ServerStatus.running ||
        state.status == ServerStatus.starting) {
      return;
    }
    final download = state.downloads[selectedModel.id];
    if (download?.status != ModelDownloadStatus.downloaded) {
      _appendLog(
        'download ${selectedModel.name} before starting',
        LogType.warning,
      );
      return;
    }
    state = state.copyWith(status: ServerStatus.starting);
    _appendLog('loading ${selectedModel.fileName}', LogType.system);
    _modelBasePath ??= await _native.getModelBasePath();
    final sec = state.security;
    final response = await _native.startServer(
      modelPath: _modelPathFor(selectedModel),
      port: state.port,
      apiKey: sec.requireApiKey ? sec.apiKey : null,
      idleMinutes: sec.idleTimeoutMinutes,
      batteryStopPercent: sec.batteryStopPercent,
      thermalStop: sec.thermalStop,
    );
    if (!response.ok) {
      state = state.copyWith(status: ServerStatus.stopped);
      _appendLog('native start failed: ${response.message}', LogType.warning);
      return;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 45));
    NativeServerStatus? live;
    var sawStarting = false;
    var polls = 0;
    while (DateTime.now().isBefore(deadline)) {
      polls++;
      live = await _native.getServerStatus();
      if (live == null) break;
      if (live.status == 'running') break;
      if (live.status == 'starting') {
        sawStarting = true;
      }
      // Fail fast: native often goes starting → stopped (missing binary) before
      // lastError is visible on every device; also stop spinning if stopped persists.
      final err = live.lastError;
      if (live.status == 'stopped' &&
          (sawStarting || (err != null && err.isNotEmpty) || polls >= 8)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    live ??= await _native.getServerStatus();

    if (live == null || live.status != 'running') {
      state = state.copyWith(status: ServerStatus.stopped);
      final err = live?.lastError;
      _appendLog(
        err == null || err.isEmpty
            ? 'server failed to start (check binary, model path, logcat)'
            : err,
        LogType.warning,
      );
      return;
    }

    _startedAt = DateTime.now();
    _uptimeTimer?.cancel();
    var ticks = 0;
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final started = _startedAt;
      if (started == null || state.status != ServerStatus.running) return;
      state = state.copyWith(
        uptime: DateTime.now().difference(started),
        requestsPerSecond: state.requestsPerSecond * 0.6,
      );
      ticks++;
      if (ticks % 5 == 0) {
        final live = await _native.getServerStatus();
        if (live != null &&
            live.status == 'stopped' &&
            state.status == ServerStatus.running) {
          _uptimeTimer?.cancel();
          _startedAt = null;
          state = state.copyWith(
            status: ServerStatus.stopped,
            uptime: Duration.zero,
            requestsPerSecond: 0,
          );
          final reason = live.stopReason;
          _appendLog(
            reason != null && reason.isNotEmpty
                ? 'auto-stop: $reason'
                : (live.lastError ?? 'server stopped unexpectedly'),
            LogType.warning,
          );
        }
      }
    });
    state = state.copyWith(
      status: ServerStatus.running,
      uptime: Duration.zero,
      port: live.port,
    );
    _appendLog('server running on $apiBaseUrl', LogType.system);
  }

  Future<void> stopServer() async {
    if (state.status == ServerStatus.stopped ||
        state.status == ServerStatus.stopping) {
      return;
    }
    state = state.copyWith(status: ServerStatus.stopping);
    final response = await _native.stopServer();
    if (!response.ok) {
      state = state.copyWith(status: ServerStatus.running);
      _appendLog('native stop failed: ${response.message}', LogType.warning);
      return;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    NativeServerStatus? live;
    while (DateTime.now().isBefore(deadline)) {
      live = await _native.getServerStatus();
      if (live == null || live.status == 'stopped') break;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    _uptimeTimer?.cancel();
    _startedAt = null;
    state = state.copyWith(
      status: ServerStatus.stopped,
      uptime: Duration.zero,
      requestsPerSecond: 0,
    );
    _appendLog('server stopped', LogType.system);
  }

  void setLowPowerMode(bool enabled) {
    state = state.copyWith(
      lowPowerMode: enabled,
      tokenLimit: enabled ? 64 : 100,
    );
    _appendLog(
      enabled ? 'low-power mode enabled' : 'low-power mode disabled',
      LogType.system,
    );
  }

  void setTemperature(double value) {
    state = state.copyWith(temperature: value);
  }

  void setTokenLimit(double value) {
    state = state.copyWith(tokenLimit: value.round());
  }

  Future<void> sendPrompt(String prompt) async {
    final cleaned = prompt.trim();
    if (cleaned.isEmpty) return;
    if (state.status != ServerStatus.running) {
      _appendLog('prompt rejected: server is offline', LogType.warning);
      return;
    }

    state = state.copyWith(
      chat: [
        ...state.chat,
        ChatMessage(text: cleaned, fromUser: true, createdAt: DateTime.now()),
      ],
      requestCount: state.requestCount + 1,
      requestsPerSecond: state.requestsPerSecond + 1,
    );

    final port = state.port;
    final maxTokens = state.tokenLimit;
    final temperature = state.temperature;
    final url = Uri.parse('http://127.0.0.1:$port/v1/chat/completions');
    final body = jsonEncode({
      'messages': [
        {'role': 'user', 'content': cleaned},
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
    });

    final stopwatch = Stopwatch()..start();
    String answer;
    final sec = state.security;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (sec.requireApiKey && sec.apiKey.isNotEmpty)
        'Authorization': 'Bearer ${sec.apiKey}',
    };
    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 120));
      stopwatch.stop();

      if (resp.statusCode != 200) {
        _appendLog(
          'POST /v1/chat/completions ${resp.statusCode}',
          LogType.warning,
        );
        answer =
            'HTTP ${resp.statusCode}: '
            '${resp.body.isEmpty ? 'no body' : resp.body}';
      } else {
        _appendLog('POST /v1/chat/completions 200', LogType.request);
        answer = _extractAssistantText(resp.body, fallback: resp.body);
      }
    } on TimeoutException {
      stopwatch.stop();
      _appendLog('chat request timed out', LogType.warning);
      answer = 'Request timed out after 120s. Try a smaller prompt.';
    } catch (e) {
      stopwatch.stop();
      _appendLog('chat request failed: $e', LogType.warning);
      answer = 'Request failed: $e';
    }

    state = state.copyWith(
      chat: [
        ...state.chat,
        ChatMessage(text: answer, fromUser: false, createdAt: DateTime.now()),
      ],
    );
  }

  String _extractAssistantText(
    String responseBody, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final choices = decoded['choices'];
        if (choices is List && choices.isNotEmpty) {
          final first = choices.first;
          if (first is Map<String, dynamic>) {
            final message = first['message'];
            if (message is Map<String, dynamic>) {
              final content = message['content'];
              if (content is String && content.trim().isNotEmpty) {
                return content.trim();
              }
            }
            final text = first['text'];
            if (text is String && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
        final content = decoded['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    } catch (_) {}
    return fallback;
  }

  @override
  void dispose() {
    for (final sub in _downloadSubs.values) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _downloadSubs.clear();
    for (final client in _downloadClients.values) {
      try {
        client.close();
      } catch (_) {}
    }
    _downloadClients.clear();
    _uptimeTimer?.cancel();
    super.dispose();
  }

  void _setDownload(String modelId, ModelDownload download) {
    state = state.copyWith(downloads: {...state.downloads, modelId: download});
  }

  void _appendLog(String message, LogType type) {
    final next = [...state.logs, ServerLog(message, type)];
    state = state.copyWith(
      logs: next.length > 80 ? next.sublist(next.length - 80) : next,
    );
  }

  String _modelName(String modelId) {
    return state.models.firstWhere((model) => model.id == modelId).name;
  }

  String _modelPathFor(ModelProfile model) {
    final base = _modelBasePath;
    if (base == null || base.isEmpty) {
      return model.fileName;
    }
    return '$base/${model.fileName}';
  }

  ServerStatus _statusFromNative(String? nativeStatus) {
    return switch (nativeStatus) {
      'running' => ServerStatus.running,
      'starting' => ServerStatus.starting,
      'stopping' => ServerStatus.stopping,
      _ => ServerStatus.stopped,
    };
  }
}

class NativeServerBridge {
  const NativeServerBridge();

  static const MethodChannel _channel = MethodChannel('buildify.ai/server');

  Future<NativeServerResponse> startServer({
    required String modelPath,
    required int port,
    String? apiKey,
    int idleMinutes = 0,
    int batteryStopPercent = 0,
    bool thermalStop = true,
  }) async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'startServer',
        <String, dynamic>{
          'modelPath': modelPath,
          'port': port,
          if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
          'idleMinutes': idleMinutes,
          'batteryStopPct': batteryStopPercent,
          'thermalStop': thermalStop,
        },
      );
      return NativeServerResponse.fromMap(raw);
    } on PlatformException catch (e) {
      return NativeServerResponse(
        ok: false,
        status: 'stopped',
        message: e.message ?? e.code,
      );
    }
  }

  Future<NativeServerResponse> stopServer() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('stopServer');
      return NativeServerResponse.fromMap(raw);
    } on PlatformException catch (e) {
      return NativeServerResponse(
        ok: false,
        status: 'running',
        message: e.message ?? e.code,
      );
    }
  }

  Future<NativeServerStatus?> getServerStatus() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getServerStatus',
      );
      if (raw == null) return null;
      return NativeServerStatus.fromMap(raw);
    } on PlatformException {
      return null;
    }
  }

  Future<String?> getModelBasePath() async {
    try {
      return await _channel.invokeMethod<String>('getModelBasePath');
    } on PlatformException {
      return null;
    }
  }

  Future<String?> getLocalIp() async {
    try {
      return await _channel.invokeMethod<String>('getLocalIp');
    } on PlatformException {
      return null;
    }
  }
}

class NativeServerResponse {
  const NativeServerResponse({
    required this.ok,
    required this.status,
    this.port,
    this.message,
  });

  final bool ok;
  final String status;
  final int? port;
  final String? message;

  factory NativeServerResponse.fromMap(Map<String, dynamic>? data) {
    return NativeServerResponse(
      ok: data?['ok'] as bool? ?? false,
      status: data?['status'] as String? ?? 'stopped',
      port: data?['port'] as int?,
      message: data?['message'] as String?,
    );
  }
}

class NativeServerStatus {
  const NativeServerStatus({
    required this.status,
    required this.port,
    this.modelPath,
    this.lastError,
    this.stopReason,
  });

  final String status;
  final int port;
  final String? modelPath;
  final String? lastError;
  final String? stopReason;

  factory NativeServerStatus.fromMap(Map<String, dynamic> data) {
    return NativeServerStatus(
      status: data['status'] as String? ?? 'stopped',
      port: data['port'] as int? ?? 8080,
      modelPath: data['modelPath'] as String?,
      lastError: data['lastError'] as String?,
      stopReason: data['stopReason'] as String?,
    );
  }
}

class AiServerShell extends ConsumerStatefulWidget {
  const AiServerShell({super.key});

  @override
  ConsumerState<AiServerShell> createState() => _AiServerShellState();
}

class _AiServerShellState extends ConsumerState<AiServerShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      ModelStoreScreen(),
      SelfTestScreen(),
      NetworkScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.bg,
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.memory, color: AppPalette.primary),
            SizedBox(width: 8),
            Text('Buildify AI'),
          ],
        ),
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (next) => setState(() => index = next),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.storage_outlined),
            selectedIcon: Icon(Icons.storage),
            label: 'Models',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Self test',
          ),
          NavigationDestination(
            icon: Icon(Icons.lan_outlined),
            selectedIcon: Icon(Icons.lan),
            label: 'Network',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiServerProvider);
    final controller = ref.read(aiServerProvider.notifier);
    final selected = state.models.firstWhere(
      (m) => m.id == state.selectedModelId,
    );
    final download = state.downloads[selected.id]!;
    final canStart = download.status == ModelDownloadStatus.downloaded;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ServerStatusPanel(
          state: state,
          selected: selected,
          apiBaseUrl: controller.apiBaseUrl,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    canStart
                        ? () {
                          final ctrl = ref.read(aiServerProvider.notifier);
                          state.status == ServerStatus.running
                              ? unawaited(ctrl.stopServer())
                              : unawaited(ctrl.startServer());
                        }
                        : null,
                icon: Icon(
                  state.status == ServerStatus.running
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  state.status == ServerStatus.running
                      ? 'Stop AI Server'
                      : 'Start AI Server',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Copy API URL',
              onPressed: () => _copyApiUrl(context, controller.apiBaseUrl),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        if (!canStart) ...[
          const SizedBox(height: 8),
          Text(
            'Download the selected model first.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _SectionTitle('Device'),
        const SizedBox(height: 8),
        _DeviceGrid(device: state.device),
        const SizedBox(height: 18),
        _SectionTitle('Selected Model'),
        const SizedBox(height: 8),
        ModelTile(model: selected, download: download, compact: true),
        const SizedBox(height: 18),
        _SectionTitle('Runtime'),
        const SizedBox(height: 8),
        _RuntimeControls(state: state),
        const SizedBox(height: 18),
        const _SectionTitle('Security & Safety'),
        const SizedBox(height: 8),
        const _SecurityCard(),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: _SectionTitle('Logs')),
            IconButton.filledTonal(
              tooltip: 'Copy logs',
              onPressed:
                  state.logs.isEmpty
                      ? null
                      : () => _copyLogs(context, state.logs),
              icon: const Icon(Icons.copy, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LogPanel(logs: state.logs),
      ],
    );
  }
}

class ModelStoreScreen extends ConsumerWidget {
  const ModelStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiServerProvider);
    final controller = ref.read(aiServerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionTitle('Model Store'),
        const SizedBox(height: 8),
        for (final model in state.models) ...[
          ModelTile(
            model: model,
            download: state.downloads[model.id]!,
            selected: state.selectedModelId == model.id,
            onSelect: () => controller.selectModel(model.id),
            onDownload: () => controller.downloadModel(model.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class SelfTestScreen extends ConsumerStatefulWidget {
  const SelfTestScreen({super.key});

  @override
  ConsumerState<SelfTestScreen> createState() => _SelfTestScreenState();
}

class _SelfTestScreenState extends ConsumerState<SelfTestScreen> {
  final input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiServerProvider);
    final running = state.status == ServerStatus.running;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (state.chat.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      running
                          ? 'Self test — calls your running server at '
                              'http://127.0.0.1:${state.port}/v1/chat/completions '
                              '(same API as Postman from your laptop).'
                          : 'Start the AI server, then use this tab to verify it answers.',
                      style: const TextStyle(color: AppPalette.muted),
                    ),
                  ),
                ),
              for (final message in state.chat)
                Align(
                  alignment:
                      message.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          message.fromUser
                              ? AppPalette.primary
                              : AppPalette.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            message.fromUser
                                ? AppPalette.primary
                                : AppPalette.border,
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color:
                            message.fromUser ? AppPalette.bg : AppPalette.text,
                        fontWeight:
                            message.fromUser
                                ? FontWeight.w700
                                : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (_sending)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPalette.teal,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'thinking…',
                          style: TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    enabled: running && !_sending,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          !running
                              ? 'Server offline'
                              : (_sending ? 'Waiting for reply…' : 'Prompt'),
                      filled: true,
                      fillColor: AppPalette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppPalette.border),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send test prompt',
                  onPressed: (running && !_sending) ? _send : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    if (_sending) return;
    final prompt = input.text;
    if (prompt.trim().isEmpty) return;
    input.clear();
    setState(() => _sending = true);
    try {
      await ref.read(aiServerProvider.notifier).sendPrompt(prompt);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiServerProvider);
    final controller = ref.read(aiServerProvider.notifier);
    final baseUrl = controller.apiBaseUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionTitle('Network'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Local IP', value: state.device.ipAddress),
                _InfoRow(label: 'Port', value: '${state.port}'),
                _InfoRow(label: 'Status', value: _statusLabel(state.status)),
                _InfoRow(
                  label: 'Auth',
                  value: state.security.requireApiKey
                      ? 'API key required'
                      : 'Open (no key)',
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: SelectableText(
                    baseUrl,
                    style: const TextStyle(
                      color: AppPalette.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _copyApiUrl(context, baseUrl),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy API URL'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Endpoints'),
        const SizedBox(height: 8),
        const _EndpointTile(method: 'GET', path: '/health'),
        const SizedBox(height: 8),
        const _EndpointTile(method: 'POST', path: '/completion'),
        const SizedBox(height: 8),
        const _EndpointTile(method: 'POST', path: '/chat'),
        const SizedBox(height: 18),
        const _SectionTitle('Example Body'),
        const SizedBox(height: 8),
        const _CodeBlock(
          text:
              '{\n'
              '  "prompt": "Explain quantum physics simply",\n'
              '  "n_predict": 100,\n'
              '  "temperature": 0.7\n'
              '}',
        ),
      ],
    );
  }
}

class _ServerStatusPanel extends StatelessWidget {
  const _ServerStatusPanel({
    required this.state,
    required this.selected,
    required this.apiBaseUrl,
  });

  final AiServerState state;
  final ModelProfile selected;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final running = state.status == ServerStatus.running;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusDot(status: state.status),
                const SizedBox(width: 8),
                Text(
                  _statusTitle(state.status),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Model', value: selected.name),
            _InfoRow(label: 'API', value: running ? apiBaseUrl : 'offline'),
            _InfoRow(label: 'Uptime', value: _formatDuration(state.uptime)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    label: 'Requests',
                    value: '${state.requestCount}',
                    color: AppPalette.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    label: 'RPS',
                    value: state.requestsPerSecond.toStringAsFixed(1),
                    color: AppPalette.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ModelTile extends ConsumerWidget {
  const ModelTile({
    required this.model,
    required this.download,
    this.selected = false,
    this.compact = false,
    this.onSelect,
    this.onDownload,
    super.key,
  });

  final ModelProfile model;
  final ModelDownload download;
  final bool selected;
  final bool compact;
  final VoidCallback? onSelect;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = download.status == ModelDownloadStatus.downloaded;
    final downloading = download.status == ModelDownloadStatus.downloading;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected || compact)
                    const Icon(
                      Icons.check_circle,
                      color: AppPalette.teal,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                model.description,
                style: const TextStyle(color: AppPalette.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(icon: Icons.sd_storage_outlined, label: model.sizeLabel),
                  _Tag(icon: Icons.speed, label: model.speed),
                  _Tag(icon: Icons.auto_awesome, label: model.quality),
                  _Tag(
                    icon: Icons.memory,
                    label: '${model.requiredRamGb}GB RAM',
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 12),
                if (downloading)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: download.progress,
                      minHeight: 8,
                      backgroundColor: AppPalette.border,
                      color: AppPalette.primary,
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSelect,
                          icon: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          label: Text(selected ? 'Selected' : 'Select'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: downloaded ? null : onDownload,
                          icon: Icon(
                            downloaded
                                ? Icons.download_done
                                : Icons.download_outlined,
                          ),
                          label: Text(downloaded ? 'Downloaded' : 'Download'),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RuntimeControls extends ConsumerWidget {
  const _RuntimeControls({required this.state});

  final AiServerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aiServerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              value: state.lowPowerMode,
              onChanged: controller.setLowPowerMode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Low-power mode'),
              secondary: const Icon(Icons.battery_saver),
            ),
            _SliderRow(
              label: 'Token limit',
              valueLabel: '${state.tokenLimit}',
              value: state.tokenLimit.toDouble(),
              min: 32,
              max: 256,
              divisions: 7,
              onChanged: controller.setTokenLimit,
            ),
            _SliderRow(
              label: 'Temperature',
              valueLabel: state.temperature.toStringAsFixed(1),
              value: state.temperature,
              min: 0.1,
              max: 1.2,
              divisions: 11,
              onChanged: controller.setTemperature,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityCard extends ConsumerStatefulWidget {
  const _SecurityCard();

  @override
  ConsumerState<_SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends ConsumerState<_SecurityCard> {
  bool _revealKey = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiServerProvider);
    final controller = ref.read(aiServerProvider.notifier);
    final sec = state.security;
    final running = state.status == ServerStatus.running;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SubSectionTitle(
              icon: Icons.vpn_key_outlined,
              text: 'API key',
            ),
            SwitchListTile(
              value: sec.requireApiKey,
              onChanged: (v) => controller.setRequireApiKey(v),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Require API key'),
              subtitle: const Text(
                'Clients must send Authorization: Bearer <key>',
                style: TextStyle(color: AppPalette.muted, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _revealKey
                          ? (sec.apiKey.isEmpty ? '—' : sec.apiKey)
                          : sec.maskedApiKey,
                      style: const TextStyle(
                        color: AppPalette.teal,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _revealKey ? 'Hide key' : 'Show key',
                    onPressed: sec.apiKey.isEmpty
                        ? null
                        : () => setState(() => _revealKey = !_revealKey),
                    icon: Icon(
                      _revealKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy key',
                    onPressed: sec.apiKey.isEmpty
                        ? null
                        : () => _copyKey(context, sec.apiKey),
                    icon: const Icon(Icons.copy, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Regenerate key',
                    onPressed: () => controller.regenerateApiKey(),
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ],
              ),
            ),
            if (running && sec.requireApiKey) ...[
              const SizedBox(height: 6),
              const Text(
                'Restart the server for key changes to take effect.',
                style: TextStyle(color: AppPalette.amber, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            const _SubSectionTitle(
              icon: Icons.shield_outlined,
              text: 'Auto-stop',
            ),
            _SliderRow(
              label: 'Idle timeout',
              valueLabel:
                  sec.idleTimeoutMinutes == 0 ? 'Off' : '${sec.idleTimeoutMinutes} min',
              value: sec.idleTimeoutMinutes.toDouble(),
              min: 0,
              max: 60,
              divisions: 12,
              onChanged: (v) => controller.setIdleTimeoutMinutes(v.round()),
            ),
            _SliderRow(
              label: 'Stop below battery',
              valueLabel:
                  sec.batteryStopPercent == 0 ? 'Off' : '${sec.batteryStopPercent}%',
              value: sec.batteryStopPercent.toDouble(),
              min: 0,
              max: 50,
              divisions: 10,
              onChanged: (v) => controller.setBatteryStopPercent(v.round()),
            ),
            SwitchListTile(
              value: sec.thermalStop,
              onChanged: (v) => controller.setThermalStop(v),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Stop on thermal warning'),
              subtitle: const Text(
                'Stops the server if the device gets too hot (Android 10+).',
                style: TextStyle(color: AppPalette.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyKey(BuildContext context, String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key copied')),
    );
  }
}

class _SubSectionTitle extends StatelessWidget {
  const _SubSectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.teal),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({required this.device});

  final DeviceSnapshot device;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.25,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _MetricPill(
          label: 'RAM',
          value: '${device.ramGb} GB',
          color: AppPalette.teal,
        ),
        _MetricPill(
          label: 'Storage',
          value: '${device.freeStorageGb.toStringAsFixed(1)} GB',
          color: AppPalette.blue,
        ),
        _MetricPill(
          label: 'Battery',
          value: '${device.batteryPercent}%',
          color: AppPalette.amber,
        ),
        _MetricPill(
          label: 'CPU',
          value: device.cpuLabel,
          color: AppPalette.primary,
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppPalette.muted, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(valueLabel, style: const TextStyle(color: AppPalette.teal)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.logs});

  final List<ServerLog> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Text(
            log.message,
            style: TextStyle(
              color: switch (log.type) {
                LogType.system => AppPalette.muted,
                LogType.request => AppPalette.teal,
                LogType.warning => AppPalette.amber,
              },
              fontSize: 12,
              height: 1.35,
            ),
          );
        },
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.method, required this.path});

  final String method;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: method == 'GET' ? AppPalette.blue : AppPalette.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            method,
            style: const TextStyle(
              color: AppPalette.bg,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(path, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          color: AppPalette.text,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.muted),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final ServerStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ServerStatus.running => AppPalette.teal,
      ServerStatus.starting => AppPalette.amber,
      ServerStatus.stopping => AppPalette.amber,
      ServerStatus.stopped => AppPalette.error,
    };
    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(label, style: const TextStyle(color: AppPalette.muted)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppPalette.text,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _statusTitle(ServerStatus status) {
  return switch (status) {
    ServerStatus.stopped => 'Server Stopped',
    ServerStatus.starting => 'Starting Server',
    ServerStatus.running => 'Server Running',
    ServerStatus.stopping => 'Stopping Server',
  };
}

String _statusLabel(ServerStatus status) {
  return switch (status) {
    ServerStatus.stopped => 'stopped',
    ServerStatus.starting => 'starting',
    ServerStatus.running => 'running',
    ServerStatus.stopping => 'stopping',
  };
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

void _copyApiUrl(BuildContext context, String baseUrl) {
  unawaited(Clipboard.setData(ClipboardData(text: baseUrl)));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('API URL copied')));
}

void _copyLogs(BuildContext context, List<ServerLog> logs) {
  if (logs.isEmpty) return;
  final text = logs.map((l) => '[${l.type.name}] ${l.message}').join('\n');
  unawaited(Clipboard.setData(ClipboardData(text: text)));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Logs copied')));
}
