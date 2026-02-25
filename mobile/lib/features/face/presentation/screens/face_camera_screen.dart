import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // State flags
  bool _permissionGranted = false;
  bool _isInitializing   = true;
  String? _initError;

  // Face detection state (will become non-final in Day 4 when MLKit sets it)
  // ignore: prefer_final_fields
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _initError      = null;
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
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller     = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError      = 'Camera error: $e';
        });
      }
    }
  }

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

        // Capture button (enabled only when face detected)
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: _CaptureButton(
              label: actionLabel,
              color: actionColor,
              enabled: _faceDetected,
              onPressed: _faceDetected ? () => _onCapture() : null,
            ),
          ),
        ),
      ],
    );
  }

  // Capture handler — fully implemented in Day 5
  Future<void> _onCapture() async {
    // TODO Day 5: capture image → compress → POST to /face/attendance-image
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
