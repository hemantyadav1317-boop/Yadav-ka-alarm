package com.yadav.alarm.yadav_ka_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || 
            action == "android.intent.action.QUICKBOOT_POWERON" || 
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            val prefs = context.getSharedPreferences("yadav_alarm_prefs", Context.MODE_PRIVATE)
            val alarmsJson = prefs.getString("saved_alarms", null) ?: return
            
            try {
                val array = JSONArray(alarmsJson)
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val now = System.currentTimeMillis()
                
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val id = obj.getString("id")
                    val label = obj.optString("label", "Yadav Alarm")
                    var timestamp = obj.getLong("timestamp")
                    val isEnabled = obj.optBoolean("isEnabled", true)
                    
                    if (!isEnabled) continue
                    
                    // If the time already passed in the past, roll it over to tomorrow or calculate next
                    while (timestamp <= now) {
                        timestamp += 24 * 60 * 60 * 1000L
                    }
                    
                    val fireIntent = Intent(context, AlarmReceiver::class.java).apply {
                        putExtra("alarmId", id)
                        putExtra("label", label)
                    }
                    val pi = PendingIntent.getBroadcast(
                        context, 
                        id.hashCode(), 
                        fireIntent, 
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    val showIntent = PendingIntent.getActivity(
                        context, 
                        0, 
                        Intent(context, MainActivity::class.java), 
                        PendingIntent.FLAG_IMMUTABLE
                    )
                    am.setAlarmClock(AlarmManager.AlarmClockInfo(timestamp, showIntent), pi)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}

