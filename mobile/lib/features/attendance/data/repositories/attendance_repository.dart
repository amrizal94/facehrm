import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_record_model.dart';
import '../models/pending_attendance_action.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(
    ref.watch(attendanceRemoteDataSourceProvider),
    ref.watch(attendanceLocalDatasourceProvider),
  ),
);

class AttendanceRepository {
  final AttendanceRemoteDataSource _ds;
  final AttendanceLocalDatasource _localDs;

  AttendanceRepository(this._ds, this._localDs);

  Future<AttendanceRecordModel?> getToday() => _ds.getToday();

  Future<List<AttendanceRecordModel>> getMyAttendance({
    String? dateFrom,
    String? dateTo,
    int perPage = 30,
  }) =>
      _ds.getMyAttendance(dateFrom: dateFrom, dateTo: dateTo, perPage: perPage);

  /// Online check-in: captures fresh GPS then posts immediately.
  Future<AttendanceRecordModel> checkIn() async {
    final loc = await LocationService.getCurrentLocation();
    return _ds.checkIn(location: loc);
  }

  /// Online check-out: captures fresh GPS then posts immediately.
  Future<AttendanceRecordModel> checkOut() async {
    final loc = await LocationService.getCurrentLocation();
    return _ds.checkOut(location: loc);
  }

  /// Sync a queued check-in action with its original timestamp + location.
  Future<AttendanceRecordModel> syncCheckIn(PendingAttendanceAction action) {
    final loc = _locationFromAction(action);
    return _ds.checkIn(location: loc, clientTimestamp: action.timestamp);
  }

  /// Sync a queued check-out action with its original timestamp + location.
  Future<AttendanceRecordModel> syncCheckOut(PendingAttendanceAction action) {
    final loc = _locationFromAction(action);
    return _ds.checkOut(location: loc, clientTimestamp: action.timestamp);
  }

  Future<List<AttendanceRecordModel>> getAllAttendance({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? status,
    int perPage = 50,
  }) =>
      _ds.getAllAttendance(
        date: date,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        perPage: perPage,
      );

  // ── Local queue helpers ────────────────────────────────────────────────────
  Future<void> enqueueAction(PendingAttendanceAction action) =>
      _localDs.enqueue(action);

  Future<List<PendingAttendanceAction>> getPendingActions() =>
      _localDs.getPendingActions();

  Future<void> removePendingAction(String id) => _localDs.remove(id);

  Future<int> pendingCount() => _localDs.pendingCount();

  // ── Private helpers ────────────────────────────────────────────────────────
  LocationResult? _locationFromAction(PendingAttendanceAction action) {
    if (action.latitude == null || action.longitude == null) return null;
    return LocationResult(
      latitude: action.latitude!,
      longitude: action.longitude!,
      accuracy: action.locationAccuracy ?? 0.0,
      isMocked: action.isMockLocation,
    );
  }
}
