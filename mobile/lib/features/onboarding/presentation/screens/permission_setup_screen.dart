import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

class PermissionSetupDoneNotifier extends Notifier<bool> {
  PermissionSetupDoneNotifier([this._initial = false]);
  final bool _initial;

  @override
  bool build() => _initial;

  void markDone() => state = true;
}

/// Overridden in main.dart with the value read from SharedPreferences.
final permissionSetupDoneProvider =
    NotifierProvider<PermissionSetupDoneNotifier, bool>(
  () => PermissionSetupDoneNotifier(false),
);

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() =>
      _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  PermissionStatus _cameraStatus       = PermissionStatus.denied;
  PermissionStatus _locationStatus     = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cam  = await Permission.camera.status;
    final loc  = await Permission.locationWhenInUse.status;
    final notif = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _cameraStatus       = cam;
      _locationStatus     = loc;
      _notificationStatus = notif;
    });
  }

  Future<void> _onRequest(Permission perm) async {
    final result = await perm.request();
    if (!mounted) return;
    setState(() {
      if (perm == Permission.camera) {
        _cameraStatus = result;
      } else if (perm == Permission.locationWhenInUse) {
        _locationStatus = result;
      } else {
        _notificationStatus = result;
      }
    });
  }

  Future<void> _onContinue() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_setup_done', true);
    if (!mounted) return;
    ref.read(permissionSetupDoneProvider.notifier).markDone();
    // Router rebuilds via ref.watch(permissionSetupDoneProvider) in appRouterProvider
    // → redirect to /login since setupDone is now true and user is unauthenticated.
  }

  bool get _anyDenied =>
      !_cameraStatus.isGranted ||
      !_locationStatus.isGranted ||
      !_notificationStatus.isGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text('Izin Akses'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Icon(
              Icons.security_rounded,
              size: 64,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Izin Diperlukan',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi ini membutuhkan akses kamera, lokasi, dan notifikasi untuk fitur absensi wajah, validasi geofence, dan push notification.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _PermissionCard(
              title: 'Kamera',
              description: 'Diperlukan untuk absensi wajah (face check-in/out) dan enrollment wajah.',
              icon: Icons.camera_alt_rounded,
              status: _cameraStatus,
              onRequest: () => _onRequest(Permission.camera),
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              title: 'Lokasi',
              description: 'Diperlukan untuk validasi geofence saat absensi di area kantor.',
              icon: Icons.location_on_rounded,
              status: _locationStatus,
              onRequest: () => _onRequest(Permission.locationWhenInUse),
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              title: 'Notifikasi',
              description: 'Diperlukan untuk menerima push notification approval cuti, lembur, dan task.',
              icon: Icons.notifications_rounded,
              status: _notificationStatus,
              onRequest: () => _onRequest(Permission.notification),
            ),
            const SizedBox(height: 32),
            if (_anyDenied) ...[
              Text(
                'Beberapa izin belum aktif. Fitur absensi mungkin tidak berfungsi penuh.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permission Card ────────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.onRequest,
  });

  final String title;
  final String description;
  final IconData icon;
  final PermissionStatus status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: _buildTrailing(context),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (status.isGranted) {
      return Chip(
        label: const Text(
          '✓ Diizinkan',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    if (status.isPermanentlyDenied) {
      return TextButton(
        onPressed: openAppSettings,
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          padding: EdgeInsets.zero,
        ),
        child: const Text(
          'Buka\nPengaturan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(72, 32),
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: const Text('Izinkan'),
    );
  }
}
