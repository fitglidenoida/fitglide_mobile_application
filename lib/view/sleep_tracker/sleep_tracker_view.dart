import 'package:fitglide_mobile_application/common_widget/health_widget.dart';
import 'package:fitglide_mobile_application/services/health_service.dart';
import 'package:fitglide_mobile_application/services/sleep_calculator.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/today_sleep_schedule_row.dart';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SleepTrackerView extends StatefulWidget {
  const SleepTrackerView({super.key});

  @override
  State<SleepTrackerView> createState() => _SleepTrackerViewState();
}

class _SleepTrackerViewState extends State<SleepTrackerView> {
  List<Map<String, dynamic>> sleepData = [];
  Map<String, dynamic> lastNightSleep = {};
  List<Map<String, dynamic>> todaySleepArr = [];

  @override
  void initState() {
    super.initState();
    _fetchAlarms();
  }

  Future<List<Map<String, dynamic>>> getAlarmsFromDevice() async {
    try {
      final List<dynamic> alarms = await platform.invokeMethod('getAlarms');
      log("Alarms fetched from device: $alarms");

      List<Map<String, dynamic>> filteredAlarms = [];
      DateTime now = DateTime.now();
      for (var alarm in alarms) {
        try {
          var alarmTime = DateTime.parse(alarm['time']); 
          var localAlarmTime = alarmTime.toLocal(); 
          
          if (localAlarmTime.isAfter(now)) {
            String formattedDisplayTime = DateFormat("hh:mm a").format(localAlarmTime);
            print("formattedDisplayTime: $formattedDisplayTime"); // Add this to log the formatted time
            Duration durationUntilAlarm = localAlarmTime.difference(now);
            String durationText = _formatDuration(durationUntilAlarm);

            filteredAlarms.add({
              "name": "Alarm",
              "image": "assets/img/alarm.png",
              "time": formattedDisplayTime,
              "duration": durationText
            });
          }
        } catch (e) {
          log("Error parsing alarm time: ${alarm['time']} - $e");
        }
      }
      // Sort by time to ensure the next closest alarm is first
      filteredAlarms.sort((a, b) => DateFormat("hh:mm a").parse(a['time']).compareTo(DateFormat("hh:mm a").parse(b['time'])));
      return filteredAlarms;
    } catch (e) {
      log("Error fetching alarms: $e");
      return [];
    }
  }

  DateTime _getNextAlarmDate(DateTime now, DateTime alarmTime) {
    DateTime alarmDateTime = DateTime(now.year, now.month, now.day, alarmTime.hour, alarmTime.minute);
    if (alarmDateTime.isBefore(now)) {
      alarmDateTime = alarmDateTime.add(const Duration(days: 1));
    }
    return alarmDateTime;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours h $minutes min";
  }

  Future<void> _fetchAlarms() async {
    try {
      List<Map<String, dynamic>> alarms = await getAlarmsFromDevice();
      setState(() {
        todaySleepArr = alarms;
        _addBedtimeToSleepArr();
        log("Updated todaySleepArr with alarms: $todaySleepArr");
      });
    } catch (e) {
      log("Failed to fetch alarms: $e");
    }
  }

 void _addBedtimeToSleepArr() {
  UserService.fetchUserData().then((user) {
    if (user != null) {
      int userAge = user.age;
      double workoutHours = 1.0; // Example value, should be dynamically fetched
      double sleepHours = SleepCalculator.getRecommendedSleepDuration(userAge, workoutHours);
        
      DateTime now = DateTime.now();
      String cleanTime = cleanTimeString(todaySleepArr.isNotEmpty ? todaySleepArr.first['time'] : '');
        
      DateTime? wakeUpTime;
      try {
        wakeUpTime = todaySleepArr.isNotEmpty 
            ? DateFormat('hh:mm a').parse(cleanTime)
            : null;
      } catch (e) {
        print("Error parsing time: $e with string: ${todaySleepArr.isNotEmpty ? todaySleepArr.first['time'] : 'no alarms'}");
        wakeUpTime = null;
      }
        
      DateTime? bedtime = wakeUpTime != null 
          ? _calculateBedtime(wakeUpTime, sleepHours, now)
          : null;
        
      if (bedtime != null) {
        Duration durationUntilBed = bedtime.difference(now);
        String durationText = _formatDuration(durationUntilBed); // This line uses the updated function

        setState(() {
          todaySleepArr.insert(0, {
            "name": "Bedtime",
            "image": "assets/img/bed.png",
            "time": DateFormat("hh:mm a").format(bedtime),
            "duration": durationText
          });
        });
      }
    }
  });
}


DateTime _calculateBedtime(DateTime wakeUpTime, double sleepHours, DateTime now) {
  DateTime baseBedtime = wakeUpTime.subtract(Duration(
    hours: sleepHours.toInt(), 
    minutes: ((sleepHours % 1) * 60).toInt()
  ));

  if (baseBedtime.isBefore(now)) {

      // If bedtime is before current time, move it to the next day
    return DateTime(now.year, now.month, now.day + 1, baseBedtime.hour, baseBedtime.minute);
    }
    return baseBedtime;
  }

String _formatBedDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String sign = duration.isNegative ? "-" : "";
  int hours = duration.inHours.abs();
  int minutes = duration.inMinutes.remainder(60).abs();

  // This part handles both scenarios: for alarms and bedtime
  if (duration.isNegative) {
    return "${sign}${hours}h ${twoDigits(minutes)}m";
  } else {
    return "${hours}h ${twoDigits(minutes)}m";
  }
}

  static const platform = MethodChannel('fitglide/alarm');

  void _scheduleNotification(Map<String, dynamic> alarm) async {
    try {
      if (alarm['time'] is! String) {
        log("Error: Alarm time is not a string: ${alarm['time']}");
        return;
      }

      DateTime? alarmTime;
      try {
        alarmTime = DateTime.parse(alarm['time'].toString());
        print("Parsed alarm time: $alarmTime");
      } catch (e) {
        print("Error parsing alarm time: ${alarm['time']} - Exception: $e");
        return;
      }

      final String alarmId = DateTime.now().millisecondsSinceEpoch.toString();

      Map<String, String> payload = {
        'title': 'Wake Up!',
        'body': 'It\'s time to wake up for your scheduled alarm!',
      };

      final Map<String, String> args = {
        'id': alarmId,
        'time': alarmTime.millisecondsSinceEpoch.toString(),
        'title': payload['title']!,
        'body': payload['body']!,
      };

      await platform.invokeMethod('scheduleNotification', args);
      log("Notification scheduled successfully for alarm at $alarmTime");
    } catch (e) {
      log("Error scheduling notification: $e");
    }
  }

  String cleanTimeString(String time) {
    return time
        .replaceAll(RegExp(r'[^\d:APM\s]'), '') 
        .replaceAll(RegExp(r'\s+'), ' ') 
        .replaceAll(RegExp(r'at\s*\d+'), '') 
        .trim(); 
  }

  @pragma('vm:entry-point')
  static void _showNotification(int id, Map<String, dynamic> params) {
    log("Notification scheduled for alarm with id: $id and params: $params");
  }

  void alarmCallback() {
    log("Alarm Triggered!");
  }

  Future<void> _refreshData() async {
    await _fetchAlarms();
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 500));
  }

  List<int> showingTooltipOnSpots = [4];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Sleep Tracker",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          _buildAppBarIcon("assets/img/more_btn.png", () {}),
        ],
      ),
      backgroundColor: TColor.white,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealthWidget(
                healthService: HealthService(),
                onHealthDataFetched: (healthData) => _processSleepData(healthData),
              ),
              if (sleepData.isNotEmpty)
                _buildLineChart(media),
              const SizedBox(height: 20),
              _buildLastNightSleepCard(media),
              const SizedBox(height: 20),
              _buildDailySleepSchedule(),
              const SizedBox(height: 20),
              _buildTodaySchedule(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarIcon(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: TColor.lightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset(
          assetPath,
          width: 10,
          height: 10,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLineChart(Size media) {
    List<FlSpot> defaultSpots = List.generate(7, (index) => FlSpot((index + 1).toDouble(), 0.0));

    return SizedBox(
      height: media.width * 0.5,
      child: LineChart(
        LineChartData(
          showingTooltipIndicators: showingTooltipOnSpots.map((index) {
            return ShowingTooltipIndicators([
              LineBarSpot(lineBarsData[0], 0, lineBarsData[0].spots[index]),
            ]);
          }).toList(),
          lineTouchData: _buildLineTouchData(),
          lineBarsData: [
            _buildLineChartBarData(
              sleepData.isNotEmpty 
                  ? sleepData.map((e) => FlSpot(sleepData.indexOf(e) + 1, e['total'])).toList() 
                  : defaultSpots,
              [TColor.primaryColor2, TColor.primaryColor1]),
          ],
          minY: -0.01,
          maxY: 10.01,
          titlesData: _buildTitlesData(),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: TColor.gray.withOpacity(0.15),
              strokeWidth: 2,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildLastNightSleepCard(Size media) {
    return Container(
      width: double.infinity,
      height: media.width * 0.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: TColor.primaryG),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "Last Night Sleep",
              style: TextStyle(color: TColor.white, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "${lastNightSleep['total']?.toStringAsFixed(1)}h",
              style: TextStyle(
                color: TColor.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Image.asset(
            "assets/img/SleepGraph.png",
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildDailySleepSchedule() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: TColor.primaryColor2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Daily Sleep Schedule",
            style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(
            width: 75,
            height: 30,
            child: RoundButton(
              title: "Check",
              type: RoundButtonType.bgGradient,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SleepScheduleView(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upcoming Schedule",
          style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: todaySleepArr.length,
          itemBuilder: (context, index) {
            String cleanTime = todaySleepArr[index]['time'].replaceAll(RegExp(r'\s+'), ' ').trim();
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50.0),
              child: TodaySleepScheduleRow(
                sObj: {
                  ...todaySleepArr[index],
                  'time': cleanTime,
                },
              ),
            );
          },
        ),
      ],
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: bottomTitles),
      rightTitles: AxisTitles(sideTitles: rightTitles),
      topTitles: const AxisTitles(),
      leftTitles: const AxisTitles(),
    );
  }

  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: false,
      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
        if (response != null && response.lineBarSpots != null) {
          setState(() {
            showingTooltipOnSpots = [
              response.lineBarSpots!.first.spotIndex
            ];
          });
        }
      },
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: (value, meta) {
          const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          return Text(days[value.toInt() - 1],
              style: TextStyle(color: TColor.gray, fontSize: 12));
        },
      );

  SideTitles get rightTitles => SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: 2,
        getTitlesWidget: (value, meta) {
          return Text('${value.toInt()}h',
              style: TextStyle(color: TColor.gray, fontSize: 12));
        },
      );

  List<LineChartBarData> get lineBarsData {
    return [
      _buildLineChartBarData(
          sleepData.map((e) => FlSpot(sleepData.indexOf(e) + 1, e['total'])).toList(),
          [TColor.primaryColor2, TColor.primaryColor1]),
    ];
  }

  bool get isLoading => false;

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, List<Color> gradientColors) {
    return LineChartBarData(
      isCurved: true,
      gradient: LinearGradient(colors: gradientColors),
      barWidth: 2,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            gradientColors.first.withOpacity(0.3),
            Colors.transparent
          ],
        ),
      ),
      spots: spots,
    );
  }

  void _processSleepData(List<HealthDataPoint> healthData) {
    Map<String, Map<String, double>> weeklySleep = {};
    Map<String, double> lastNight = {};

    for (var dataPoint in healthData) {
      String day = dataPoint.dateFrom.weekday.toString();
      double value = _toDouble(dataPoint.value);

      switch (dataPoint.type) {
        case HealthDataType.SLEEP_ASLEEP:
        case HealthDataType.SLEEP_IN_BED:
          weeklySleep[day] = (weeklySleep[day] ?? {})..update('total', (existingValue) => existingValue + value, ifAbsent: () => value);
          if (dataPoint.dateFrom.day == DateTime.now().day - 1) {
            lastNight['total'] = (lastNight['total'] ?? 0.0) + value;
          }
          break;
        case HealthDataType.SLEEP_DEEP:
          weeklySleep[day] = (weeklySleep[day] ?? {})..update('deep', (existingValue) => existingValue + value, ifAbsent: () => value);
          if (dataPoint.dateFrom.day == DateTime.now().day - 1) {
            lastNight['deep'] = (lastNight['deep'] ?? 0.0) + value;
          }
          break;
        default:
          break;
      }
    }

    print("Weekly Sleep: $weeklySleep");
    print("Last Night Sleep: $lastNight");

    var newSleepData = weeklySleep.entries.map((entry) {
      int weekdayIndex = int.tryParse(entry.key) ?? 0;
      String dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][weekdayIndex - 1];

      return {
        'day': dayName,
        'total': entry.value['total'] ?? 0.0,
        'deep': entry.value['deep'] ?? 0.0,
      };
    }).toList();

    setState(() {
      sleepData = newSleepData;
      lastNightSleep = lastNight;
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      print("Warning: Received null value.");
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      double? parsedValue = double.tryParse(value);
      if (parsedValue == null) {
        print("Warning: Unable to parse value '$value' as double.");
        return 0.0;
      }
      return parsedValue;
    } else {
      print("Warning: Unexpected type for value '$value'.");
      return 0.0;
    }
  }
}
