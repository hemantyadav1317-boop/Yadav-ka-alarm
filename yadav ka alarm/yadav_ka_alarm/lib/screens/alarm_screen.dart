import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  final AlarmModel alarm;
  const AlarmScreen({super.key, required this.alarm});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Step Tracker State
  int _currentSteps = 0;
  
  // Math Challenge State
  int _mathSolvedCount = 0;
  int get _mathTarget => widget.alarm.challengeTarget > 0 ? widget.alarm.challengeTarget : 3;
  late int _num1;
  late int _num2;
  late String _operator;
  late int _expectedAnswer;
  String _userAnswer = '';

  // Shake Challenge State
  int _currentShakes = 0;
  StreamSubscription? _accelerometerSub;
  double _lastShakeAccel = 0.0;
  DateTime _lastShakeTime = DateTime.now();

  // Typing Challenge State
  final String _typingTargetPhrase = 'Main aaj aalas chhodkar apne lakshya ko prapt karunga';
  final TextEditingController _typingController = TextEditingController();

  bool _isDisarmed = false;

  @override
  void initState() {
    super.initState();
    _initAlert();
    _generateMathProblem();
    _setupSensors();
  }

  Future<void> _initAlert() async {
    await WakelockPlus.enable();
    await AlarmService.native.invokeMethod('lock');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(_pulseController);

    // Listen to native step counter events
    AlarmService.native.setMethodCallHandler((call) async {
      if (call.method == 'stepDetected') {
        final steps = (call.arguments['steps'] as num?)?.toInt() ?? (_currentSteps + 1);
        if (mounted && widget.alarm.challengeType == 'steps') {
          setState(() {
            _currentSteps = steps;
          });
          if (_currentSteps >= widget.alarm.challengeTarget) {
            _disarm();
          }
        }
      }
    });

    if (widget.alarm.challengeType == 'steps') {
      await AlarmService.native.invokeMethod('startStepTracker');
    }
  }

  void _setupSensors() {
    if (widget.alarm.challengeType == 'shake') {
      _accelerometerSub = accelerometerEventStream().listen((event) {
        final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final now = DateTime.now();
        if (magnitude > 14.0 && _lastShakeAccel <= 14.0 && now.difference(_lastShakeTime).inMilliseconds > 250) {
          _lastShakeTime = now;
          setState(() {
            _currentShakes++;
          });
          if (_currentShakes >= widget.alarm.challengeTarget) {
            _disarm();
          }
        }
        _lastShakeAccel = magnitude;
      });
    }
  }

  void _generateMathProblem() {
    final rand = Random();
    _num1 = rand.nextInt(40) + 12;
    _num2 = rand.nextInt(30) + 5;
    if (rand.nextBool()) {
      _operator = '+';
      _expectedAnswer = _num1 + _num2;
    } else {
      _operator = '-';
      if (_num1 < _num2) {
        final temp = _num1;
        _num1 = _num2;
        _num2 = temp;
      }
      _expectedAnswer = _num1 - _num2;
    }
    _userAnswer = '';
  }

  void _submitMathKey(String key) {
    if (key == 'DEL') {
      if (_userAnswer.isNotEmpty) {
        setState(() => _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1));
      }
    } else if (key == 'ENTER') {
      if (int.tryParse(_userAnswer) == _expectedAnswer) {
        setState(() {
          _mathSolvedCount++;
          if (_mathSolvedCount >= _mathTarget) {
            _disarm();
          } else {
            _generateMathProblem();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Galat jawab! Phir se prayas karein.'), backgroundColor: Colors.red),
        );
        setState(() => _userAnswer = '');
      }
    } else {
      if (_userAnswer.length < 5) {
        setState(() => _userAnswer += key);
      }
    }
  }

  Future<void> _disarm() async {
    if (_isDisarmed) return;
    setState(() => _isDisarmed = true);
    _accelerometerSub?.cancel();
    _pulseController.stop();

    await WakelockPlus.disable();
    await AlarmService.native.invokeMethod('unlock');

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('🎉 MISSION ACCOMPLISHED', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          content: Text(
            'Aapne successfully challenge poora kar liya!\n\nAlarm band ho chuka hai. Ab uthiye aur apne din ki shuruat kijiye!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK, MAIN UTH GAYA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _pulseController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Back button completely blocked
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: Column(
            children: [
              // Header Alert Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.red.shade900,
                child: const Column(
                  children: [
                    Text(
                      '🚨 RED ALERT — WAKE PROTOCOL 🚨',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Volume & Back button locked until protocol completed!',
                      style: TextStyle(color: Colors.yellowAccent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                widget.alarm.label.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                widget.alarm.timeFormatted,
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 16),

              // Dynamic Challenge View
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChallengeWidget(),
                ),
              ),

              // Bottom status bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Yadav Ka Alarm • Extreme Anti-Snooze Mode',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeWidget() {
    switch (widget.alarm.challengeType) {
      case 'steps':
        return _buildStepsChallenge();
      case 'math':
        return _buildMathChallenge();
      case 'shake':
        return _buildShakeChallenge();
      case 'typing':
        return _buildTypingChallenge();
      default:
        return _buildStepsChallenge();
    }
  }

  // 1. STEPS / WALKING / RUNNING CHALLENGE
  Widget _buildStepsChallenge() {
    final target = widget.alarm.challengeTarget;
    final progress = (_currentSteps / target).clamp(0.0, 1.0);
    final distanceKm = (_currentSteps * 0.75 / 1000).toStringAsFixed(2);
    final targetKm = (target * 0.75 / 1000).toStringAsFixed(2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.1),
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
            child: const Icon(Icons.directions_run_rounded, size: 70, color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'BED CHHODIYE AUR CHALIYE / DAUDIYE!',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          'Target: $target Steps (~$targetKm KM)',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Live Step Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 22,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Steps: $_currentSteps / $target', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Distance: $distanceKm KM', style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hardware Step Detector active: Phone ko hath me lekar chaliye ya daudiye.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. MATH CHALLENGE
  Widget _buildMathChallenge() {
    return Column(
      children: [
        Text(
          'Solve Math Problems (${_mathSolvedCount + 1}/$_mathTarget)',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$_num1 $_operator $_num2 = ${_userAnswer.isEmpty ? "?" : _userAnswer}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 20),

        // Custom Numeric Keypad
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              for (var i = 1; i <= 9; i++) _keypadButton('$i'),
              _keypadButton('DEL', color: Colors.orangeAccent),
              _keypadButton('0'),
              _keypadButton('ENTER', color: Colors.greenAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keypadButton(String text, {Color? color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _submitMathKey(text),
      child: Text(
        text,
        style: TextStyle(
          color: color != null ? Colors.black : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 3. SHAKE CHALLENGE
  Widget _buildShakeChallenge() {
    final target = widget.alarm.challengeTarget;
    final progress = (_currentShakes / target).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: const Icon(Icons.vibration_rounded, size: 80, color: Colors.orangeAccent),
        ),
        const SizedBox(height: 20),
        const Text(
          'PHONE KO ZOR SE HILAIYE (SHAKE)!',
          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text('Target: $target Shakes', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 30),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 20,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
          ),
        ),
        const SizedBox(height: 16),
        Text('$_currentShakes / $target Shakes', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // 4. TYPING CHALLENGE
  Widget _buildTypingChallenge() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text('Neeche likha vakya bina galti type karein:', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _typingTargetPhrase,
              style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _typingController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Yahan type karein...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              if (_typingController.text.trim() == _typingTargetPhrase) {
                _disarm();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vakya match nahi hua. Bilkul sahi type karein!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('SUBMIT & DISARM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
