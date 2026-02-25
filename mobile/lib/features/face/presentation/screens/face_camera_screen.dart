import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../../../../features/attendance/presentation/providers/attendance_provider.dart';
import '../../data/datasources/face_remote_datasource.dart';

/// Screen type passed when navigating to [FaceCameraScreen].
enum FaceAction { checkIn, checkOut }

class FaceCameraScreen extends ConsumerStatefulWidget {
  final FaceAction action;
  const FaceCameraScreen({super.key, required this.action});

  @override
  ConsumerState<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends ConsumerState<FaceCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  // MLKit face detector — fast mode, minimum face size 15% of frame
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );
  bool _isDetecting = false;

  // State flags
  bool _permissionGranted = false;
  bool _isInitializing   = true;
  bool _isCapturing      = false;
  String? _initError;
  bool _faceDetected = false;

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
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _initError      = null;
      _faceDetected   = false;
    });

    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _isInitializing    = false;
          _initError         = 'Camera permission denied.';
        });
      }
      return;
    }

    _permissionGranted = true;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No cameras found on this device.');

      // Prefer front camera
      final desc = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // NV21 required for MLKit on Android
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller     = controller;
        _isInitializing = false;
      });

      _startDetection(controller);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError      = 'Camera error: $e';
        });
      }
    }
  }

  // ── Face detection loop ───────────────────────────────────────────────────

  void _startDetection(CameraController controller) {
    controller.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final inputImage = _toInputImage(image);
        if (inputImage == null) return;

        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          final detected = faces.length == 1;
          if (detected != _faceDetected) {
            setState(() => _faceDetected = detected);
          }
        }
      } catch (_) {
        // ignore per-frame detection errors silently
      } finally {
        // ~10 fps — give the device time to breathe between frames
        await Future.delayed(const Duration(milliseconds: 100));
        _isDetecting = false;
      }
    });
  }

  InputImage? _toInputImage(CameraImage image) {
    final rotation = InputImageRotationValue.fromRawValue(
      _controller!.description.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Concatenate all planes into a single byte buffer (works for NV21)
    final WriteBuffer allBytes = WriteBuffer();
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

  // ── Capture pipeline ──────────────────────────────────────────────────────

  Future<void> _onCapture() async {
    if (_isCapturing || _controller == null) return;
    setState(() => _isCapturing = true);

    try {
      // Stop detection stream — required before takePicture() on Android
      await _controller!.stopImageStream();

      // Take photo
      final xfile    = await _controller!.takePicture();
      final rawBytes = await xfile.readAsBytes();

      // Compress: resize to max 800 width, JPEG quality 85
      final original = img.decodeImage(rawBytes);
      if (original == null) throw Exception('Gagal memproses gambar.');
      final toEncode = original.width > 800
          ? img.copyResize(original, width: 800)
          : original;
      final compressed = img.encodeJpg(toEncode, quality: 85);

      // POST to backend
      final action = widget.action == FaceAction.checkIn ? 'check_in' : 'check_out';
      await ref.read(faceRemoteDatasourceProvider).faceAttendance(
        imageBytes: compressed,
        action: action,
        filename: 'face_${action}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Refresh attendance data and navigate back
      if (!mounted) return;
      ref.invalidate(todayAttendanceProvider);
      final label = widget.action == FaceAction.checkIn ? 'Check-in' : 'Check-out';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label berhasil!'),
          backgroundColor:
              widget.action == FaceAction.checkIn ? Colors.green : Colors.blue,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceFirst('ApiException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      // Reset and restart stream so user can retry
      setState(() {
        _isCapturing  = false;
        _faceDetected = false;
      });
      if (_controller != null && _controller!.value.isInitialized) {
        _startDetection(_controller!);
      }
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final actionLabel = widget.action == FaceAction.checkIn ? 'Check In' : 'Check Out';
    final actionColor = widget.action == FaceAction.checkIn ? Colors.green : Colors.blue;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Face $actionLabel'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(actionLabel, actionColor),
    );
  }

  Widget _buildBody(String actionLabel, Color actionColor) {
    // Error / permission denied state
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                _initError!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_permissionGranted)
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings'),
                )
              else
                ElevatedButton(
                  onPressed: _initCamera,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isInitializing || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview (mirrored for front camera)
        Transform.scale(
          scaleX: _controller!.description.lensDirection == CameraLensDirection.front
              ? -1
              : 1,
          child: CameraPreview(_controller!),
        ),

        // Oval face guide overlay
        CustomPaint(
          painter: _FaceGuidePainter(detected: _faceDetected),
        ),

        // Instruction text
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Text(
            _faceDetected
                ? 'Face detected — hold still'
                : 'Position your face in the oval',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _faceDetected ? Colors.greenAccent : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ),

        // Capture button (enabled only when face detected and not capturing)
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: _CaptureButton(
              label: actionLabel,
              color: actionColor,
              enabled: _faceDetected && !_isCapturing,
              onPressed: (_faceDetected && !_isCapturing) ? _onCapture : null,
            ),
          ),
        ),

        // Processing overlay — shown while uploading to backend
        if (_isCapturing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Memproses...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Oval face guide painter ──────────────────────────────────────────────────
class _FaceGuidePainter extends CustomPainter {
  final bool detected;
  const _FaceGuidePainter({required this.detected});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay outside the oval
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width:  size.width * 0.68,
      height: size.width * 0.85,
    );

    // Cut oval out of overlay using BlendMode
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
    canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // Oval border
    final borderPaint = Paint()
      ..color  = detected ? Colors.greenAccent : Colors.white70
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(_FaceGuidePainter old) => old.detected != detected;
}

// ── Capture button ───────────────────────────────────────────────────────────
class _CaptureButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  const _CaptureButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? color : Colors.grey,
            boxShadow: enabled
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                enabled ? Icons.camera_alt : Icons.face_retouching_off,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
