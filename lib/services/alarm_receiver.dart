class AlarmReceiver {
  static void handleAlarmNotification(int alarmId) {
    if (alarmId >= 1000) {  // Custom ID range for Fitglide alarms
      print("Fitglide Alarm Triggered: $alarmId");
      // Log wake-up time & update sleep data
    } else {
      print("Ignoring non-Fitglide alarm");
    }
  }
}
