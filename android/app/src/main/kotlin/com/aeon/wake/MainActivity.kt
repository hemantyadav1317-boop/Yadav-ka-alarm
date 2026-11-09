package com.aeon.wake

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var locked = false
    private lateinit var channel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Show over lock screen & turn screen on when alarm fires
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "aeon/native")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "lock" -> { locked = true; try { startLockTask() } catch (_: Exception) {}; maxVolume(); result.success(null) }
                "unlock" -> { locked = false; try { stopLockTask() } catch (_: Exception) {}; result.success(null) }
                "maxVolume" -> { maxVolume(); result.success(null) }
                "scheduleAlarms" -> { schedule(call.arguments as List<Map<String, Any>>); result.success(null) }
                "requestFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT >= 34) startActivity(Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        intent?.getStringExtra("alarmId")?.let { channel.invokeMethod("alarmFired", mapOf("id" to it)) }
    }

    private fun maxVolume() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        am.setStreamVolume(AudioManager.STREAM_MUSIC, am.getStreamMaxVolume(AudioManager.STREAM_MUSIC), 0)
        am.setStreamVolume(AudioManager.STREAM_ALARM, am.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0)
    }

    // Swallow volume keys while ringing and force volume back to max
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (locked && (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_MUTE)) {
            maxVolume(); return true
        }
        return super.onKeyDown(keyCode, event)
    }

    // If user leaves via home/recents, bring app straight back
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (locked) startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT))
    }

    private fun schedule(alarms: List<Map<String, Any>>) {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.forEachIndexed { i, a ->
            val ts = (a["timestamp"] as Number).toLong()
            val fire = Intent(this, AlarmReceiver::class.java).putExtra("alarmId", a["id"] as String).putExtra("label", a["label"] as String)
            val pi = PendingIntent.getBroadcast(this, 1000 + i, fire, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val show = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
            am.setAlarmClock(AlarmManager.AlarmClockInfo(ts, show), pi)
        }
    }
}
