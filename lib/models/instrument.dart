import 'package:json_annotation/json_annotation.dart';

part 'instrument.g.dart';

@JsonSerializable()
class Instrument {
  final String instrumentId;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String name;
  final String? description;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? location;
  final Map<String, dynamic>? metadata;

  Instrument({
    required this.instrumentId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.name,
    this.description,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.location,
    this.metadata,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) =>
      _$InstrumentFromJson(json);
  Map<String, dynamic> toJson() => _$InstrumentToJson(this);

  Instrument copyWith({
    String? instrumentId,
    String? createdAt,
    String? updatedAt,
    String? status,
    String? name,
    String? description,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return Instrument(
      instrumentId: instrumentId ?? this.instrumentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
    );
  }
}
