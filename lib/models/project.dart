import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

@JsonSerializable()
class Project {
  final String projectId;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String status;
  final String name;
  final String? description;
  final List<String> requiredInstruments;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? metadata;

  Project({
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.status,
    required this.name,
    this.description,
    required this.requiredInstruments,
    this.startDate,
    this.endDate,
    this.metadata,
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? projectId,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? status,
    String? name,
    String? description,
    List<String>? requiredInstruments,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
  }) {
    return Project(
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      requiredInstruments: requiredInstruments ?? this.requiredInstruments,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadata: metadata ?? this.metadata,
    );
  }
}
