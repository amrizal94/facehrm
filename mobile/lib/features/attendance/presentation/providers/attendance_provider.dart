import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      return e.toString().replaceFirst('ApiException: ', '');
    }
  }

  Future<String?> checkOut() async {
    try {
      final record = await ref.read(attendanceRepositoryProvider).checkOut();
      state = AsyncData(record);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('ApiException: ', '');
    }
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
