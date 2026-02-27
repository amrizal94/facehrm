import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';

class FaceRemoteDatasource {
  final Dio _dio;
  FaceRemoteDatasource(this._dio);

  /// POST /face/attendance-image
  /// Returns the backend success message (e.g. "Welcome, John! Checked in at 08:00.")
  Future<String> faceAttendance({
    required List<int> imageBytes,
    required String action,
    required String filename,
    LocationResult? location,
    bool livenessVerified = false,
  }) async {
    try {
      final fields = <String, dynamic>{
        'action':             action,
        'image':              MultipartFile.fromBytes(imageBytes, filename: filename),
        'liveness_verified':  livenessVerified ? '1' : '0',
      };
      if (location != null) {
        fields['latitude']          = location.latitude.toString();
        fields['longitude']         = location.longitude.toString();
        fields['location_accuracy'] = location.accuracy.toString();
        fields['is_mock_location']  = location.isMocked ? '1' : '0';
      }
      final formData = FormData.fromMap(fields);

      final response = await _dio.post(
        ApiConstants.faceAttendanceImage,
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw ApiException(
          message: body['message']?.toString() ?? 'Face attendance failed',
        );
      }
      return body['message']?.toString() ?? 'Berhasil!';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const ApiException(message: 'Proses terlalu lama. Coba lagi.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ApiException(
          message: 'Koneksi gagal. Periksa jaringan dan coba lagi.',
        );
      }
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /face/me
  /// Returns whether the current user's face is enrolled.
  Future<bool> getMyFaceStatus() async {
    try {
      final response = await _dio.get(ApiConstants.faceMe);
      final body = response.data as Map<String, dynamic>;
      return (body['data'] as Map<String, dynamic>?)?['enrolled'] as bool? ?? false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw const ApiException(message: 'Koneksi gagal. Periksa jaringan dan coba lagi.');
      }
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /face/self-enroll-image
  /// Enrolls the current user's own face. Returns the backend success message.
  Future<String> selfEnrollFace({
    required List<int> imageBytes,
    required String filename,
    bool livenessVerified = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image':             MultipartFile.fromBytes(imageBytes, filename: filename),
        'liveness_verified': livenessVerified ? '1' : '0',
      });

      final response = await _dio.post(
        ApiConstants.faceSelfEnroll,
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw ApiException(
          message: body['message']?.toString() ?? 'Pendaftaran wajah gagal',
        );
      }
      return body['message']?.toString() ?? 'Wajah berhasil didaftarkan!';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const ApiException(message: 'Proses terlalu lama. Coba lagi.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ApiException(message: 'Koneksi gagal. Periksa jaringan dan coba lagi.');
      }
      throw ApiException.fromDioError(e);
    }
  }
}

final faceRemoteDatasourceProvider = Provider<FaceRemoteDatasource>(
  (ref) => FaceRemoteDatasource(ref.watch(dioClientProvider)),
);
