import 'package:intl/intl.dart';

class AlarmCalculator {
  static DateTime calculateBedtime(DateTime wakeUpTime, double sleepDuration) {
    return wakeUpTime.subtract(Duration(hours: sleepDuration.toInt()));
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
}
