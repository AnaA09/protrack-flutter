import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@JsonSerializable()
class Activity {
  final String activityId;
  final String taskId;
  final String projectId;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String name;
  final String? description;
  final List<String> usedInstruments;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? performedBy;
  final Map<String, dynamic>? results;
  final Map<String, dynamic>? metadata;

  Activity({
    required this.activityId,
    required this.taskId,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.name,
    this.description,
    required this.usedInstruments,
    this.startTime,
    this.endTime,
    this.performedBy,
    this.results,
    this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  Activity copyWith({
    String? activityId,
    String? taskId,
    String? projectId,
    String? createdAt,
    String? updatedAt,
    String? status,
    String? name,
    String? description,
    List<String>? usedInstruments,
    DateTime? startTime,
    DateTime? endTime,
    String? performedBy,
    Map<String, dynamic>? results,
    Map<String, dynamic>? metadata,
  }) {
    return Activity(
      activityId: activityId ?? this.activityId,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      usedInstruments: usedInstruments ?? this.usedInstruments,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      performedBy: performedBy ?? this.performedBy,
      results: results ?? this.results,
      metadata: metadata ?? this.metadata,
    );
  }
}
