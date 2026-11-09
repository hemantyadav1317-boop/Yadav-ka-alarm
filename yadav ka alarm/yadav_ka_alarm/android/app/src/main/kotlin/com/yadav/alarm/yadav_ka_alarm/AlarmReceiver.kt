package com.yadav.alarm.yadav_ka_alarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val id = intent.getStringExtra("alarmId") ?: "default_alarm"
        val label = intent.getStringExtra("label") ?: "YADAV KA ALARM"
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val channelId = "yadav_alarm_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(channelId, "Yadav Wake Alert", NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
                )
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }
            nm.createNotificationChannel(ch)
        }
        
        val open = Intent(ctx, MainActivity::class.java).apply {
            putExtra("alarmId", id)
            putExtra("label", label)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        }
        val pi = PendingIntent.getActivity(
            ctx, 
            0, 
            open, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(ctx, channelId)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("🚨 RED ALERT: $label")
            .setContentText("Complete the physical wakeup protocol to disarm!")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pi, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
            
        nm.notify(999, notification)
        ctx.startActivity(open)
    }
}

