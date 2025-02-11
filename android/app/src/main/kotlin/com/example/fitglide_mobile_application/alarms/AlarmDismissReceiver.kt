package com.example.fitglide_mobile_application.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        context?.let {
            val stopIntent = Intent(it, AlarmService::class.java)
            it.stopService(stopIntent)
        }
    }
}
