import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

const appUrl = 'https://pwa-apk-pro.lovable.app';
const native = MethodChannel('aeon/native');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: AeonShell()));
}

class AeonShell extends StatefulWidget {
  const AeonShell({super.key});
  @override
  State<AeonShell> createState() => _AeonShellState();
}

class _AeonShellState extends State<AeonShell> {
  late final WebViewController web;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    _askPermissions();
    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF020617))
      ..addJavaScriptChannel('AeonNative', onMessageReceived: (m) => _handle(m.message))
      ..loadRequest(Uri.parse(appUrl));
    // Native -> web: alarm fired while app was closed
    native.setMethodCallHandler((call) async {
      if (call.method == 'alarmFired') {
        web.runJavaScript("window.aeonFromNative && window.aeonFromNative('alarmFired', ${jsonEncode(call.arguments)})");
      }
    });
  }

  Future<void> _askPermissions() async {
    await [Permission.notification, Permission.microphone, Permission.sensors,
      Permission.activityRecognition, Permission.scheduleExactAlarm,
      Permission.systemAlertWindow, Permission.ignoreBatteryOptimizations].request();
    await native.invokeMethod('requestFullScreenIntent');
  }

  Future<void> _handle(String raw) async {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'lock':
        setState(() => locked = true);
        await WakelockPlus.enable();
        await native.invokeMethod('lock');
        break;
      case 'unlock':
        setState(() => locked = false);
        await WakelockPlus.disable();
        await native.invokeMethod('unlock');
        break;
      case 'maxVolume':
        await native.invokeMethod('maxVolume');
        break;
      case 'scheduleAlarms':
        await native.invokeMethod('scheduleAlarms', msg['alarms']);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !locked, // back button blocked while alarm ringing
      child: Scaffold(backgroundColor: const Color(0xFF020617),
        body: SafeArea(child: WebViewWidget(controller: web))),
    );
  }
}
