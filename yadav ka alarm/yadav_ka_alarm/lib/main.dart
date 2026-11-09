import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/alarm_model.dart';
import 'services/alarm_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const YadavAlarmApp());
}

class YadavAlarmApp extends StatefulWidget {
  const YadavAlarmApp({super.key});

  @override
  State<YadavAlarmApp> createState() => _YadavAlarmAppState();
}

class _YadavAlarmAppState extends State<YadavAlarmApp> {
  @override
  void initState() {
    super.initState();
    _listenToNativeAlarms();
  }

  void _listenToNativeAlarms() {
    AlarmService.native.setMethodCallHandler((call) async {
      if (call.method == 'alarmFired') {
        final id = call.arguments['id'] as String? ?? 'default';
        final label = call.arguments['label'] as String? ?? 'Wakeup Protocol';
        
        // Find alarm from local storage or create fallback
        final alarms = await AlarmService.getAlarms();
        final targetAlarm = alarms.firstWhere(
          (a) => a.id == id,
          orElse: () => AlarmModel(
            id: id,
            hour: DateTime.now().hour,
            minute: DateTime.now().minute,
            label: label,
            challengeType: 'steps',
            challengeTarget: 50,
            days: [],
          ),
        );

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AlarmScreen(alarm: targetAlarm),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Yadav Ka Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.greenAccent,
          surface: Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
