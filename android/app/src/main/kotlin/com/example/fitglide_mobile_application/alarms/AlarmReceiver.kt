package com.example.fitglide_mobile_application.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        context?.let {
            val alarmIntent = Intent(it, AlarmService::class.java).apply {
                putExtra("vibration", intent?.getBooleanExtra("vibration", false) ?: false)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                it.startForegroundService(alarmIntent) // For Android 8+
            } else {
                it.startService(alarmIntent)
            }
        }
    }
}
