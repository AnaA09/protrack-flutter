import 'package:json_annotation/json_annotation.dart';

part 'lab.g.dart';

@JsonSerializable()
class Lab {
  final String instrumentId; // Primary key in DynamoDB
  final String type; // 'LAB'
  final String labId;
  final String name;
  final String description;
  final String location;
  final String createdAt;
  final String updatedAt;
  final String status;

  Lab({
    required this.instrumentId,
    required this.type,
    required this.labId,
    required this.name,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory Lab.fromJson(Map<String, dynamic> json) => _$LabFromJson(json);
  Map<String, dynamic> toJson() => _$LabToJson(this);

  Lab copyWith({
    String? instrumentId,
    String? type,
    String? labId,
    String? name,
    String? description,
    String? location,
    String? createdAt,
    String? updatedAt,
    String? status,
  }) {
    return Lab(
      instrumentId: instrumentId ?? this.instrumentId,
      type: type ?? this.type,
      labId: labId ?? this.labId,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
