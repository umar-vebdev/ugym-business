/// Status of a generated group class session.
enum ClassSessionStatus {
  scheduled('scheduled'),
  cancelled('cancelled');

  const ClassSessionStatus(this.apiValue);

  final String apiValue;

  static ClassSessionStatus fromApi(String? raw) {
    return switch (raw) {
      'cancelled' => ClassSessionStatus.cancelled,
      _ => ClassSessionStatus.scheduled,
    };
  }
}

/// Status of a client booking for a group class session.
enum ClassBookingStatus {
  booked('booked'),
  cancelled('cancelled');

  const ClassBookingStatus(this.apiValue);

  final String apiValue;

  static ClassBookingStatus fromApi(String? raw) {
    return switch (raw) {
      'cancelled' => ClassBookingStatus.cancelled,
      _ => ClassBookingStatus.booked,
    };
  }
}

/// Trainer profile attached to a gym branch.
final class TrainerProfile {
  const TrainerProfile({
    required this.id,
    required this.publicId,
    required this.gymId,
    required this.name,
    required this.isActive,
    this.userId,
    this.bio,
  });

  final int id;
  final String publicId;
  final int gymId;
  final int? userId;
  final String name;
  final String? bio;
  final bool isActive;
}

/// Weekly recurring schedule template for group classes.
final class ScheduleTemplate {
  const ScheduleTemplate({
    required this.id,
    required this.publicId,
    required this.gymId,
    required this.trainerId,
    required this.title,
    required this.weekday,
    required this.startTimeMinute,
    required this.durationMinutes,
    required this.capacity,
    required this.isActive,
    this.description,
  });

  final int id;
  final String publicId;
  final int gymId;
  final int trainerId;
  final String title;
  final String? description;
  final int weekday;
  final int startTimeMinute;
  final int durationMinutes;
  final int capacity;
  final bool isActive;

  String get formattedStartTime {
    final hours = (startTimeMinute ~/ 60).toString().padLeft(2, '0');
    final minutes = (startTimeMinute % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

/// Concrete generated group class slot.
final class ClassSession {
  const ClassSession({
    required this.id,
    required this.publicId,
    required this.gymId,
    required this.templateId,
    required this.trainerId,
    required this.title,
    required this.capacity,
    required this.bookedCount,
    required this.availableSeats,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final int id;
  final String publicId;
  final int gymId;
  final int templateId;
  final int trainerId;
  final String title;
  final int capacity;
  final int bookedCount;
  final int availableSeats;
  final DateTime startsAt;
  final DateTime endsAt;
  final ClassSessionStatus status;
}

/// Client booking entry for a group class session.
final class ClassBooking {
  const ClassBooking({
    required this.id,
    required this.publicId,
    required this.companyId,
    required this.gymId,
    required this.sessionId,
    required this.clientId,
    required this.status,
    required this.bookedAt,
    this.membershipId,
    this.cancelledAt,
  });

  final int id;
  final String publicId;
  final int companyId;
  final int gymId;
  final int sessionId;
  final int clientId;
  final int? membershipId;
  final ClassBookingStatus status;
  final DateTime bookedAt;
  final DateTime? cancelledAt;
}

/// Contract for trainers and group class schedule operations.
abstract interface class TrainersScheduleRepository {
  Future<List<TrainerProfile>> listTrainers({required int gymId});

  Future<TrainerProfile> createTrainer({
    required int gymId,
    required String name,
    String? bio,
  });

  Future<TrainerProfile> updateTrainer({
    required int trainerId,
    required String name,
    String? bio,
    bool? isActive,
  });

  Future<List<ScheduleTemplate>> listTemplates({
    required int gymId,
    bool? onlyActive,
  });

  Future<ScheduleTemplate> createTemplate({
    required int gymId,
    required int trainerId,
    required String title,
    String? description,
    required int weekday,
    required int startTimeMinute,
    required int durationMinutes,
    required int capacity,
  });

  Future<ScheduleTemplate> updateTemplate({
    required int templateId,
    required int trainerId,
    required String title,
    String? description,
    required int weekday,
    required int startTimeMinute,
    required int durationMinutes,
    required int capacity,
    bool? isActive,
  });

  Future<List<ClassSession>> listSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  });

  Future<List<ClassSession>> generateSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  });

  Future<ClassSession> cancelSession({required int sessionId});

  Future<List<ClassBooking>> listSessionBookings({required int sessionId});
}
