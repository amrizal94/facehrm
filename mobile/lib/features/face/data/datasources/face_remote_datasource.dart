import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

class FaceRemoteDatasource {
  final Dio _dio;
  FaceRemoteDatasource(this._dio);

  /// POST /face/attendance-image
  /// [imageBytes] — compressed JPEG bytes
  /// [action]     — 'check_in' | 'check_out'
  /// [filename]   — e.g. 'face_checkin_1234.jpg'
  Future<void> faceAttendance({
    required List<int> imageBytes,
    required String action,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'action': action,
        'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      });

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
    } on DioException catch (e) {
      // Give timeout a clearer message before the generic handler
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const ApiException(
          message: 'Proses terlalu lama. Coba lagi.',
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ApiException(
          message: 'Koneksi gagal. Periksa jaringan dan coba lagi.',
        );
      }
      throw ApiException.fromDioError(e);
    }
  }
}

final faceRemoteDatasourceProvider = Provider<FaceRemoteDatasource>(
  (ref) => FaceRemoteDatasource(ref.watch(dioClientProvider)),
);
