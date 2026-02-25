import 'checklist_item_model.dart';
import 'label_model.dart';

class TaskModel {
  final int id;
  final int projectId;
  final String? projectName;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? deadline;
  final String? assigneeName;
  final List<LabelModel> labels;
  final List<ChecklistItemModel> checklistItems;
  final int checklistTotal;
  final int checklistDone;

  const TaskModel({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.deadline,
    this.assigneeName,
    required this.labels,
    required this.checklistItems,
    required this.checklistTotal,
    required this.checklistDone,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final projectJson = json['project'] as Map<String, dynamic>?;
    final assigneeJson = json['assignee'] as Map<String, dynamic>?;
    final assigneeUser = assigneeJson?['user'] as Map<String, dynamic>?;
    final assigneeName = assigneeUser?['name'] as String?;

    final labelsJson = json['labels'] as List<dynamic>?;
    final labels = labelsJson != null
        ? labelsJson.map((e) => LabelModel.fromJson(e as Map<String, dynamic>)).toList()
        : <LabelModel>[];

    final checklistJson = json['checklist_items'] as List<dynamic>?;
    final checklistItems = checklistJson != null
        ? checklistJson
            .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ChecklistItemModel>[];

    return TaskModel(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      projectName: projectJson?['name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      deadline: json['deadline'] as String?,
      assigneeName: assigneeName,
      labels: labels,
      checklistItems: checklistItems,
      checklistTotal: json['checklist_total'] as int? ?? checklistItems.length,
      checklistDone: json['checklist_done'] as int? ??
          checklistItems.where((i) => i.isDone).length,
    );
  }

  TaskModel copyWith({
    String? status,
    List<ChecklistItemModel>? checklistItems,
  }) =>
      TaskModel(
        id: id,
        projectId: projectId,
        projectName: projectName,
        title: title,
        description: description,
        status: status ?? this.status,
        priority: priority,
        deadline: deadline,
        assigneeName: assigneeName,
        labels: labels,
        checklistItems: checklistItems ?? this.checklistItems,
        checklistTotal: checklistTotal,
        checklistDone: checklistDone,
      );
}
