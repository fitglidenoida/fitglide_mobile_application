import 'package:fitglide_mobile_application/services/alarm_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sleepDataProvider = StateNotifierProvider<SleepDataNotifier, SleepData>(
  (ref) => SleepDataNotifier(),
);

class SleepData {
  final double sleepDuration;
  final DateTime wakeUpTime;
  final DateTime bedtime;

  SleepData({required this.sleepDuration, required this.wakeUpTime, required this.bedtime});
}

class SleepDataNotifier extends StateNotifier<SleepData> {
  SleepDataNotifier()
      : super(SleepData(sleepDuration: 7.5, wakeUpTime: DateTime.now(), bedtime: DateTime.now()));

  void updateSleepData(double sleepDuration, DateTime wakeUpTime) {
    DateTime bedtime = AlarmCalculator.calculateBedtime(wakeUpTime, sleepDuration);
    state = SleepData(sleepDuration: sleepDuration, wakeUpTime: wakeUpTime, bedtime: bedtime);
  }
}
