import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final String bookingId;
  final String entryId;
  final String userId;
  final String startDate;
  final String endDate;
  final String? startTime;
  final String? endTime;
  final String purpose;
  final String notes;
  final String status; // CONFIRMED, CANCELLED, COMPLETED
  final String createdAt;
  final String updatedAt;
  final String? userFullName;

  Booking({
    required this.bookingId,
    required this.entryId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.purpose,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userFullName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

  Booking copyWith({
    String? bookingId,
    String? entryId,
    String? userId,
    String? startDate,
    String? endDate,
    String? startTime,
    String? endTime,
    String? purpose,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      entryId: entryId ?? this.entryId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'CONFIRMED';

  DateTime get startDateTime => DateTime.parse(startDate);
  DateTime get endDateTime => DateTime.parse(endDate);
}
