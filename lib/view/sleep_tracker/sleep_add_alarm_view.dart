import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/round_button.dart';
import '../../services/alarm_service.dart';
import '../../services/sleep_provider.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';

class SleepAddAlarmView extends ConsumerStatefulWidget {
  final DateTime date;
  const SleepAddAlarmView({super.key, required this.date});

  @override
  ConsumerState<SleepAddAlarmView> createState() => _SleepAddAlarmViewState();
}

class _SleepAddAlarmViewState extends ConsumerState<SleepAddAlarmView> {
  bool vibrationEnabled = false;
  DateTime? selectedAlarmTime;
  List<String> repeatDays = [];
  static const platform = MethodChannel('fitglide/alarm');


  @override
  void initState() {
    super.initState();
    _fetchAlarms();
  }

Future _fetchAlarms() async {
  try {
    List alarms = await AlarmService.getAlarms();
    if (alarms.isNotEmpty) {
      // Get current date and time
      DateTime now = DateTime.now();
      
      // Filter to get the next alarm (considering alarms set for the next day)
      Alarm nextAlarm = alarms.firstWhere(
        (alarm) => alarm.time.isAfter(now),
        orElse: () => alarms.first,
      ); // If no alarm is for today, take the first one assuming it's for tomorrow or beyond

      setState(() {
        selectedAlarmTime = nextAlarm.time;
        vibrationEnabled = nextAlarm.vibration;
        repeatDays = nextAlarm.repeatDays;
      });
    } else {
      // If no alarms exist, set a default time
      DateTime now = DateTime.now();
      setState(() {
        selectedAlarmTime = DateTime(now.year, now.month, now.day, 7, 0);
      });
    }
  } catch (e) {
    print("Error fetching alarms: $e");
    // Set a default time if fetching fails
    DateTime now = DateTime.now();
    setState(() {
      selectedAlarmTime = now.add(Duration(hours: 1)); // An hour later as a default
    });
  }
}
 // <-- Added missing closing bracket

void _pickAlarmTime() async {
  TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: selectedAlarmTime != null
        ? TimeOfDay.fromDateTime(selectedAlarmTime!)
        : const TimeOfDay(hour: 7, minute: 0),
  );

  if (picked != null) {
    setState(() {
      selectedAlarmTime = DateTime(widget.date.year, widget.date.month, widget.date.day, picked.hour, picked.minute);
    });
  }
}

Future _setNativeAlarm() async {
  if (selectedAlarmTime == null) return;

  try {
    final sleepData = ref.read(sleepDataProvider);

    // Get the current date and time
    DateTime now = DateTime.now();
    
    // Create the alarm date time, ensuring it's for the future
    DateTime alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedAlarmTime!.hour,
      selectedAlarmTime!.minute,
    );
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(Duration(days: 1)); // Set for the next day if the time has passed
    }

    // Calculate the bedtime based on the sleep data
    DateTime bedtime = alarmTime.subtract(
      Duration(hours: sleepData.sleepDuration.toInt(), minutes: ((sleepData.sleepDuration % 1) * 60).toInt()),
    );

    // Prepare the alarm
    Alarm alarm = Alarm(
      time: alarmTime,
      vibration: vibrationEnabled,
      sleepHours: sleepData.sleepDuration,
      repeatDays: repeatDays,
    );

    // Add the alarm using the AlarmService
    await AlarmService.addAlarm(alarm);

    // Call the native Android method to set the alarm
    await platform.invokeMethod('setAlarm', {
      'hour': alarmTime.hour,
      'minute': alarmTime.minute,
      'message': "Wake up! Your FitGlide alarm",
      'vibration': vibrationEnabled,
      'repeatDays': repeatDays, // This is now used for recurring alarms
    });

    print("Native alarm set successfully");

    // Save health vitals and update the UI
    String? jwt = await StorageService.getToken();
    String? healthVitalsDocumentId = await StorageService.getData('health_vitals_document_id');

    if (jwt == null || healthVitalsDocumentId == null) {
      print("Missing authentication details for updating health vitals.");
      return;
    }

    final apiService = DataService();
    await apiService.updateHealthVitals(healthVitalsDocumentId, {
      "bedtime": bedtime.toIso8601String().substring(11, 23),
      "hours_of_sleep": sleepData.sleepDuration.toString(),
    });

    // Refresh alarms to reflect the new alarm added
    await AlarmService.refreshAlarms();
    Navigator.pop(context);
  } on PlatformException catch (e) {
    print("Failed to set native alarm: ${e.message}");
  } catch (e) {
    print("Error updating or adding alarm: $e");
  }
}


void _toggleRepeatDay(String day) {
  setState(() {
    repeatDays.contains(day) ? repeatDays.remove(day) : repeatDays.add(day);
  });
}


  @override
  Widget build(BuildContext context) {
    final sleepData = ref.watch(sleepDataProvider);
    double sleepHours = sleepData.sleepDuration;

    DateTime bedtime = selectedAlarmTime != null
        ? selectedAlarmTime!.subtract(Duration(hours: sleepHours.toInt(), minutes: ((sleepHours % 1) * 60).toInt()))
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: TColor.lightGray, borderRadius: BorderRadius.circular(10)),
            child: Image.asset("assets/img/closed_btn.png", width: 15, height: 15, fit: BoxFit.contain),
          ),
        ),
        title: Text("Edit Alarm", style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      backgroundColor: TColor.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTitleNextRow(
              title: "Bedtime",
              time: DateFormat.jm().format(bedtime),
              icon: "assets/img/Bed_Add.png",
              color: TColor.white,
              onPressed: () {},
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              decoration: BoxDecoration(color: TColor.lightGray, borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset("assets/img/HoursTime.png", width: 21, height: 21),
                      const SizedBox(width: 8),
                      Text("Hours of Sleep", style: TextStyle(color: TColor.gray, fontSize: 12)),
                    ],
                  ),
                  Text("${sleepHours.toStringAsFixed(1)} hrs", style: TextStyle(color: TColor.black, fontSize: 12, )),
                ],
              ),
            ),
            const SizedBox(height: 15),

                        IconTitleNextRow(
              title: "Alarm Time",
              time: selectedAlarmTime != null 
                  ? DateFormat.jm().format(selectedAlarmTime!) 
                  : "--", // Show "--" if no alarm time is set
              icon: "assets/img/alarm.png",
              color: TColor.lightGray,
              onPressed: _pickAlarmTime,),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: TColor.lightGray, borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Image.asset("assets/img/Vibrate.png", width: 18, height: 18),
                title: Text("Vibrate When Alarm Sounds", style: TextStyle(color: TColor.gray, fontSize: 12)),
                trailing: Switch(value: vibrationEnabled, onChanged: (value) => setState(() => vibrationEnabled = value)),
              ),
            ),
            const SizedBox(height: 15),

            Text("Repeat On", style: TextStyle(color: TColor.gray, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                bool isSelected = repeatDays.contains(day);
                return GestureDetector(
                  onTap: () => _toggleRepeatDay(day),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : TColor.lightGray,
                    child: Text(day.substring(0, 2), style: TextStyle(color: isSelected ? Colors.white : TColor.gray, fontSize: 14)),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            RoundButton(title: "Update", onPressed: _setNativeAlarm),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
