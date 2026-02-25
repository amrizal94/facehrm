import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/reports_overview_model.dart';

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>(
  (ref) => ReportsRemoteDataSource(ref.watch(dioClientProvider)),
);

class ReportsRemoteDataSource {
  final Dio _dio;
  ReportsRemoteDataSource(this._dio);

  Future<ReportsOverviewModel> getOverview() async {
    try {
      final res = await _dio.get(ApiConstants.reportsOverview);
      final data = res.data['data'] as Map<String, dynamic>;
      return ReportsOverviewModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
