import 'package:flutter/services.dart';
import 'alarm_service.dart';

class SoundService {
  static void click() {
    HapticFeedback.selectionClick();
    AlarmService.native.invokeMethod('playCyberSound', {'type': 'click'});
  }

  static void toggle(bool on) {
    HapticFeedback.lightImpact();
    AlarmService.native.invokeMethod('playCyberSound', {
      'type': on ? 'toggle_on' : 'toggle_off',
    });
  }

  static void keypad(int key) {
    HapticFeedback.selectionClick();
    final freq = 800.0 + (key * 90.0);
    AlarmService.native.invokeMethod('playCyberSound', {
      'type': 'keypad',
      'freq': freq,
    });
  }

  static void confirm() {
    HapticFeedback.mediumImpact();
    AlarmService.native.invokeMethod('playCyberSound', {'type': 'confirm'});
  }

  static void error() {
    HapticFeedback.heavyImpact();
    AlarmService.native.invokeMethod('playCyberSound', {'type': 'error'});
  }

  static void swipe() {
    HapticFeedback.selectionClick();
    AlarmService.native.invokeMethod('playCyberSound', {'type': 'swipe'});
  }
}

