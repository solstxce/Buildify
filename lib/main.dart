import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'backend/cloudflare_service.dart';
import 'backend/embedded_backend.dart';

void main() {
  runApp(const ProviderScope(child: BuildifyApp()));
}

class BuildifyPalette {
  static const bg = Color(0xFF0D0D0D);
  static const surface = Color(0xFF111111);
  static const text = Color(0xFFE8E2D9);
  static const primary = Color(0xFFDF795E);
  static const success = Color(0xFF7EC8A4);
  static const error = Color(0xFFE2704A);
  static const muted = Color(0xFF666666);
  static const border = Color(0xFF222222);
}

final embeddedBackendProvider = Provider<EmbeddedBackendService>((ref) {
  final service = EmbeddedBackendService();
  unawaited(service.devLogin(userName: 'user'));
  ref.onDispose(service.dispose);
  return service;
});

final cloudflareServiceProvider = Provider<CloudflareService>((ref) {
  return CloudflareService();
});

final serverProvider = StateNotifierProvider<ServerController, ServerState>((
  ref,
) {
  final backend = ref.watch(embeddedBackendProvider);
  return ServerController(backend);
});

class ServerState {
  const ServerState({
    required this.isRunning,
    required this.requestCount,
    required this.rps,
    required this.publicUrl,
    required this.uptime,
    required this.lowBattery,
    required this.tunnelProvider,
    required this.logs,
    required this.projects,
    this.activeProjectId,
    required this.userName,
    this.statusMessage,
  });

  final bool isRunning;
  final int requestCount;
  final double rps;
  final String publicUrl;
  final Duration uptime;
  final bool lowBattery;
  final String tunnelProvider;
  final List<LogLine> logs;
  final List<BackendProject> projects;
  final String? activeProjectId;
  final String userName;
  final String? statusMessage;

  ServerState copyWith({
    bool? isRunning,
    int? requestCount,
    double? rps,
    String? publicUrl,
    Duration? uptime,
    bool? lowBattery,
    String? tunnelProvider,
    List<LogLine>? logs,
    List<BackendProject>? projects,
    String? activeProjectId,
    String? userName,
    String? statusMessage,
  }) {
    return ServerState(
      isRunning: isRunning ?? this.isRunning,
      requestCount: requestCount ?? this.requestCount,
      rps: rps ?? this.rps,
      publicUrl: publicUrl ?? this.publicUrl,
      uptime: uptime ?? this.uptime,
      lowBattery: lowBattery ?? this.lowBattery,
      tunnelProvider: tunnelProvider ?? this.tunnelProvider,
      logs: logs ?? this.logs,
      projects: projects ?? this.projects,
      activeProjectId: activeProjectId ?? this.activeProjectId,
      userName: userName ?? this.userName,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

enum LogType { request, error, system }

class LogLine {
  const LogLine({required this.text, required this.type});
  final String text;
  final LogType type;
}

class ServerController extends StateNotifier<ServerState> {
  ServerController(this._backend)
    : super(
        const ServerState(
          isRunning: false,
          requestCount: 0,
          rps: 0,
          publicUrl: 'https://myproject.buildify.app',
          uptime: Duration.zero,
          lowBattery: false,
          tunnelProvider: 'cloudflare',
          logs: [LogLine(text: '-- buildify booted --', type: LogType.system)],
          projects: [],
          activeProjectId: null,
          userName: 'user',
          statusMessage: 'idle',
        ),
      ) {
    _syncSubscription = _backend.stream.listen(_syncFromBackend);
    _syncFromBackend(_backend.state);
  }

  final EmbeddedBackendService _backend;
  StreamSubscription<BackendState>? _syncSubscription;

  void startServer() {
    final projectId =
        state.activeProjectId ??
        (state.projects.isNotEmpty ? state.projects.first.id : null);
    if (projectId == null) return;
    unawaited(_backend.startSession(projectId: projectId));
  }

  void stopServer() {
    final sessionId = _backend.state.activeSession?.id;
    if (sessionId == null) return;
    unawaited(_backend.stopSession(sessionId: sessionId));
  }

  Future<void> importProjectAndStart({
    required String sourceType,
    required bool zipChosen,
  }) async {
    final projectName =
        zipChosen
            ? 'zip-site-${state.projects.length + 1}'
            : '$sourceType-site-${state.projects.length + 1}';
    final project = await _backend.createProject(
      name: projectName,
      sourceType: sourceType,
    );
    await _backend.createDeployment(
      projectId: project.id,
      framework: 'plain html',
      sourceType: zipChosen ? 'zip upload' : sourceType,
    );
    await _backend.startSession(projectId: project.id);
  }

  Future<String> deployProjectWithConfig({
    required String sourceType,
    required String projectName,
    required String domain,
    String? subdomain,
    required String branch,
    required String baseDirectory,
    required String buildCommand,
    required String publishDirectory,
    required String functionsDirectory,
    required String selectedPath,
    required Map<String, String> envVars,
  }) async {
    final fallbackName = 'site-${state.projects.length + 1}';
    final cleanedName =
        projectName.trim().isEmpty ? fallbackName : projectName.trim();
    final rawSubdomain = (subdomain ?? cleanedName)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final slug =
        rawSubdomain.isEmpty
            ? _backend.generateRandomSubdomain()
            : rawSubdomain;
    final cleanDomain = domain.trim().isEmpty ? 'buildify.app' : domain.trim();
    final deployUrl = 'https://$slug.$cleanDomain';

    final project = await _backend.createProject(
      name: cleanedName,
      sourceType: sourceType,
      customUrl: deployUrl,
    );
    await _backend.createDeployment(
      projectId: project.id,
      framework: 'plain html',
      sourceType: sourceType,
    );
    await _backend.startSession(
      projectId: project.id,
      publicUrl: deployUrl,
      tunnelProvider: 'cloudflare',
    );
    return deployUrl;
  }

  String suggestRandomSubdomain() => _backend.generateRandomSubdomain();

  BackendProject? resolveHostMapping(String hostname) {
    return _backend.resolveHostname(hostname);
  }

  void _syncFromBackend(BackendState backendState) {
    final session = backendState.activeSession;
    final mappedLogs = backendState.logs
        .map(
          (e) => LogLine(
            text: e.message,
            type: switch (e.type) {
              BackendLogType.request => LogType.request,
              BackendLogType.error => LogType.error,
              BackendLogType.system => LogType.system,
            },
          ),
        )
        .toList(growable: false);
    final uptime =
        session == null
            ? Duration.zero
            : DateTime.now().difference(session.startedAt);
    state = state.copyWith(
      isRunning: session?.isRunning ?? false,
      requestCount: session?.requestCount ?? 0,
      rps: session?.rps ?? 0,
      publicUrl:
          session?.publicUrl ??
          (backendState.projects.isNotEmpty
              ? backendState.projects.first.url
              : 'https://myproject.buildify.app'),
      uptime: uptime,
      lowBattery: session?.lowBattery ?? false,
      tunnelProvider: session?.tunnelProvider ?? 'cloudflare',
      logs: mappedLogs,
      projects: backendState.projects,
      activeProjectId:
          session?.projectId ??
          (backendState.projects.isNotEmpty
              ? backendState.projects.first.id
              : null),
      userName: backendState.userName,
      statusMessage: session == null ? 'idle' : 'your site is live.',
    );
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}

class BuildifyApp extends ConsumerWidget {
  const BuildifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.spaceMonoTextTheme(base.textTheme).apply(
      bodyColor: BuildifyPalette.text,
      displayColor: BuildifyPalette.text,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'buildify',
      theme: base.copyWith(
        scaffoldBackgroundColor: BuildifyPalette.bg,
        textTheme: textTheme,
        colorScheme: base.colorScheme.copyWith(
          primary: BuildifyPalette.primary,
          secondary: BuildifyPalette.success,
          surface: BuildifyPalette.surface,
          error: BuildifyPalette.error,
        ),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/import',
      builder: (context, state) => const ImportProjectScreen(),
    ),
    GoRoute(
      path: '/deploy-config',
      builder: (context, state) {
        final args = state.extra! as DeployConfigArgs;
        return DeployConfigScreen(args: args);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) => ShellScaffold(shell: navShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (c, s) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/deploy',
              builder: (c, s) => const DeployWizardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/logs', builder: (c, s) => const LogsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/domains', builder: (c, s) => const DomainsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (c, s) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: BuildifyPalette.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                'Bd',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: BuildifyPalette.bg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'buildify',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BuildifyPalette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 2, width: 240, color: BuildifyPalette.primary),
            const SizedBox(height: 10),
            Text(
              'your phone. your server. go live.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: BuildifyPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'sign in to buildify',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'deploy from anywhere',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: BuildifyPalette.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: BuildifyPalette.primary,
              ),
              child: const Text('continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      floatingActionButton:
          shell.currentIndex == 0
              ? FloatingActionButton(
                onPressed: () {
                  context.push('/import');
                },
                backgroundColor: BuildifyPalette.primary,
                foregroundColor: BuildifyPalette.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: BuildifyPalette.bg),
                ),
                child: const Icon(Icons.add),
              )
              : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: BuildifyPalette.bg,
        indicatorColor: BuildifyPalette.primary.withValues(alpha: 0.18),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'home'),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            label: 'deploy',
          ),
          NavigationDestination(icon: Icon(Icons.terminal), label: 'logs'),
          NavigationDestination(
            icon: Icon(Icons.language_outlined),
            label: 'domains',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'settings',
          ),
        ],
      ),
    );
  }
}

class ImportProjectScreen extends ConsumerStatefulWidget {
  const ImportProjectScreen({super.key});

  @override
  ConsumerState<ImportProjectScreen> createState() =>
      _ImportProjectScreenState();
}

class _ImportProjectScreenState extends ConsumerState<ImportProjectScreen> {
  String? selectedProvider;
  bool zipChosen = false;
  String? selectedFolderPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuildifyPalette.bg,
      appBar: AppBar(
        backgroundColor: BuildifyPalette.surface,
        foregroundColor: BuildifyPalette.text,
        title: Row(
          children: [
            const Icon(
              Icons.terminal,
              color: BuildifyPalette.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'buildify',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: BuildifyPalette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: BuildifyPalette.bg,
                border: Border.all(color: const Color(0xFF555555)),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          const Text(
            'step 1 of 2',
            style: TextStyle(fontSize: 14, color: Color(0xFF55423E)),
          ),
          const SizedBox(height: 6),
          Text(
            'connect to git',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _providerButton(
            icon: Icons.code,
            label: 'github',
            selected: selectedProvider == 'github',
            onTap: () => setState(() => selectedProvider = 'github'),
          ),
          const SizedBox(height: 10),
          _providerButton(
            icon: Icons.api,
            label: 'gitlab',
            selected: selectedProvider == 'gitlab',
            onTap: () => setState(() => selectedProvider = 'gitlab'),
          ),
          const SizedBox(height: 10),
          _providerButton(
            icon: Icons.integration_instructions,
            label: 'bitbucket',
            selected: selectedProvider == 'bitbucket',
            onTap: () => setState(() => selectedProvider = 'bitbucket'),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFF555555))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('or', style: TextStyle(color: Color(0xFF55423E))),
              ),
              Expanded(child: Divider(color: Color(0xFF555555))),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: _pickFolderForUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 14),
              decoration: BoxDecoration(
                color: BuildifyPalette.surface,
                border: Border.all(
                  color:
                      zipChosen
                          ? BuildifyPalette.primary
                          : const Color(0xFF555555),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.folder, size: 34, color: Color(0xFFA38B86)),
                  const SizedBox(height: 8),
                  const Text('upload zip file', style: TextStyle(fontSize: 16)),
                  Text(
                    zipChosen
                        ? 'folder selected: ${_lastPathPart(selectedFolderPath ?? '')}'
                        : 'drag and drop or click to browse folder',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF55423E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _goToDeployConfig,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: BuildifyPalette.primary,
              foregroundColor: BuildifyPalette.bg,
            ),
            child: const Text('continue'),
          ),
        ],
      ),
    );
  }

  Widget _providerButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        alignment: Alignment.centerLeft,
        side: BorderSide(
          color: selected ? BuildifyPalette.primary : const Color(0xFF555555),
        ),
        backgroundColor: BuildifyPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BuildifyPalette.text),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: BuildifyPalette.text, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFolderForUpload() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'select project folder',
      );
      if (path == null || path.isEmpty) return;
      setState(() {
        zipChosen = true;
        selectedFolderPath = path;
      });
    } on MissingPluginException {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final filePath = picked.files.single.path ?? picked.files.single.name;
      setState(() {
        zipChosen = true;
        selectedFolderPath = filePath;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('folder picker unavailable, selected zip file instead'),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('file picker error: ${e.message ?? e.code}')),
      );
    }
  }

  void _goToDeployConfig() {
    if (selectedProvider == null && !zipChosen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('select git provider or upload zip first'),
        ),
      );
      return;
    }
    final args = DeployConfigArgs(
      sourceType: selectedProvider ?? 'zip upload',
      selectedPath: selectedFolderPath ?? '',
      suggestedProjectName:
          selectedFolderPath != null && selectedFolderPath!.isNotEmpty
              ? _lastPathPart(selectedFolderPath!)
              : 'my-project',
    );
    context.push('/deploy-config', extra: args);
  }

  String _lastPathPart(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }
}

class DeployConfigArgs {
  const DeployConfigArgs({
    required this.sourceType,
    required this.selectedPath,
    required this.suggestedProjectName,
  });

  final String sourceType;
  final String selectedPath;
  final String suggestedProjectName;
}

class DeployConfigScreen extends ConsumerStatefulWidget {
  const DeployConfigScreen({required this.args, super.key});
  final DeployConfigArgs args;

  @override
  ConsumerState<DeployConfigScreen> createState() => _DeployConfigScreenState();
}

class _DeployConfigScreenState extends ConsumerState<DeployConfigScreen> {
  final _teamCtrl = TextEditingController(text: 'IDK');
  final _projectCtrl = TextEditingController();
  final _branchCtrl = TextEditingController(text: 'main');
  final _baseCtrl = TextEditingController();
  final _buildCtrl = TextEditingController();
  final _publishCtrl = TextEditingController(text: 'dist');
  final _functionsCtrl = TextEditingController(text: 'netlify/functions');
  final _envCtrl = TextEditingController();
  final _domainCtrl = TextEditingController();
  final _zoneIdCtrl = TextEditingController();
  final _apiTokenCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: 'example.trycloudflare.com');
  final _subdomainCtrl = TextEditingController();
  bool _autoSubdomain = true;
  bool _deploying = false;

  @override
  void initState() {
    super.initState();
    _projectCtrl.text = widget.args.suggestedProjectName;
    unawaited(_primeCloudflareConfig());
  }

  @override
  void dispose() {
    _teamCtrl.dispose();
    _projectCtrl.dispose();
    _branchCtrl.dispose();
    _baseCtrl.dispose();
    _buildCtrl.dispose();
    _publishCtrl.dispose();
    _functionsCtrl.dispose();
    _envCtrl.dispose();
    _domainCtrl.dispose();
    _zoneIdCtrl.dispose();
    _apiTokenCtrl.dispose();
    _targetCtrl.dispose();
    _subdomainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('review configuration'),
        backgroundColor: BuildifyPalette.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'let’s deploy your project with…',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'deploy as sujith8257 on ${_teamCtrl.text} team from ${_branchCtrl.text} branch',
            style: const TextStyle(color: Color(0xFFA38B86)),
          ),
          const SizedBox(height: 16),
          _labeledField('team', _teamCtrl),
          _labeledField('project name', _projectCtrl),
          _labeledField(
            'cloudflare base domain',
            _domainCtrl,
            hint: 'example: yourdomain.com',
          ),
          _labeledField('cloudflare zone id', _zoneIdCtrl),
          _labeledField(
            'cloudflare api token',
            _apiTokenCtrl,
            hint: 'token with dns edit permission',
          ),
          _labeledField(
            'cloudflare cname target',
            _targetCtrl,
            hint: 'e.g. your-tunnel.trycloudflare.com',
          ),
          SwitchListTile(
            value: _autoSubdomain,
            onChanged: (v) => setState(() => _autoSubdomain = v),
            title: const Text('auto-generate subdomain'),
            subtitle: const Text('netlify-style adjective-noun-number'),
            contentPadding: EdgeInsets.zero,
          ),
          if (_autoSubdomain)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () {
                  final generated =
                      ref
                          .read(serverProvider.notifier)
                          .suggestRandomSubdomain();
                  setState(() => _subdomainCtrl.text = generated);
                },
                child: Text(
                  _subdomainCtrl.text.isEmpty
                      ? 'generate subdomain'
                      : 'generated: ${_subdomainCtrl.text}',
                ),
              ),
            ),
          if (!_autoSubdomain)
            _labeledField(
              'custom subdomain',
              _subdomainCtrl,
              hint: 'e.g. myproject',
            ),
          _labeledField('branch to deploy', _branchCtrl),
          _labeledField('base directory', _baseCtrl),
          _labeledField(
            'build command',
            _buildCtrl,
            hint: 'e.g. npm run build',
          ),
          _labeledField('publish directory', _publishCtrl, hint: 'e.g. dist'),
          _labeledField('functions directory', _functionsCtrl),
          _labeledField(
            'environment variables',
            _envCtrl,
            hint: 'KEY=value (one per line)',
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _deploying ? null : _deployNow,
            style: FilledButton.styleFrom(
              backgroundColor: BuildifyPalette.primary,
              foregroundColor: BuildifyPalette.bg,
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(_deploying ? 'deploying...' : 'deploy project'),
          ),
        ],
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFDBC1BA), fontSize: 13),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: BuildifyPalette.surface,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deployNow() async {
    setState(() => _deploying = true);
    try {
      final env = <String, String>{};
      for (final line in _envCtrl.text.split('\n')) {
        final t = line.trim();
        if (t.isEmpty || !t.contains('=')) continue;
        final split = t.split('=');
        env[split.first.trim()] = split.skip(1).join('=').trim();
      }

      final cloudflare = ref.read(cloudflareServiceProvider);
      final cfg = CloudflareConfig(
        apiToken: _apiTokenCtrl.text.trim(),
        zoneId: _zoneIdCtrl.text.trim(),
        baseDomain: _domainCtrl.text.trim(),
      );
      await cloudflare.saveConfig(cfg);

      final slug = _projectCtrl.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final chosenSubdomain =
          _autoSubdomain
              ? (_subdomainCtrl.text.isEmpty
                  ? ref.read(serverProvider.notifier).suggestRandomSubdomain()
                  : _subdomainCtrl.text)
              : _subdomainCtrl.text;
      final dnsUrl = await cloudflare.upsertCnameRecord(
        config: cfg,
        subdomain: chosenSubdomain.isEmpty ? slug : chosenSubdomain,
        targetHostname: _targetCtrl.text.trim(),
      );

      final appUrl = await ref
          .read(serverProvider.notifier)
          .deployProjectWithConfig(
            sourceType: widget.args.sourceType,
            projectName: _projectCtrl.text,
            domain: _domainCtrl.text,
            subdomain: chosenSubdomain.isEmpty ? slug : chosenSubdomain,
            branch: _branchCtrl.text,
            baseDirectory: _baseCtrl.text,
            buildCommand: _buildCtrl.text,
            publishDirectory: _publishCtrl.text,
            functionsDirectory: _functionsCtrl.text,
            selectedPath: widget.args.selectedPath,
            envVars: env,
          );
      if (!mounted) return;
      setState(() => _deploying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('dns: $dnsUrl | app: $appUrl')));
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deploying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('cloudflare deploy failed: $e')));
    }
  }

  Future<void> _primeCloudflareConfig() async {
    final cfg = await ref.read(cloudflareServiceProvider).loadConfig();
    if (!mounted || cfg == null) return;
    if (_domainCtrl.text.isEmpty) _domainCtrl.text = cfg.baseDomain;
    if (_zoneIdCtrl.text.isEmpty) _zoneIdCtrl.text = cfg.zoneId;
    if (_apiTokenCtrl.text.isEmpty) _apiTokenCtrl.text = cfg.apiToken;
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(serverProvider);
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: BuildifyPalette.bg,
            border: Border(bottom: BorderSide(color: BuildifyPalette.border)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.terminal,
                color: BuildifyPalette.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'buildify',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: BuildifyPalette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: BuildifyPalette.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: BuildifyPalette.text,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                'good morning, ${server.userName}.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _MetricChip(
                      label: 'projects live',
                      value: '${server.projects.where((p) => p.isLive).length}',
                    ),
                    const SizedBox(width: 12),
                    _MetricChip(
                      label: 'requests today',
                      value: '${server.requestCount}',
                    ),
                    const SizedBox(width: 12),
                    _MetricChip(
                      label: 'bandwidth used',
                      value: '${(server.requestCount * 18) ~/ 100}mb',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'recent projects',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: BuildifyPalette.text.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              ...server.projects.map((project) {
                final deployedAt =
                    project.lastDeployedAt == null
                        ? 'last deployed never'
                        : 'last deployed ${DateTime.now().difference(project.lastDeployedAt!).inMinutes}m ago';
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _ProjectCard(
                    name: project.name,
                    url: project.url,
                    deployedAt: deployedAt,
                    isLive: project.isLive,
                  ),
                );
              }),
              if (server.projects.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'no projects yet. tap + to start.',
                    style: TextStyle(color: Color(0xFFA38B86)),
                  ),
                ),
              const SizedBox(height: 14),
              _panel(
                context,
                title: 'live server',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: () {
                        final ctrl = ref.read(serverProvider.notifier);
                        server.isRunning
                            ? ctrl.stopServer()
                            : ctrl.startServer();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            server.isRunning
                                ? BuildifyPalette.error
                                : BuildifyPalette.primary,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: Text(
                        server.isRunning ? 'stop server' : 'start server',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'public url: ${server.publicUrl}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'tunnel: ${server.tunnelProvider}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'uptime: ${_formatUptime(server.uptime)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DeployWizardScreen extends StatefulWidget {
  const DeployWizardScreen({super.key});

  @override
  State<DeployWizardScreen> createState() => _DeployWizardScreenState();
}

class _DeployWizardScreenState extends State<DeployWizardScreen> {
  String source = 'zip upload';
  String framework = 'react';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'deploy wizard',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'source',
          child: DropdownButton<String>(
            isExpanded: true,
            value: source,
            dropdownColor: BuildifyPalette.surface,
            items: const [
              DropdownMenuItem(value: 'zip upload', child: Text('zip upload')),
              DropdownMenuItem(
                value: 'github repo',
                child: Text('github repo'),
              ),
            ],
            onChanged: (v) => setState(() => source = v ?? source),
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'framework auto-detection',
          child: DropdownButton<String>(
            isExpanded: true,
            value: framework,
            dropdownColor: BuildifyPalette.surface,
            items: const [
              DropdownMenuItem(value: 'react', child: Text('react')),
              DropdownMenuItem(value: 'vue', child: Text('vue')),
              DropdownMenuItem(value: 'plain html', child: Text('plain html')),
            ],
            onChanged: (v) => setState(() => framework = v ?? framework),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed:
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('deploying...'))),
          style: FilledButton.styleFrom(
            backgroundColor: BuildifyPalette.primary,
          ),
          child: const Text('go live'),
        ),
      ],
    );
  }
}

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  LogType? filter;
  bool autoScroll = true;
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(serverProvider).logs;
    final shown =
        filter == null ? logs : logs.where((l) => l.type == filter).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!autoScroll || !controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('logs terminal'),
        backgroundColor: BuildifyPalette.bg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _filterButton(
                  'all',
                  filter == null,
                  () => setState(() => filter = null),
                ),
                _filterButton(
                  'errors',
                  filter == LogType.error,
                  () => setState(() => filter = LogType.error),
                ),
                _filterButton(
                  'requests',
                  filter == LogType.request,
                  () => setState(() => filter = LogType.request),
                ),
                _filterButton(
                  autoScroll ? 'auto-scroll: on' : 'auto-scroll: off',
                  autoScroll,
                  () => setState(() => autoScroll = !autoScroll),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: BuildifyPalette.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: controller,
                itemCount: shown.length,
                itemBuilder: (context, index) {
                  final log = shown[index];
                  final color = switch (log.type) {
                    LogType.error => BuildifyPalette.primary,
                    LogType.system => BuildifyPalette.muted,
                    LogType.request => BuildifyPalette.text,
                  };
                  return Text(
                    log.text,
                    style: TextStyle(fontSize: 11, color: color),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _filterButton(String label, bool selected, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            selected ? BuildifyPalette.primary : BuildifyPalette.text,
        side: BorderSide(
          color: selected ? BuildifyPalette.primary : BuildifyPalette.border,
        ),
      ),
      child: Text(label),
    );
  }
}

class DomainsScreen extends StatelessWidget {
  const DomainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'domains',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'custom domain',
          child: const Text('myproject.buildify.app'),
        ),
        const SizedBox(height: 12),
        _panel(context, title: 'ssl', child: const Text('auto ssl active')),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'qr share',
          child: const Text('qr preview placeholder'),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'env vars',
          child: const Text('.env manager (encrypted at rest)'),
        ),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'analytics',
          child: const Text('requests/hr, bandwidth, top pages'),
        ),
        const SizedBox(height: 12),
        _panel(
          context,
          title: 'profile',
          child: const Text('builder profile controls'),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: BuildifyPalette.surface,
        border: Border.all(color: const Color(0xFF555555)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFFDBC1BA)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: BuildifyPalette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.name,
    required this.url,
    required this.deployedAt,
    required this.isLive,
  });

  final String name;
  final String url;
  final String deployedAt;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final textColor = isLive ? BuildifyPalette.text : const Color(0xFFA38B86);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BuildifyPalette.surface,
        border: Border.all(color: const Color(0xFF555555)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isLive ? BuildifyPalette.success : BuildifyPalette.muted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_vert, size: 20, color: Color(0xFFDBC1BA)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFF3D3230)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(url, style: TextStyle(fontSize: 13, color: textColor)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Color(0xFFA38B86)),
              const SizedBox(width: 4),
              Text(
                deployedAt,
                style: const TextStyle(fontSize: 13, color: Color(0xFFA38B86)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _panel(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: BuildifyPalette.surface,
      border: Border.all(color: BuildifyPalette.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: BuildifyPalette.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

String _formatUptime(Duration d) {
  final hh = d.inHours.toString().padLeft(2, '0');
  final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
  final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}
