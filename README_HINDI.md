# AEON → Android APK (Flutter) गाइड

## 1. Setup (Laptop पर)
1. Flutter SDK + Android Studio install करें, `flutter doctor` चलाएं।
2. `flutter create --org com.aeon --project-name aeon_wake aeon_wake`
3. इस ZIP की files उसी folder में copy करके overwrite करें:
   - `pubspec.yaml`, `lib/main.dart`
   - `android/app/src/main/AndroidManifest.xml`
   - `android/app/src/main/kotlin/com/aeon/wake/*.kt` (पुरानी MainActivity.kt हटा दें)
4. `android/app/build.gradle` में `minSdk = 26` और dependency `implementation "androidx.core:core-ktx:1.13.1"` डालें।
5. `flutter pub get` → `flutter build apk --release`
6. APK: `build/app/outputs/flutter-apk/app-release.apk`

## 2. Install के बाद Phone पर permissions (ज़रूरी)
- Notifications, Alarms & reminders, Full-screen notifications: Allow
- Display over other apps: Allow
- Battery → AEON → Unrestricted (Xiaomi/Vivo/Oppo में "Autostart" भी ON)
- Settings → Security → **App pinning / Screen pinning: ON**

## 3. कैसे काम करता है
- Web app (`src/lib/native-bridge.ts`) `AeonNative` channel से Flutter को message भेजता है:
  `lock`, `unlock`, `maxVolume`, `scheduleAlarms`
- Alarms Android **AlarmManager.setAlarmClock** में जाते हैं → phone lock/app बंद होने पर भी बजेगा।
- Alarm बजते ही: screen on, lock screen के ऊपर app खुलेगा, `startLockTask()` से screen pin,
  Volume keys block + volume हमेशा max, Back button block, Home दबाने पर app वापस आ जाएगा।
- सारे challenges पूरे होने पर ही `unlock` भेजा जाता है।

## 4. ईमानदार सीमाएं
- Normal app में Android, screen pinning के समय एक बार "Pin this app?" पूछता है और
  Back+Recents लंबा दबाकर निकलना संभव रहता है। 100% पक्का lock सिर्फ **Device Owner** mode में:
  `adb shell dpm set-device-owner com.aeon.wake/.AdminReceiver` (इसके लिए DeviceAdminReceiver
  और phone से सारे accounts हटाने पड़ते हैं — advanced)।
- Power button से phone बंद (switch off) करना कोई भी app नहीं रोक सकता।
- Play Store पर ये permissions review में reject हो सकती हैं — खुद के use के लिए APK sideload करें।
