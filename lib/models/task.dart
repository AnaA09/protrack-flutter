import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String taskId;
  final String projectId;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String name;
  final String? description;
  final List<String> requiredInstruments;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? assignedTo;
  final int? priority;
  final Map<String, dynamic>? metadata;

  Task({
    required this.taskId,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.name,
    this.description,
    required this.requiredInstruments,
    this.startDate,
    this.dueDate,
    this.assignedTo,
    this.priority,
    this.metadata,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    String? taskId,
    String? projectId,
    String? createdAt,
    String? updatedAt,
    String? status,
    String? name,
    String? description,
    List<String>? requiredInstruments,
    DateTime? startDate,
    DateTime? dueDate,
    String? assignedTo,
    int? priority,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      requiredInstruments: requiredInstruments ?? this.requiredInstruments,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }
}
