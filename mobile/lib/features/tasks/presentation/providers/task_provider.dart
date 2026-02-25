import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

// ── Projects (read-only) ──────────────────────────────────────────────────────

final myProjectsProvider = FutureProvider<List<ProjectModel>>(
  (ref) => ref.watch(taskRepositoryProvider).getMyProjects(),
);

// ── Tasks (filterable + mutable) ─────────────────────────────────────────────

class MyTasksNotifier extends AsyncNotifier<List<TaskModel>> {
  String? _statusFilter;
  String? _priorityFilter;

  @override
  Future<List<TaskModel>> build() => ref
      .watch(taskRepositoryProvider)
      .getMyTasks(status: _statusFilter, priority: _priorityFilter);

  void setFilters({String? status, String? priority}) {
    _statusFilter = status;
    _priorityFilter = priority;
    ref.invalidateSelf();
  }

  Future<String?> updateStatus(int taskId, String status) async {
    try {
      await ref.read(taskRepositoryProvider).updateTaskStatus(taskId, status);
      ref.invalidateSelf();
      ref.invalidate(myProjectsProvider);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('ApiException: ', '');
    }
  }
}

final myTasksProvider =
    AsyncNotifierProvider<MyTasksNotifier, List<TaskModel>>(() => MyTasksNotifier());

// ── Task detail (family per taskId) ─────────────────────────────────────────

final taskDetailProvider = FutureProvider.family<TaskModel, int>(
  (ref, id) => ref.watch(taskRepositoryProvider).getTask(id),
);
