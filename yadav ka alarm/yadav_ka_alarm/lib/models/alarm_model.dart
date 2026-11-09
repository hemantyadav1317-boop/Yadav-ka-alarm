import 'dart:convert';

class AlarmModel {
  final String id;
  final int hour;
  final int minute;
  final String label;
  bool isEnabled;
  final String challengeType; // 'steps', 'math', 'shake', 'typing'
  final int challengeTarget;
  final List<int> days; // 1 = Mon ... 7 = Sun, empty = once

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.isEnabled = true,
    this.challengeType = 'steps',
    this.challengeTarget = 50,
    required this.days,
  });

  String get timeFormatted {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  int getNextTriggerTimestamp() {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute, 0);

    if (days.isEmpty) {
      // One-time alarm
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled.millisecondsSinceEpoch;
    }

    // Repeating alarm
    for (int i = 0; i < 7; i++) {
      final candidate = DateTime(now.year, now.month, now.day, hour, minute, 0).add(Duration(days: i));
      if (candidate.isAfter(now) && days.contains(candidate.weekday)) {
        return candidate.millisecondsSinceEpoch;
      }
    }

    // Fallback tomorrow
    return scheduled.add(const Duration(days: 1)).millisecondsSinceEpoch;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'challengeType': challengeType,
      'challengeTarget': challengeTarget,
      'days': days,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'] ?? '',
      hour: map['hour'] ?? 6,
      minute: map['minute'] ?? 0,
      label: map['label'] ?? 'Wake Up Protocol',
      isEnabled: map['isEnabled'] ?? true,
      challengeType: map['challengeType'] ?? 'steps',
      challengeTarget: map['challengeTarget'] ?? 50,
      days: List<int>.from(map['days'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AlarmModel.fromJson(String source) => AlarmModel.fromMap(jsonDecode(source));
}

