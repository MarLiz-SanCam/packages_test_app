import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picture_info/picture_info.dart';

class PluginDemoScreen extends StatefulWidget {
  const PluginDemoScreen({super.key});

  @override
  State<PluginDemoScreen> createState() => _PluginDemoScreenState();
}

class _PluginDemoScreenState extends State<PluginDemoScreen> {
  final _plugin = PictureInfo();
  final _captureKey = GlobalKey<PictureInfoCaptureWidgetState>();

  PictureInfoSnapshot? _snapshot;
  bool _loadingSnapshot = true;
  String? _snapshotError;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _loadingSnapshot = true;
      _snapshotError = null;
    });
    try {
      final snapshot = await PictureInfoDataLoader.load();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (e) {
      if (mounted) setState(() => _snapshotError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSnapshot = false);
    }
  }

  Future<void> _openCamera() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;

    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CameraScreen(snapshot: snapshot),
      ),
    );

    if (bytes != null && mounted) {
      await _showPreview(bytes);
    }
  }

  Future<void> _captureScreen() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final bytes = await _captureKey.currentState!.capture();
      if (!mounted) return;
      await _showPreview(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _showPreview(Uint8List bytes) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PreviewDialog(bytes: bytes, plugin: _plugin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final snapshot = _snapshot;

    final scaffold = Scaffold(
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
              'Plugin Demo',
              style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer),
            ),
          ],
        ),
      ),
      body: _buildBody(cs),
    );

    if (snapshot != null) {
      return PictureInfoCaptureWidget(
        key: _captureKey,
        snapshot: snapshot,
        overlayTitle: 'Package Testing',
        overlayPosition: OverlayPosition.bottomLeft,
        child: scaffold,
      );
    }

    return scaffold;
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loadingSnapshot) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_snapshotError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'No se pudieron cargar los datos del dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadSnapshot,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const _Label('Cámara'),
        const SizedBox(height: 8),
        _ActionCard(
          icon: Icons.camera_alt_outlined,
          title: 'Abrir Cámara',
          description:
              'Abre la cámara del dispositivo con overlay de metadatos en '
              'tiempo real. Al capturar, el stamp queda grabado en la imagen.',
          onPressed: _snapshot != null ? _openCamera : null,
        ),
        const SizedBox(height: 16),
        const _Label('Captura de Pantalla'),
        const SizedBox(height: 8),
        _ActionCard(
          icon: Icons.screenshot_outlined,
          title: 'Capturar Pantalla',
          description:
              'Toma una captura de la pantalla actual con el stamp de '
              'metadatos superpuesto y la exporta como PNG.',
          loading: _capturing,
          onPressed: (_capturing || _snapshot == null) ? null : _captureScreen,
        ),
        if (_snapshot != null) ...[
          const SizedBox(height: 24),
          const _Label('Datos del Snapshot'),
          const SizedBox(height: 8),
          _SnapshotCard(snapshot: _snapshot!),
        ],
      ],
    );
  }
}

// ── Camera Screen ─────────────────────────────────────────────────────────────

class _CameraScreen extends StatelessWidget {
  const _CameraScreen({required this.snapshot});

  final PictureInfoSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PictureInfoCamera(
        snapshot: snapshot,
        overlayTitle: 'Package Testing',
        onCapture: (bytes) async {
          Navigator.of(context).pop(bytes);
        },
      ),
    );
  }
}

// ── Preview Dialog ─────────────────────────────────────────────────────────────

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({required this.bytes, required this.plugin});

  final Uint8List bytes;
  final PictureInfo plugin;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);
    try {
      await widget.plugin.saveImageToGallery(
        widget.bytes,
        albumName: 'PackageTesting',
      );
      if (mounted) setState(() => _saved = true);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            height: 340,
            width: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_saved) ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Guardado en galería',
                        style: tt.bodySmall?.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  FilledButton.tonal(
                    onPressed: _saving ? null : _saveToGallery,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar en galería'),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: cs.primary,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onPressed,
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSecondaryContainer,
                      ),
                    )
                  : const Text('Abrir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot});

  final PictureInfoSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final connLabel = switch (snapshot.connectivityType) {
      'wifi' => 'WiFi',
      'mobile' => 'Datos móviles',
      'ethernet' => 'Ethernet',
      'web' => 'Web',
      _ => 'Ninguna',
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(tt, cs, 'Dispositivo', snapshot.deviceLabel),
            _infoRow(tt, cs, 'SO', snapshot.osVersion),
            _infoRow(tt, cs, 'Fecha', snapshot.formattedDateTime),
            _infoRow(
              tt,
              cs,
              'Coordenadas',
              snapshot.formattedCoordinates ?? 'No disponible',
            ),
            _infoRow(
              tt,
              cs,
              'Red',
              snapshot.isConnected ? connLabel : 'Sin conexión',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    TextTheme tt,
    ColorScheme cs,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
