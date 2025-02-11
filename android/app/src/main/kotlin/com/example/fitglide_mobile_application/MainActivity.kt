package com.example.fitglide_mobile_application

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fitglide/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlarms" -> {
                    val alarms = getAlarmsFromSystem()
                    result.success(alarms)
                }
                "setAlarm" -> {
                    val hour = call.argument<Int>("hour")
                    if (hour == null) return@setMethodCallHandler
                    val minute = call.argument<Int>("minute")
                    if (minute == null) return@setMethodCallHandler
                    val repeatDays = call.argument<List<String>>("repeatDays") ?: listOf<String>()
                    val vibration = call.argument<Boolean>("vibration") ?: false

                    setAlarm(hour, minute, repeatDays, vibration)
                    result.success("Alarm Set")
                }
                "updateAlarm" -> {
                    val oldHour = call.argument<Int>("oldHour")
                    if (oldHour == null) return@setMethodCallHandler
                    val oldMinute = call.argument<Int>("oldMinute")
                    if (oldMinute == null) return@setMethodCallHandler
                    val newHour = call.argument<Int>("newHour")
                    if (newHour == null) return@setMethodCallHandler
                    val newMinute = call.argument<Int>("newMinute")
                    if (newMinute == null) return@setMethodCallHandler
                    val repeatDays = call.argument<List<String>>("repeatDays") ?: listOf<String>()
                    val vibration = call.argument<Boolean>("vibration") ?: false

                    updateAlarm(oldHour, oldMinute, newHour, newMinute, repeatDays, vibration)
                    result.success("Alarm Updated")
                }
                "cancelAlarm" -> {
                    val hour = call.argument<Int>("hour")
                    if (hour == null) return@setMethodCallHandler
                    val minute = call.argument<Int>("minute")
                    if (minute == null) return@setMethodCallHandler

                    cancelAlarm(hour, minute)
                    result.success("Alarm Canceled")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getAlarmsFromSystem(): List<Map<String, Any>> {
        val alarms = ArrayList<Map<String, Any>>()
        
        // Example: Adding one alarm for demonstration. In a real scenario, you'd fetch these from a system or database.
        alarms.add(mapOf(
            "time" to getNextAlarmTime(),
            "duration" to calculateDuration(getNextAlarmTime())
        ))
        
        return alarms
    }

    private fun setAlarm(hour: Int, minute: Int, repeatDays: List<String>, vibration: Boolean) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("vibration", vibration)
        }
        val requestCode = hour * 60 + minute
        val pendingIntent = PendingIntent.getBroadcast(
            this, requestCode, intent, getPendingIntentFlags()
        )

        val calendar = Calendar.getInstance().apply { // Use device's local timezone
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_MONTH, 1) // Set for the next day if time has already passed
            }
        }

        if (repeatDays.isNotEmpty()) {
            // Convert repeat days (e.g., ["Monday", "Wednesday"]) to actual calendar days
            for (day in repeatDays) {
                val dayOfWeek = getDayOfWeek(day)
                val repeatCalendar = calendar.clone() as Calendar
                repeatCalendar.set(Calendar.DAY_OF_WEEK, dayOfWeek)

                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    repeatCalendar.timeInMillis,
                    AlarmManager.INTERVAL_DAY * 7,
                    pendingIntent
                )
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }

        Toast.makeText(this, "Alarm set for $hour:$minute", Toast.LENGTH_LONG).show()
    }

    private fun updateAlarm(oldHour: Int, oldMinute: Int, newHour: Int, newMinute: Int, repeatDays: List<String>, vibration: Boolean) {
        cancelAlarm(oldHour, oldMinute)
        setAlarm(newHour, newMinute, repeatDays, vibration)
    }

    private fun cancelAlarm(hour: Int, minute: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val requestCode = hour * 60 + minute
        val pendingIntent = PendingIntent.getBroadcast(
            this, requestCode, intent, getPendingIntentFlags()
        )

        alarmManager.cancel(pendingIntent)
        Toast.makeText(this, "Alarm canceled at $hour:$minute", Toast.LENGTH_LONG).show()
    }

    private fun getPendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    private fun getDayOfWeek(day: String): Int {
        return when (day.lowercase()) {
            "sunday" -> Calendar.SUNDAY
            "monday" -> Calendar.MONDAY
            "tuesday" -> Calendar.TUESDAY
            "wednesday" -> Calendar.WEDNESDAY
            "thursday" -> Calendar.THURSDAY
            "friday" -> Calendar.FRIDAY
            "saturday" -> Calendar.SATURDAY
            else -> Calendar.MONDAY // Default case
        }
    }

    private fun getNextAlarmTime(): String {
        val currentTime = Calendar.getInstance() // Use device's local timezone
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US) // No need for 'Z' as we're not using UTC
        
        // Example: Set alarm for 7:30 AM local time daily
        currentTime.set(Calendar.HOUR_OF_DAY, 7)
        currentTime.set(Calendar.MINUTE, 30)
        currentTime.set(Calendar.SECOND, 0)
        currentTime.set(Calendar.MILLISECOND, 0)
        
        // If the alarm time has passed for today, set it for tomorrow
        if (currentTime.before(Calendar.getInstance())) {
            currentTime.add(Calendar.DAY_OF_MONTH, 1)
        }
        
        return formatter.format(currentTime.time)
    }

    private fun calculateDuration(alarmTimeString: String): Int {
        val alarmTime = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(alarmTimeString)
        val currentTime = Calendar.getInstance().time // Use local time
        
        val durationInMillis = alarmTime.time - currentTime.time
        val durationInMinutes = TimeUnit.MILLISECONDS.toMinutes(durationInMillis)
        
        return durationInMinutes.toInt()
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val vibration = intent.getBooleanExtra("vibration", false)

        Toast.makeText(context, "Alarm Triggered!", Toast.LENGTH_LONG).show()

        // TODO: Play a sound or show a notification
    }
}
