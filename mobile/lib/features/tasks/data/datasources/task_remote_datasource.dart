import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/checklist_item_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>(
  (ref) => TaskRemoteDataSource(ref.watch(dioClientProvider)),
);

class TaskRemoteDataSource {
  final Dio _dio;
  TaskRemoteDataSource(this._dio);

  Future<List<ProjectModel>> getMyProjects() async {
    try {
      final res = await _dio.get(
        ApiConstants.projects,
        queryParameters: {'per_page': 50},
      );
      return (res.data['data'] as List)
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<TaskModel>> getMyTasks({String? status, String? priority}) async {
    try {
      final params = <String, dynamic>{'per_page': 50};
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (priority != null && priority.isNotEmpty) params['priority'] = priority;

      final res = await _dio.get(ApiConstants.tasks, queryParameters: params);
      return (res.data['data'] as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TaskModel> getTask(int id) async {
    try {
      final res = await _dio.get('${ApiConstants.tasks}/$id');
      return TaskModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TaskModel> updateTaskStatus(int id, String status) async {
    try {
      final res = await _dio.put('${ApiConstants.tasks}/$id', data: {'status': status});
      return TaskModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChecklistItemModel> toggleChecklistItem(int taskId, int itemId) async {
    try {
      final res = await _dio.patch(
        '${ApiConstants.tasks}/$taskId/checklist/$itemId/toggle',
      );
      final data = res.data['data'] as Map<String, dynamic>;
      // Server returns {id, is_done} — reconstruct with minimal fields
      return ChecklistItemModel(
        id: data['id'] as int,
        title: '',
        isDone: data['is_done'] as bool,
        sortOrder: 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
