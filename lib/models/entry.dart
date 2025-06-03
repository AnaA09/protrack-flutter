import 'package:json_annotation/json_annotation.dart';

part 'entry.g.dart';

@JsonSerializable()
class Entry {
  final String instrumentId; // Primary key in DynamoDB
  final String type; // 'ENTRY'
  final String categoryId;
  final String labId;
  final String entryId;
  final String name;
  final String? model;
  final String? manufacturer;
  final String? serialNumber;
  final String description;
  final Map<String, dynamic>? specifications;
  final int quantity;
  final int availableQuantity;
  final String? location;
  final String? calibrationDate;
  final String? maintenanceSchedule;
  final String createdAt;
  final String updatedAt;
  final String status; // AVAILABLE, IN_USE, MAINTENANCE, UNAVAILABLE

  Entry({
    required this.instrumentId,
    required this.type,
    required this.categoryId,
    required this.labId,
    required this.entryId,
    required this.name,
    this.model,
    this.manufacturer,
    this.serialNumber,
    required this.description,
    this.specifications,
    required this.quantity,
    required this.availableQuantity,
    this.location,
    this.calibrationDate,
    this.maintenanceSchedule,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);
  Map<String, dynamic> toJson() => _$EntryToJson(this);

  Entry copyWith({
    String? instrumentId,
    String? type,
    String? categoryId,
    String? labId,
    String? entryId,
    String? name,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? description,
    Map<String, dynamic>? specifications,
    int? quantity,
    int? availableQuantity,
    String? location,
    String? calibrationDate,
    String? maintenanceSchedule,
    String? createdAt,
    String? updatedAt,
    String? status,
  }) {
    return Entry(
      instrumentId: instrumentId ?? this.instrumentId,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      labId: labId ?? this.labId,
      entryId: entryId ?? this.entryId,
      name: name ?? this.name,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      location: location ?? this.location,
      calibrationDate: calibrationDate ?? this.calibrationDate,
      maintenanceSchedule: maintenanceSchedule ?? this.maintenanceSchedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  bool get isAvailable => status == 'AVAILABLE' && availableQuantity > 0;
}
