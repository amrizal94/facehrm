import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/task_remote_datasource.dart';
import '../models/checklist_item_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(taskRemoteDataSourceProvider)),
);

class TaskRepository {
  final TaskRemoteDataSource _ds;
  TaskRepository(this._ds);

  Future<List<ProjectModel>> getMyProjects() => _ds.getMyProjects();
  Future<List<TaskModel>> getMyTasks({String? status, String? priority}) =>
      _ds.getMyTasks(status: status, priority: priority);
  Future<TaskModel> getTask(int id) => _ds.getTask(id);
  Future<TaskModel> updateTaskStatus(int id, String status) =>
      _ds.updateTaskStatus(id, status);
  Future<ChecklistItemModel> toggleChecklistItem(int taskId, int itemId) =>
      _ds.toggleChecklistItem(taskId, itemId);
}
