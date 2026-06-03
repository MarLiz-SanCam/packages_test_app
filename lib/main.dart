import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picture_info/picture_info.dart';
import 'plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugin Tester — picture_info',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PluginDemoScreen(),
    );
  }
}

class PluginTestScreen extends StatefulWidget {
  const PluginTestScreen({super.key});

  @override
  State<PluginTestScreen> createState() => _PluginTestScreenState();
}

class _PluginTestScreenState extends State<PluginTestScreen> {
  final PictureInfo _plugin = PictureInfo();

  _TestResult? _platformVersionResult;
  bool _loadingPlatformVersion = false;

  Future<void> _runGetPlatformVersion() async {
    setState(() {
      _loadingPlatformVersion = true;
      _platformVersionResult = null;
    });

    try {
      final version = await _plugin.getPlatformVersion();
      setState(() {
        _platformVersionResult = _TestResult.success(
          version ?? 'null (sin valor)',
        );
      });
    } on PlatformException catch (e) {
      setState(() {
        _platformVersionResult = _TestResult.error(
          'PlatformException: ${e.message}',
        );
      });
    } catch (e) {
      setState(() {
        _platformVersionResult = _TestResult.error(e.toString());
      });
    } finally {
      setState(() => _loadingPlatformVersion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'picture_info',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: cs.onPrimaryContainer,
              ),
            ),
            Text(
              'Plugin Test App',
              style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(label: 'Plataforma'),
          const SizedBox(height: 8),
          _MethodCard(
            methodName: 'getPlatformVersion()',
            description:
                'Devuelve la versión del sistema operativo del dispositivo.',
            loading: _loadingPlatformVersion,
            result: _platformVersionResult,
            onRun: _runGetPlatformVersion,
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'Data Loader (próximamente)'),
          const SizedBox(height: 8),
          _PlaceholderCard(
            methodName: 'PictureInfoDataLoader.load()',
            description:
                'Carga todos los datos del dispositivo junto a metadata personalizada (userName, appVersion, environment).',
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'Overlay (próximamente)'),
          const SizedBox(height: 8),
          _PlaceholderCard(
            methodName: 'PictureInfoOverlay()',
            description:
                'Renderiza el stamp sobre la imagen con título y tema (dark / light).',
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: cs.primary,
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.methodName,
    required this.description,
    required this.loading,
    required this.result,
    required this.onRun,
  });

  final String methodName;
  final String description;
  final bool loading;
  final _TestResult? result;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    methodName,
                    style: tt.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: loading ? null : onRun,
                  child: loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSecondaryContainer,
                          ),
                        )
                      : const Text('Ejecutar'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: tt.bodySmall),
            if (result != null) ...[
              const SizedBox(height: 12),
              _ResultBadge(result: result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.methodName,
    required this.description,
  });

  final String methodName;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    methodName,
                    style: tt.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: cs.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: null,
                  child: const Text('Pendiente'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: tt.bodySmall?.copyWith(color: cs.outline)),
          ],
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});

  final _TestResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isError = result.isError;

    final bgColor = isError ? cs.errorContainer : cs.secondaryContainer;
    final fgColor = isError ? cs.onErrorContainer : cs.onSecondaryContainer;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              result.value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result model ───────────────────────────────────────────────────────────────

class _TestResult {
  const _TestResult._(this.value, this.isError);

  factory _TestResult.success(String value) => _TestResult._(value, false);
  factory _TestResult.error(String value) => _TestResult._(value, true);

  final String value;
  final bool isError;
}
