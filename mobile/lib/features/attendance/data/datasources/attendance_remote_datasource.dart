import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../models/attendance_record_model.dart';

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>(
  (ref) => AttendanceRemoteDataSource(ref.watch(dioClientProvider)),
);

class AttendanceRemoteDataSource {
  final Dio _dio;
  AttendanceRemoteDataSource(this._dio);

  Future<AttendanceRecordModel?> getToday() async {
    try {
      final res = await _dio.get(ApiConstants.attendanceToday);
      final data = res.data['data'];
      if (data == null) return null;
      return AttendanceRecordModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<AttendanceRecordModel>> getMyAttendance({
    String? dateFrom,
    String? dateTo,
    int perPage = 30,
  }) async {
    try {
      final q = <String, dynamic>{'per_page': perPage};
      if (dateFrom != null) q['date_from'] = dateFrom;
      if (dateTo != null) q['date_to'] = dateTo;
      final res = await _dio.get(ApiConstants.attendanceMy, queryParameters: q);
      final list = res.data['data'] as List;
      return list.map((e) => AttendanceRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AttendanceRecordModel> checkIn() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      final body = <String, dynamic>{};
      if (loc != null) {
        body['latitude']          = loc.latitude;
        body['longitude']         = loc.longitude;
        body['location_accuracy'] = loc.accuracy;
        body['is_mock_location']  = loc.isMocked;
      }
      final res = await _dio.post(ApiConstants.attendanceCheckIn, data: body);
      return AttendanceRecordModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AttendanceRecordModel> checkOut() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      final body = <String, dynamic>{};
      if (loc != null) {
        body['latitude']          = loc.latitude;
        body['longitude']         = loc.longitude;
        body['location_accuracy'] = loc.accuracy;
        body['is_mock_location']  = loc.isMocked;
      }
      final res = await _dio.post(ApiConstants.attendanceCheckOut, data: body);
      return AttendanceRecordModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<AttendanceRecordModel>> getAllAttendance({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? status,
    int perPage = 50,
  }) async {
    try {
      final q = <String, dynamic>{'per_page': perPage};
      if (date != null) q['date'] = date;
      if (dateFrom != null) q['date_from'] = dateFrom;
      if (dateTo != null) q['date_to'] = dateTo;
      if (status != null) q['status'] = status;
      final res = await _dio.get(ApiConstants.attendance, queryParameters: q);
      final list = res.data['data'] as List;
      return list
          .map((e) => AttendanceRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
