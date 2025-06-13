import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

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

  String get formattedStartDateTime {
    try {
      final date = DateTime.parse(startDate);
      final formattedDate = DateFormat('MMM d, yyyy').format(date);
      if (startTime != null) {
        // Parse the time string (HH:mm:ss)
        final timeParts = startTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$formattedDate ${hour12}:$minute $period';
      }
      return formattedDate;
    } catch (e) {
      return startTime != null ? '$startDate $startTime' : startDate;
    }
  }

  String get formattedEndDateTime {
    try {
      final date = DateTime.parse(endDate);
      final formattedDate = DateFormat('MMM d, yyyy').format(date);
      if (endTime != null) {
        // Parse the time string (HH:mm:ss)
        final timeParts = endTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$formattedDate ${hour12}:$minute $period';
      }
      return formattedDate;
    } catch (e) {
      return endTime != null ? '$endDate $endTime' : endDate;
    }
  }

  bool get isActive => status == 'CONFIRMED';

  DateTime get startDateTime {
    if (startTime != null) {
      return DateTime.parse('${startDate}T${startTime}');
    }
    return DateTime.parse(startDate);
  }

  DateTime get endDateTime {
    if (endTime != null) {
      return DateTime.parse('${endDate}T${endTime}');
    }
    return DateTime.parse(endDate);
  }
}
