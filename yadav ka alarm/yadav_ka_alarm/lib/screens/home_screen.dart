import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlarmModel> _alarms = [];
  bool _isLoading = true;
  String _currentTime = '';
  String _currentDate = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadAlarms();
    _checkPermissions();
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('hh:mm:ss a').format(now);
        _currentDate = DateFormat('EEEE, d MMMM yyyy').format(now);
      });
    }
  }

  Future<void> _loadAlarms() async {
    final alarms = await AlarmService.getAlarms();
    if (mounted) {
      setState(() {
        _alarms = alarms;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.systemAlertWindow,
      Permission.ignoreBatteryOptimizations,
      Permission.activityRecognition,
      Permission.sensors,
    ].request();
    await AlarmService.native.invokeMethod('requestFullScreenIntent');
  }

  Future<void> _toggleAlarm(AlarmModel alarm, bool val) async {
    await AlarmService.toggleAlarm(alarm.id, val);
    await _loadAlarms();
  }

  Future<void> _deleteAlarm(String id) async {
    await AlarmService.deleteAlarm(id);
    await _loadAlarms();
  }

  void _openAddAlarmSheet([AlarmModel? existing]) {
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : TimeOfDay.now();
    String label = existing?.label ?? 'Morning Wakeup';
    String challenge = existing?.challengeType ?? 'steps';
    int target = existing?.challengeTarget ?? 50;
    List<int> selectedDays = existing?.days != null ? List.from(existing!.days) : [1, 2, 3, 4, 5, 6, 7];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      existing == null ? '⏰ Naya Alarm Banayein' : '✏️ Alarm Edit Karein',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Time Picker Button
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: selectedTime);
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Alarm Samay:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            Text(
                              selectedTime.format(context),
                              style: const TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Label Input
                    TextField(
                      controller: TextEditingController(text: label),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Alarm Name / Label',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) => label = val,
                    ),

                    const SizedBox(height: 16),
                    const Text('Wakeup Challenge Chuniye:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Challenge Selector (2 rows for all 4 challenges)
                    Row(
                      children: [
                        _challengeChip('steps', '🏃 Steps/Run', challenge, (c) {
                          setSheetState(() {
                            challenge = c;
                            target = 50;
                          });
                        }),
                        const SizedBox(width: 8),
                        _challengeChip('math', '🧠 Maths', challenge, (c) {
                          setSheetState(() {
                            challenge = c;
                            target = 3;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _challengeChip('shake', '📱 Phone Shake', challenge, (c) {
                          setSheetState(() {
                            challenge = c;
                            target = 30;
                          });
                        }),
                        const SizedBox(width: 8),
                        _challengeChip('typing', '✍️ Typing Quote', challenge, (c) {
                          setSheetState(() {
                            challenge = c;
                            target = 1;
                          });
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),
                    if (challenge == 'steps') ...[
                      Text('Target Steps: $target (~${(target * 0.75 / 1000).toStringAsFixed(1)} KM)',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Slider(
                        value: target.toDouble(),
                        min: 20,
                        max: 5000,
                        divisions: 50,
                        label: '$target steps',
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          setSheetState(() => target = val.toInt());
                        },
                      ),
                    ] else if (challenge == 'math') ...[
                      Text('Math Questions: $target Sawaal', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      Slider(
                        value: target.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$target problems',
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) {
                          setSheetState(() => target = val.toInt());
                        },
                      ),
                    ] else if (challenge == 'shake') ...[
                      Text('Target Shakes: $target Baar Hilayein', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      Slider(
                        value: target.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 18,
                        label: '$target shakes',
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) {
                          setSheetState(() => target = val.toInt());
                        },
                      ),
                    ] else if (challenge == 'typing') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'अलार्म बंद करने के लिए प्रेरणादायक वाक्य बिना किसी गलती के टाइप करना होगा।',
                          style: TextStyle(color: Colors.yellowAccent, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final newAlarm = AlarmModel(
                          id: existing?.id ?? 'alarm_${DateTime.now().millisecondsSinceEpoch}',
                          hour: selectedTime.hour,
                          minute: selectedTime.minute,
                          label: label.isEmpty ? 'Yadav Wake Protocol' : label,
                          challengeType: challenge,
                          challengeTarget: target,
                          days: selectedDays,
                          isEnabled: true,
                        );

                        if (existing == null) {
                          await AlarmService.addAlarm(newAlarm);
                        } else {
                          await AlarmService.updateAlarm(newAlarm);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadAlarms();
                      },
                      child: Text(
                        existing == null ? 'ALARM SET KAREIN' : 'UPDATE KAREIN',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _challengeChip(String type, String label, String current, Function(String) onSelect) {
    final isSelected = type == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.redAccent : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.redAccent : Colors.white24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.shield_rounded, color: Colors.redAccent),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'YADAV KA ALARM',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sabhi Permissions Check Karein',
            icon: const Icon(Icons.security_rounded, color: Colors.greenAccent),
            onPressed: _checkPermissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Column(
              children: [
                // Top Live Digital Clock Widget
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1E293B), const Color(0xFF0F172A).withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withValues(alpha: 0.1), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentDate,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Extreme Anti-Snooze & Physical Lock Active',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Alarms List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SAVED ALARMS',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Text(
                        '${_alarms.where((a) => a.isEnabled).length} ACTIVE',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // List of Alarms
                Expanded(
                  child: _alarms.isEmpty
                      ? const Center(
                          child: Text(
                            'Koi alarm nahi hai.\nNeeche + dabakar alarm set karein!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _alarms.length,
                          itemBuilder: (context, index) {
                            final alarm = _alarms[index];
                            return _alarmCard(alarm);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NEW ALARM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openAddAlarmSheet(),
      ),
    );
  }

  Widget _alarmCard(AlarmModel alarm) {
    IconData icon;
    String challengeTitle;
    Color chipColor;

    if (alarm.challengeType == 'steps') {
      icon = Icons.directions_run_rounded;
      challengeTitle = '${alarm.challengeTarget} Steps (~${(alarm.challengeTarget * 0.75 / 1000).toStringAsFixed(1)} KM)';
      chipColor = Colors.greenAccent;
    } else if (alarm.challengeType == 'math') {
      icon = Icons.calculate_rounded;
      challengeTitle = '${alarm.challengeTarget} Math Problems';
      chipColor = Colors.cyanAccent;
    } else if (alarm.challengeType == 'shake') {
      icon = Icons.vibration_rounded;
      challengeTitle = '${alarm.challengeTarget} Phone Shakes';
      chipColor = Colors.orangeAccent;
    } else {
      icon = Icons.keyboard_rounded;
      challengeTitle = 'Typing Wakeup Quote';
      chipColor = Colors.yellowAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alarm.isEnabled ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alarm.timeFormatted,
                style: TextStyle(
                  color: alarm.isEnabled ? Colors.white : Colors.white38,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                activeThumbColor: Colors.redAccent,
                onChanged: (val) => _toggleAlarm(alarm, val),
              ),
            ],
          ),
          Text(
            alarm.label,
            style: TextStyle(color: alarm.isEnabled ? Colors.white70 : Colors.white24, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: chipColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: chipColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      challengeTitle,
                      style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Test Alarm Button
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.yellowAccent, size: 18),
                label: const Text('TEST NOW', style: TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AlarmScreen(alarm: alarm)),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                onPressed: () => _deleteAlarm(alarm.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
