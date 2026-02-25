import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/attendance_record_model.dart';
import '../../data/repositories/attendance_repository.dart';

// Today's attendance — AsyncNotifier with check-in/out actions
class TodayAttendanceNotifier extends AsyncNotifier<AttendanceRecordModel?> {
  @override
  Future<AttendanceRecordModel?> build() =>
      ref.watch(attendanceRepositoryProvider).getToday();

  Future<String?> checkIn() async {
    try {
      final record = await ref.read(attendanceRepositoryProvider).checkIn();
      state = AsyncData(record);
      return null;
    } catch (e) {
      await _refreshTodayBestEffort();
      return _humanizeError(e);
    }
  }

  Future<String?> checkOut() async {
    try {
      final record = await ref.read(attendanceRepositoryProvider).checkOut();
      state = AsyncData(record);
      return null;
    } catch (e) {
      await _refreshTodayBestEffort();
      return _humanizeError(e);
    }
  }

  Future<void> _refreshTodayBestEffort() async {
    try {
      final latest = await ref.read(attendanceRepositoryProvider).getToday();
      state = AsyncData(latest);
    } catch (_) {
      // Ignore refresh errors; keep existing state.
    }
  }

  String _humanizeError(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 422) {
        final msg = e.message.toLowerCase();
        if (msg.contains('already checked out')) {
          return 'Kamu sudah check-out hari ini.';
        }
        if (msg.contains('already checked in')) {
          return 'Kamu sudah check-in hari ini.';
        }
      }
      return '${e.message}${e.statusCode != null ? ' (status: ${e.statusCode})' : ''}';
    }

    return e.toString().replaceFirst('ApiException: ', '');
  }
}

final todayAttendanceProvider =
    AsyncNotifierProvider<TodayAttendanceNotifier, AttendanceRecordModel?>(
        () => TodayAttendanceNotifier());

// My attendance history list
final myAttendanceListProvider = FutureProvider.family<
    List<AttendanceRecordModel>,
    ({String? dateFrom, String? dateTo})>((ref, params) {
  return ref.watch(attendanceRepositoryProvider).getMyAttendance(
        dateFrom: params.dateFrom,
        dateTo: params.dateTo,
      );
});
