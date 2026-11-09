import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static const MethodChannel native = MethodChannel('yadav/alarm_native');
  static const String _storageKey = 'yadav_alarms_list';

  static Future<List<AlarmModel>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Return default starter alarm (e.g., 6:00 AM with 50 Steps challenge)
      return [
        AlarmModel(
          id: 'alarm_default_1',
          hour: 6,
          minute: 0,
          label: 'Mission Wakeup 🏃‍♂️',
          challengeType: 'steps',
          challengeTarget: 50,
          days: [1, 2, 3, 4, 5],
        ),
      ];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => AlarmModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final listMap = alarms.map((a) => a.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(listMap));
    await syncWithNative(alarms);
  }

  static Future<void> addAlarm(AlarmModel alarm) async {
    final alarms = await getAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  static Future<void> updateAlarm(AlarmModel alarm) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      alarms[index] = alarm;
      await saveAlarms(alarms);
    }
  }

  static Future<void> deleteAlarm(String id) async {
    final alarms = await getAlarms();
    alarms.removeWhere((a) => a.id == id);
    await native.invokeMethod('cancelAlarm', {'id': id});
    await saveAlarms(alarms);
  }

  static Future<void> toggleAlarm(String id, bool enabled) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      alarms[index].isEnabled = enabled;
      await saveAlarms(alarms);
    }
  }

  static Future<void> syncWithNative(List<AlarmModel> alarms) async {
    final nativeList = alarms.map((a) => {
      'id': a.id,
      'label': a.label,
      'timestamp': a.getNextTriggerTimestamp(),
      'isEnabled': a.isEnabled,
    }).toList();
    await native.invokeMethod('scheduleAlarms', nativeList);
  }

  static Future<void> testAlarmNow(AlarmModel alarm) async {
    // Schedule alarm 4 seconds from now
    final testTs = DateTime.now().add(const Duration(seconds: 4)).millisecondsSinceEpoch;
    final testAlarm = [
      {
        'id': alarm.id,
        'label': 'TEST: ${alarm.label}',
        'timestamp': testTs,
        'isEnabled': true,
      }
    ];
    await native.invokeMethod('scheduleAlarms', testAlarm);
  }
}

