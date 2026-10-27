import 'package:intl/intl.dart';

enum CourseSigningStatus {
  alreadySigned,
  open,
  upcoming,
  closed,
}

class Course {
  final int id;
  final String title;
  final String? teacher;
  final String? room;
  final DateTime startTime;
  final DateTime endTime;
  final int openingDelayMinutes;
  final int closingDelayMinutes;
  final bool closingFromStart;
  final bool isSigned;
  final String? signatureStatus;
  final List<Map<String, dynamic>> beacons;

  const Course({
    required this.id,
    required this.title,
    this.teacher,
    this.room,
    required this.startTime,
    required this.endTime,
    this.openingDelayMinutes = 15,
    this.closingDelayMinutes = 15,
    this.closingFromStart = true,
    this.isSigned = false,
    this.signatureStatus,
    this.beacons = const [],
  });

  /// Calcule l'instant précis où l'émargement s'ouvre
  DateTime get openingTime =>
      startTime.subtract(Duration(minutes: openingDelayMinutes));

  /// Calcule l'instant précis où l'émargement se clôture
  DateTime get closingTime {
    final base = closingFromStart ? startTime : endTime;
    return base.add(Duration(minutes: closingDelayMinutes));
  }

  /// Détermine le statut dynamique actuel du cours
  CourseSigningStatus get currentStatus {
    if (isSigned) {
      return CourseSigningStatus.alreadySigned;
    }
    final now = DateTime.now();
    if (now.isBefore(openingTime)) {
      return CourseSigningStatus.upcoming;
    }
    if (now.isAfter(closingTime)) {
      return CourseSigningStatus.closed;
    }
    return CourseSigningStatus.open;
  }

  /// Temps restant avant l'ouverture (si statut upcoming)
  Duration? get timeUntilOpen {
    final now = DateTime.now();
    if (now.isBefore(openingTime)) {
      return openingTime.difference(now);
    }
    return null;
  }

  /// Temps restant avant la fermeture (si statut open)
  Duration? get timeUntilClose {
    final now = DateTime.now();
    if (now.isAfter(openingTime) && now.isBefore(closingTime)) {
      return closingTime.difference(now);
    }
    return null;
  }

  String get formattedTimeRange {
    final format = DateFormat('HH:mm');
    return '${format.format(startTime)} - ${format.format(endTime)}';
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.parse(val).toLocal();
      }
      return DateTime.now();
    }

    final rawStart = json['start'] ?? json['start_date'] ?? json['begin'];
    final rawEnd = json['end'] ?? json['end_date'];
    
    // Détection de présence
    final presence = json['presence'];
    final signed = json['signed'] == true ||
        (presence != null && presence != false && presence != 'absent');

    final beaconList = <Map<String, dynamic>>[];
    if (json['beacons'] is List) {
      for (final b in json['beacons']) {
        if (b is Map<String, dynamic>) {
          beaconList.add(b);
        }
      }
    }

    return Course(
      id: json['id'] as int? ?? 0,
      title: json['label'] as String? ??
          json['name'] as String? ??
          json['title'] as String? ??
          'Cours sans titre',
      teacher: json['trainer'] as String? ??
          json['teacher'] as String? ??
          (json['trainer_name'] as String?),
      room: json['room'] as String? ??
          json['classroom'] as String? ??
          (json['location'] as String?),
      startTime: parseDate(rawStart),
      endTime: parseDate(rawEnd),
      openingDelayMinutes: json['openingDelay'] as int? ??
          json['opening_delay'] as int? ??
          15,
      closingDelayMinutes: json['closingDelay'] as int? ??
          json['closing_delay'] as int? ??
          15,
      closingFromStart: json['closing_from_start'] as bool? ?? true,
      isSigned: signed,
      signatureStatus: presence is String ? presence : (signed ? 'present' : null),
      beacons: beaconList,
    );
  }
}
