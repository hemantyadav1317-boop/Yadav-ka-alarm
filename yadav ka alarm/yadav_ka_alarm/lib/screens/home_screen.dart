import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';
import '../services/update_service.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<AlarmModel> _alarms = [];
  bool _isLoading = true;
  String _currentTime = '';
  String _currentDate = '';
  double _secondsProgress = 0.0;
  Timer? _clockTimer;
  UpdateInfo? _updateInfo;

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startClock();
    _loadAlarms();
    _checkPermissions();
    _checkAutoUpdate();
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
        _currentDate = DateFormat('yyyy.MM.dd // EEEE').format(now).toUpperCase();
        _secondsProgress = now.second / 60.0;
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

  Future<void> _checkAutoUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info != null && info.hasUpdate && mounted) {
      setState(() => _updateInfo = info);
      _showUpdateDialog(info);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    SoundService.confirm();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF020617),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.system_update_alt_rounded, color: Color(0xFF22D3EE)),
            SizedBox(width: 10),
            Text(
              'NEW FIRMWARE DETECTED',
              style: TextStyle(color: Color(0xFF22D3EE), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: v${info.remoteVersionName} (Build ${info.remoteVersionCode})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('DIRECTIVE CHANGELOG:', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
              child: Text(info.changelog, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundService.click();
              Navigator.pop(ctx);
            },
            child: const Text('DISMISS', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22D3EE)),
            onPressed: () {
              SoundService.confirm();
              Navigator.pop(ctx);
            },
            child: const Text('UPGRADE NOW', style: TextStyle(color: Color(0xFF020617), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAlarm(AlarmModel alarm, bool val) async {
    SoundService.toggle(val);
    await AlarmService.toggleAlarm(alarm.id, val);
    await _loadAlarms();
  }

  Future<void> _deleteAlarm(String id) async {
    SoundService.error();
    await AlarmService.deleteAlarm(id);
    await _loadAlarms();
  }

  void _openAddAlarmSheet([AlarmModel? existing]) {
    SoundService.click();
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : TimeOfDay.now();
    String label = existing?.label ?? 'Mission Directive';
    String challenge = existing?.challengeType ?? 'steps';
    int target = existing?.challengeTarget ?? 50;
    List<int> selectedDays = existing?.days != null ? List.from(existing!.days) : [1, 2, 3, 4, 5, 6, 7];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF020617),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF22D3EE), width: 1),
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
                        decoration: BoxDecoration(color: const Color(0xFF22D3EE).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      existing == null ? '🛰️ // NEW DIRECTIVE SEQUENCE //' : '✏️ // CONFIGURE SEQUENCE //',
                      style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Time Picker Button
                    InkWell(
                      onTap: () async {
                        SoundService.click();
                        final picked = await showTimePicker(context: context, initialTime: selectedTime);
                        if (picked != null) {
                          SoundService.click();
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('SEQUENCE TIME:', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2)),
                            Text(
                              selectedTime.format(context),
                              style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
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
                        labelText: 'DIRECTIVE LABEL',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 1),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22D3EE))),
                      ),
                      onChanged: (val) => label = val,
                    ),

                    const SizedBox(height: 16),
                    const Text('DISARM PROTOCOL:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 10),

                    // Challenge Selector (2 rows)
                    Row(
                      children: [
                        _challengeChip('steps', '🏃 STEPS // RUN', challenge, (c) {
                          SoundService.click();
                          setSheetState(() {
                            challenge = c;
                            target = 50;
                          });
                        }),
                        const SizedBox(width: 8),
                        _challengeChip('math', '🧠 NEURAL MATH', challenge, (c) {
                          SoundService.click();
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
                        _challengeChip('shake', '📱 SENSOR SHAKE', challenge, (c) {
                          SoundService.click();
                          setSheetState(() {
                            challenge = c;
                            target = 30;
                          });
                        }),
                        const SizedBox(width: 8),
                        _challengeChip('typing', '✍️ TERMINAL TYPING', challenge, (c) {
                          SoundService.click();
                          setSheetState(() {
                            challenge = c;
                            target = 1;
                          });
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),
                    if (challenge == 'steps') ...[
                      Text('TARGET STEPS: $target (~${(target * 0.75 / 1000).toStringAsFixed(1)} KM)',
                          style: const TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Slider(
                        value: target.toDouble(),
                        min: 20,
                        max: 5000,
                        divisions: 50,
                        label: '$target steps',
                        activeColor: const Color(0xFF22D3EE),
                        onChanged: (val) {
                          SoundService.swipe();
                          setSheetState(() => target = val.toInt());
                        },
                      ),
                    ] else if (challenge == 'math') ...[
                      Text('NEURAL QUESTIONS: $target PROBLEMS', style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Slider(
                        value: target.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$target questions',
                        activeColor: const Color(0xFFA855F7),
                        onChanged: (val) {
                          SoundService.swipe();
                          setSheetState(() => target = val.toInt());
                        },
                      ),
                    ] else if (challenge == 'shake') ...[
                      Text('SENSOR THRESHOLD: $target SHAKES', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Slider(
                        value: target.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 18,
                        label: '$target shakes',
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) {
                          SoundService.swipe();
                          setSheetState(() => target = val.toInt());
                        },
                      ),
                    ] else if (challenge == 'typing') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'Type the exact neural wake phrase in the disarm terminal to clear alarm.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22D3EE),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        SoundService.confirm();
                        final newAlarm = AlarmModel(
                          id: existing?.id ?? 'alarm_${DateTime.now().millisecondsSinceEpoch}',
                          hour: selectedTime.hour,
                          minute: selectedTime.minute,
                          label: label.isEmpty ? 'Neural Protocol' : label,
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
                        existing == null ? 'ARM DIRECTIVE' : 'UPDATE DIRECTIVE',
                        style: const TextStyle(color: Color(0xFF020617), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
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
            color: isSelected ? const Color(0xFF22D3EE).withValues(alpha: 0.15) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF22D3EE) : Colors.white24, width: isSelected ? 1.5 : 1.0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF22D3EE) : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.shield_rounded, color: Color(0xFF22D3EE)),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YADAV KA ALARM',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 16),
                ),
                Text(
                  'NEURAL WAKE PROTOCOL // HUD',
                  style: TextStyle(color: Color(0xFF22D3EE), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_updateInfo != null && _updateInfo!.hasUpdate)
            IconButton(
              tooltip: 'New Firmware Available',
              icon: const Icon(Icons.download_rounded, color: Color(0xFF22D3EE)),
              onPressed: () => _showUpdateDialog(_updateInfo!),
            ),
          IconButton(
            tooltip: 'Sound FX Test',
            icon: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF22D3EE)),
            onPressed: () {
              SoundService.confirm();
            },
          ),
          IconButton(
            tooltip: 'Permissions Status',
            icon: const Icon(Icons.security_rounded, color: Color(0xFFA855F7)),
            onPressed: () {
              SoundService.click();
              _checkPermissions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE)))
          : Column(
              children: [
                // Sci-Fi Circular Radar Clock
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF22D3EE).withValues(alpha: 0.08), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating Radar Sweeper Arc
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              value: _secondsProgress,
                              strokeWidth: 4,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                              backgroundColor: Colors.white10,
                            ),
                          ),
                          // Glowing Center Clock
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentTime.split(' ')[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                _currentTime.split(' ').length > 1 ? _currentTime.split(' ')[1] : '',
                                style: const TextStyle(
                                  color: Color(0xFF22D3EE),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _currentDate,
                        style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace', letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),

                // Directives Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '// ACTIVE SEQUENCES //',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      Text(
                        '${_alarms.where((a) => a.isEnabled).length} ARMED',
                        style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),

                // List of Alarms
                Expanded(
                  child: _alarms.isEmpty
                      ? const Center(
                          child: Text(
                            'NO PROTOCOLS ARMED\nTAP [+] TO ENGAGE SEQUENCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white24, fontFamily: 'monospace', letterSpacing: 1.5),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        backgroundColor: const Color(0xFF22D3EE),
        icon: const Icon(Icons.add, color: Color(0xFF020617)),
        label: const Text('ARM NEW SEQUENCE', style: TextStyle(color: Color(0xFF020617), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
      challengeTitle = '[PROTOCOL: ${alarm.challengeTarget} STEPS (~${(alarm.challengeTarget * 0.75 / 1000).toStringAsFixed(1)} KM)]';
      chipColor = const Color(0xFF22D3EE);
    } else if (alarm.challengeType == 'math') {
      icon = Icons.calculate_rounded;
      challengeTitle = '[PROTOCOL: ${alarm.challengeTarget} NEURAL MATH]';
      chipColor = const Color(0xFFA855F7);
    } else if (alarm.challengeType == 'shake') {
      icon = Icons.vibration_rounded;
      challengeTitle = '[PROTOCOL: ${alarm.challengeTarget} SENSOR SHAKES]';
      chipColor = Colors.orangeAccent;
    } else {
      icon = Icons.keyboard_rounded;
      challengeTitle = '[PROTOCOL: TERMINAL TYPING]';
      chipColor = Colors.yellowAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alarm.isEnabled ? const Color(0xFF22D3EE).withValues(alpha: 0.5) : Colors.white10,
          width: alarm.isEnabled ? 1.5 : 1.0,
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
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                activeThumbColor: const Color(0xFF22D3EE),
                onChanged: (val) => _toggleAlarm(alarm, val),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alarm.isEnabled ? const Color(0xFF22D3EE) : Colors.white24,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                alarm.isEnabled ? 'ARMED // STANDING BY' : 'STANDBY // DORMANT',
                style: TextStyle(
                  color: alarm.isEnabled ? const Color(0xFF22D3EE) : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: chipColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challengeTitle,
                  style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF22D3EE), size: 16),
                label: const Text('TEST', style: TextStyle(color: Color(0xFF22D3EE), fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  SoundService.confirm();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AlarmScreen(alarm: alarm)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                onPressed: () => _deleteAlarm(alarm.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
