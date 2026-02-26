import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, WriteBuffer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../../data/datasources/face_remote_datasource.dart';

enum _FaceStatus  { none, detected, multiple }
enum _EnrollStage { idle, capturing, processing, success }

/// Camera screen for staff self-enrollment.
/// Pops with [true] on success, or [false]/null if cancelled.
class FaceSelfEnrollScreen extends ConsumerStatefulWidget {
  const FaceSelfEnrollScreen({super.key});

  @override
  ConsumerState<FaceSelfEnrollScreen> createState() => _FaceSelfEnrollScreenState();
}

class _FaceSelfEnrollScreenState extends ConsumerState<FaceSelfEnrollScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.25,
    ),
  );
  bool _isDetecting = false;

  bool    _permissionGranted = false;
  bool    _isInitializing    = true;
  String? _initError;

  int  _faceCount      = 0;
  bool _hadFaceBefore  = false;

  _FaceStatus get _faceStatus => switch (_faceCount) {
    1 => _FaceStatus.detected,
    0 => _FaceStatus.none,
    _ => _FaceStatus.multiple,
  };
  bool get _faceDetected => _faceCount == 1;

  _EnrollStage _stage          = _EnrollStage.idle;
  String       _successMessage = '';

  bool get _isBusy => _stage != _EnrollStage.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _faceDetector.close();
    final ctrl = _controller;
    _controller = null;
    ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _initError      = null;
      _faceCount      = 0;
      _hadFaceBefore  = false;
      _stage          = _EnrollStage.idle;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _isInitializing    = false;
          _initError         = 'Izin kamera ditolak.';
        });
      }
      return;
    }
    _permissionGranted = true;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('Tidak ada kamera ditemukan.');

      final desc = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final ctrl = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await ctrl.initialize();
      if (!mounted) return;

      setState(() {
        _controller     = ctrl;
        _isInitializing = false;
      });

      _startDetection(ctrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError      = 'Kamera error: $e';
        });
      }
    }
  }

  void _startDetection(CameraController ctrl) {
    ctrl.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;
      try {
        final inputImage = _toInputImage(image);
        if (inputImage == null) return;

        final faces = await _faceDetector.processImage(inputImage);
        if (mounted) {
          final count = _filterFacesInOval(faces, image.width, image.height).length;
          if (count != _faceCount) {
            setState(() => _faceCount = count);
            if (count == 1 && !_hadFaceBefore) {
              _hadFaceBefore = true;
              HapticFeedback.lightImpact();
            } else if (count == 0) {
              _hadFaceBefore = false;
            }
          }
        }
      } catch (_) {
        // ignore per-frame errors
      } finally {
        await Future.delayed(const Duration(milliseconds: 100));
        _isDetecting = false;
      }
    });
  }

  /// Only count faces whose center falls within the oval guide area.
  /// MLKit returns bounding boxes in the rotated (portrait) coordinate space
  /// when rotation metadata is provided, so portrait width = imgH, portrait height = imgW
  /// for a landscape-sensor camera with sensorOrientation 90 or 270.
  List<Face> _filterFacesInOval(List<Face> faces, int imgWidth, int imgHeight) {
    final orientation = _controller?.description.sensorOrientation ?? 270;
    final bool isRotated = orientation == 90 || orientation == 270;
    final double pW = isRotated ? imgHeight.toDouble() : imgWidth.toDouble();
    final double pH = isRotated ? imgWidth.toDouble() : imgHeight.toDouble();

    return faces.where((face) {
      final box = face.boundingBox;
      // Size gate: reject tiny faces (t-shirt prints, far-away people)
      if (box.width < pW * 0.18 || box.height < pH * 0.15) return false;
      // Oval zone: centre (0.5, 0.42), semi-axes (0.40, 0.34) in normalised portrait coords.
      // These match the _EnrollGuidePainter oval with a small margin added.
      final cx = box.center.dx / pW;
      final cy = box.center.dy / pH;
      final dx = (cx - 0.5) / 0.40;
      final dy = (cy - 0.42) / 0.34;
      return dx * dx + dy * dy <= 1.0;
    }).toList();
  }

  InputImage? _toInputImage(CameraImage image) {
    final rotation = InputImageRotationValue.fromRawValue(
      _controller!.description.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _onEnroll() async {
    if (_isBusy || _controller == null) return;
    setState(() => _stage = _EnrollStage.capturing);

    try {
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));
      final xfile    = await _controller!.takePicture();
      final rawBytes = await xfile.readAsBytes();

      final original = img.decodeImage(rawBytes);
      if (original == null) throw Exception('Gagal memproses gambar.');
      final toEncode = original.width > 800
          ? img.copyResize(original, width: 800)
          : original;
      final compressed = img.encodeJpg(toEncode, quality: 85);

      if (mounted) setState(() => _stage = _EnrollStage.processing);

      final message = await ref.read(faceRemoteDatasourceProvider).selfEnrollFace(
        imageBytes: compressed,
        filename:   'enroll_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      setState(() {
        _stage          = _EnrollStage.success;
        _successMessage = message;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.pop(true); // signal success to caller
    } catch (e) {
      if (!mounted) return;

      final msg = _humanizeError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() {
        _stage         = _EnrollStage.idle;
        _faceCount     = 0;
        _hadFaceBefore = false;
      });
      if (_controller != null && _controller!.value.isInitialized) {
        _startDetection(_controller!);
      }
    }
  }

  String _humanizeError(Object e) {
    final raw   = e.toString().replaceFirst('ApiException: ', '');
    final lower = raw.toLowerCase();
    if (lower.contains('no face') || lower.contains('extraction failed') ||
        lower.contains('invalid descriptor') || lower.contains('face extraction')) {
      return 'Wajah tidak terdeteksi dalam foto. Pastikan pencahayaan cukup lalu coba lagi.';
    }
    if (lower.contains('terlalu lama') || lower.contains('timeout')) {
      return 'Proses terlalu lama. Coba lagi.';
    }
    if (lower.contains('koneksi') || lower.contains('connection')) {
      return 'Koneksi gagal. Periksa jaringan dan coba lagi.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Daftarkan Wajah'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(_initError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (!_permissionGranted)
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Buka Pengaturan'),
                )
              else
                ElevatedButton(
                  onPressed: _initCamera,
                  child: const Text('Coba Lagi'),
                ),
            ],
          ),
        ),
      );
    }

    if (_isInitializing || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview (mirrored for front cam)
        Transform.scale(
          scaleX: _controller!.description.lensDirection == CameraLensDirection.front ? -1 : 1,
          child: CameraPreview(_controller!),
        ),

        // Oval guide
        CustomPaint(painter: _EnrollGuidePainter(status: _faceStatus)),

        // Instruction
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                _instructionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _instructionColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Foto wajah akan disimpan untuk check-in otomatis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),

        // Enroll button
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: _EnrollButton(
              enabled: _faceDetected && !_isBusy,
              onPressed: (_faceDetected && !_isBusy) ? _onEnroll : null,
            ),
          ),
        ),

        // Overlays
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_stage) {
            _EnrollStage.capturing  => const _OverlayMessage(key: ValueKey('cap'),  label: 'Memotret wajah...'),
            _EnrollStage.processing => const _OverlayMessage(key: ValueKey('proc'), label: 'Mendaftarkan wajah...'),
            _EnrollStage.success    => _SuccessView(
                key: const ValueKey('ok'),
                message: _successMessage,
                onTap: () => context.pop(true),
              ),
            _EnrollStage.idle       => const SizedBox.shrink(key: ValueKey('idle')),
          },
        ),
      ],
    );
  }

  String get _instructionText => switch (_faceStatus) {
    _FaceStatus.none     => 'Posisikan wajah Anda dalam oval',
    _FaceStatus.detected => 'Wajah terdeteksi — tahan posisi',
    _FaceStatus.multiple => 'Lebih dari 1 wajah — pastikan hanya Anda',
  };

  Color get _instructionColor => switch (_faceStatus) {
    _FaceStatus.none     => Colors.white,
    _FaceStatus.detected => Colors.greenAccent,
    _FaceStatus.multiple => Colors.orangeAccent,
  };
}

// ── Oval guide painter ───────────────────────────────────────────────────────
class _EnrollGuidePainter extends CustomPainter {
  final _FaceStatus status;
  const _EnrollGuidePainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width:  size.width * 0.68,
      height: size.width * 0.85,
    );

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
    canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    final borderColor = switch (status) {
      _FaceStatus.none     => Colors.white70,
      _FaceStatus.detected => Colors.greenAccent,
      _FaceStatus.multiple => Colors.orangeAccent,
    };

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color       = borderColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_EnrollGuidePainter old) => old.status != status;
}

// ── Processing overlay ───────────────────────────────────────────────────────
class _OverlayMessage extends StatelessWidget {
  final String label;
  const _OverlayMessage({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ── Success overlay ──────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _SuccessView({super.key, required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu sekarang bisa check-in dengan wajah',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Enroll button ────────────────────────────────────────────────────────────
class _EnrollButton extends StatelessWidget {
  final bool     enabled;
  final VoidCallback? onPressed;
  const _EnrollButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.how_to_reg_outlined),
        label: const Text('Daftar Wajah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        ),
      ),
    );
  }
}
