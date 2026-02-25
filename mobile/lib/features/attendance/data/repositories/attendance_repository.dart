import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_record_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(attendanceRemoteDataSourceProvider)),
);

class AttendanceRepository {
  final AttendanceRemoteDataSource _ds;
  AttendanceRepository(this._ds);

  Future<AttendanceRecordModel?> getToday() => _ds.getToday();

  Future<List<AttendanceRecordModel>> getMyAttendance({
    String? dateFrom,
    String? dateTo,
    int perPage = 30,
  }) => _ds.getMyAttendance(dateFrom: dateFrom, dateTo: dateTo, perPage: perPage);

  Future<AttendanceRecordModel> checkIn() => _ds.checkIn();
  Future<AttendanceRecordModel> checkOut() => _ds.checkOut();

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
}
