import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String instrumentId; // Primary key in DynamoDB
  final String type; // 'CATEGORY'
  final String labId;
  final String categoryId;
  final String name;
  final String categoryType; // 'INSTRUMENTS', 'CHEMICALS', 'CULTURES'
  final String description;
  final String createdAt;
  final String updatedAt;
  final String status;

  Category({
    required this.instrumentId,
    required this.type,
    required this.labId,
    required this.categoryId,
    required this.name,
    required this.categoryType,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    String? instrumentId,
    String? type,
    String? labId,
    String? categoryId,
    String? name,
    String? categoryType,
    String? description,
    String? createdAt,
    String? updatedAt,
    String? status,
  }) {
    return Category(
      instrumentId: instrumentId ?? this.instrumentId,
      type: type ?? this.type,
      labId: labId ?? this.labId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      categoryType: categoryType ?? this.categoryType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
