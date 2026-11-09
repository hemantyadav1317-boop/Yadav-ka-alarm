package com.yadav.alarm.yadav_ka_alarm

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.sqrt

class MainActivity : FlutterActivity(), SensorEventListener {
    private var locked = false
    private lateinit var channel: MethodChannel
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var accelSensor: Sensor? = null
    private var stepCount = 0
    private var isTrackingSteps = false
    
    // Simple accelerometer peak detection fallback
    private var lastAccelMagnitude = 9.8f
    private var lastStepTime = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Show over lockscreen and turn screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
        
        initVibrator()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
        accelSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    }

    private fun initVibrator() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val alarmId = intent.getStringExtra("alarmId")
        if (alarmId != null && ::channel.isInitialized) {
            channel.invokeMethod("alarmFired", mapOf("id" to alarmId, "label" to (intent.getStringExtra("label") ?: "Yadav Wake Alert")))
        }
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "yadav/alarm_native")
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "lock" -> {
                    locked = true
                    try { startLockTask() } catch (_: Exception) {}
                    maxVolume()
                    startAlarmAlert()
                    result.success(null)
                }
                "unlock" -> {
                    locked = false
                    try { stopLockTask() } catch (_: Exception) {}
                    stopAlarmAlert()
                    stopStepTracker()
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    nm.cancel(999)
                    result.success(null)
                }
                "maxVolume" -> {
                    maxVolume()
                    result.success(null)
                }
                "startAlarmSound" -> {
                    startAlarmAlert()
                    result.success(null)
                }
                "stopAlarmSound" -> {
                    stopAlarmAlert()
                    result.success(null)
                }
                "scheduleAlarms" -> {
                    val alarms = call.arguments as? List<Map<String, Any>>
                    if (alarms != null) {
                        schedule(alarms)
                    }
                    result.success(null)
                }
                "cancelAlarm" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        cancelAlarmById(id)
                    }
                    result.success(null)
                }
                "startStepTracker" -> {
                    startStepTracker()
                    result.success(null)
                }
                "stopStepTracker" -> {
                    stopStepTracker()
                    result.success(null)
                }
                "playCyberSound" -> {
                    val soundType = call.argument<String>("type") ?: "click"
                    val freq = call.argument<Double>("freq") ?: 0.0
                    playCyberSound(soundType, freq)
                    result.success(null)
                }
                "requestFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        try {
                            startActivity(Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$packageName")))
                        } catch (_: Exception) {}
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // If launched with an alarm intent
        intent?.getStringExtra("alarmId")?.let {
            channel.invokeMethod("alarmFired", mapOf("id" to it, "label" to (intent.getStringExtra("label") ?: "Yadav Wake Alert")))
        }
    }

    // Zero-latency PCM Audio Synthesizer for instant futuristic sci-fi sound effects
    private fun playCyberSound(type: String, extraFreq: Double = 0.0) {
        Thread {
            try {
                val sampleRate = 22050
                val durationMs = when (type) {
                    "click" -> 45
                    "toggle_on" -> 70
                    "toggle_off" -> 70
                    "keypad" -> 40
                    "confirm", "disarm" -> 160
                    "error" -> 110
                    "swipe" -> 35
                    else -> 40
                }
                val numSamples = (durationMs * sampleRate) / 1000
                val samples = ShortArray(numSamples)
                
                for (i in 0 until numSamples) {
                    val t = i.toDouble() / sampleRate
                    val progress = i.toDouble() / numSamples
                    val amp = (1.0 - progress) * 0.75
                    
                    val freq = when (type) {
                        "click" -> 850.0 + progress * 1100.0 // 850Hz -> 1950Hz upward cyber chirp
                        "toggle_on" -> if (progress < 0.5) 440.0 else 880.0
                        "toggle_off" -> if (progress < 0.5) 880.0 else 330.0
                        "keypad" -> if (extraFreq > 0) extraFreq else 950.0 + (progress * 200.0)
                        "confirm", "disarm" -> when {
                            progress < 0.33 -> 587.33
                            progress < 0.66 -> 880.0
                            else -> 1174.66
                        }
                        "error" -> 260.0 - progress * 140.0
                        "swipe" -> 400.0 + Math.sin(progress * Math.PI) * 300.0
                        else -> 900.0
                    }
                    
                    val wave = Math.sin(2.0 * Math.PI * freq * t)
                    samples[i] = (wave * amp * Short.MAX_VALUE).toInt().toShort()
                }
                
                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(samples.size * 2)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()
                    
                track.write(samples, 0, samples.size)
                track.play()
                Thread.sleep(durationMs.toLong() + 20)
                track.release()
            } catch (_: Exception) {}
        }.start()
    }

    private fun maxVolume() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            am.setStreamVolume(AudioManager.STREAM_MUSIC, am.getStreamMaxVolume(AudioManager.STREAM_MUSIC), 0)
            am.setStreamVolume(AudioManager.STREAM_ALARM, am.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0)
        } catch (_: Exception) {}
    }

    private fun startAlarmAlert() {
        maxVolume()
        // Play looping loud alarm
        if (mediaPlayer == null) {
            try {
                var uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                if (uri == null) {
                    uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                }
                mediaPlayer = MediaPlayer().apply {
                    setDataSource(applicationContext, uri)
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    isLooping = true
                    prepare()
                    start()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        // Looping vibration pattern
        try {
            val pattern = longArrayOf(0, 600, 200, 600, 200, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {}
    }

    private fun stopAlarmAlert() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null
        try {
            vibrator?.cancel()
        } catch (_: Exception) {}
    }

    private fun startStepTracker() {
        stepCount = 0
        isTrackingSteps = true
        if (stepSensor != null) {
            sensorManager?.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_FASTEST)
        } else if (accelSensor != null) {
            sensorManager?.registerListener(this, accelSensor, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    private fun stopStepTracker() {
        isTrackingSteps = false
        sensorManager?.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (!isTrackingSteps || event == null) return
        
        if (event.sensor.type == Sensor.TYPE_STEP_DETECTOR) {
            stepCount++
            runOnUiThread {
                channel.invokeMethod("stepDetected", mapOf("steps" to stepCount))
            }
        } else if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]
            val magnitude = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
            val now = System.currentTimeMillis()
            
            // Peak detection for steps: threshold jump > 11.8 m/s^2 and debounce >= 280ms
            if (magnitude > 11.8f && lastAccelMagnitude <= 11.8f && (now - lastStepTime > 280)) {
                lastStepTime = now
                stepCount++
                runOnUiThread {
                    channel.invokeMethod("stepDetected", mapOf("steps" to stepCount))
                }
            }
            lastAccelMagnitude = magnitude
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // Force volume back to max if user tries to lower it while ringing
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (locked && (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || 
                       keyCode == KeyEvent.KEYCODE_VOLUME_UP || 
                       keyCode == KeyEvent.KEYCODE_VOLUME_MUTE)) {
            maxVolume()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    // Force app back to front if user leaves via Home / Gestures
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (locked) {
            val frontIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(frontIntent)
        }
    }

    private fun schedule(alarms: List<Map<String, Any>>) {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val jsonArray = JSONArray()
        
        alarms.forEach { a ->
            val id = a["id"] as String
            val label = (a["label"] as? String) ?: "Yadav Wake Alert"
            val ts = (a["timestamp"] as Number).toLong()
            val isEnabled = (a["isEnabled"] as? Boolean) ?: true
            
            val obj = JSONObject().apply {
                put("id", id)
                put("label", label)
                put("timestamp", ts)
                put("isEnabled", isEnabled)
            }
            jsonArray.put(obj)
            
            if (isEnabled) {
                val fire = Intent(this, AlarmReceiver::class.java).apply {
                    putExtra("alarmId", id)
                    putExtra("label", label)
                }
                val pi = PendingIntent.getBroadcast(
                    this, 
                    id.hashCode(), 
                    fire, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val show = PendingIntent.getActivity(
                    this, 
                    0, 
                    Intent(this, MainActivity::class.java), 
                    PendingIntent.FLAG_IMMUTABLE
                )
                am.setAlarmClock(AlarmManager.AlarmClockInfo(ts, show), pi)
            } else {
                cancelAlarmById(id)
            }
        }
        
        // Save to SharedPreferences so BootReceiver can recover it after reboot
        val prefs = getSharedPreferences("yadav_alarm_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("saved_alarms", jsonArray.toString()).apply()
    }

    private fun cancelAlarmById(id: String) {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val fire = Intent(this, AlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            this, 
            id.hashCode(), 
            fire, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.cancel(pi)
    }

    override fun onDestroy() {
        stopAlarmAlert()
        stopStepTracker()
        super.onDestroy()
    }
}
