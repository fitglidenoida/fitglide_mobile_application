import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/sleep_calculator.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  List<int> showingTooltipOnSpots = [];

  @override
  void initState() {
    super.initState();
    _fetchAlarms();
    _fetchSleepLogs();
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
      int userAge = user.age;
      double workoutHours = 1.0;
      double sleepHours = SleepCalculator.getRecommendedSleepDuration(userAge, workoutHours);

      DateTime now = DateTime.now();
      String cleanTime = cleanTimeString(todaySleepArr.isNotEmpty ? todaySleepArr.first['time'] : '');

      DateTime? wakeUpTime;
      try {
        wakeUpTime = todaySleepArr.isNotEmpty ? DateFormat('hh:mm a').parse(cleanTime) : null;
      } catch (e) {
        print("Error parsing time: $e with string: ${todaySleepArr.isNotEmpty ? todaySleepArr.first['time'] : 'no alarms'}");
        wakeUpTime = null;
      }

      DateTime? bedtime = wakeUpTime != null ? _calculateBedtime(wakeUpTime, sleepHours, now) : null;

      if (bedtime != null) {
        Duration durationUntilBed = bedtime.difference(now);
        String durationText = _formatDuration(durationUntilBed);

        setState(() {
          todaySleepArr.insert(0, {
            "name": "Bedtime",
            "image": "assets/img/bed.png",
            "time": DateFormat("hh:mm a").format(bedtime),
            "duration": durationText
          });
        });
      }
    });
  }

  DateTime _calculateBedtime(DateTime wakeUpTime, double sleepHours, DateTime now) {
    DateTime baseBedtime = wakeUpTime.subtract(Duration(
      hours: sleepHours.toInt(),
      minutes: ((sleepHours % 1) * 60).toInt(),
    ));

    if (baseBedtime.isBefore(now)) {
      return DateTime(now.year, now.month, now.day + 1, baseBedtime.hour, baseBedtime.minute);
    }
    return baseBedtime;
  }

  static const platform = MethodChannel('fitglide/alarm');

  Future<void> _scheduleNotification(Map<String, dynamic> alarm) async {
    try {
      if (alarm['time'] is! String) {
        log("Error: Alarm time is not a string: ${alarm['time']}");
        return;
      }

      DateTime? alarmTime;
      try {
        alarmTime = DateTime.parse(alarm['time'].toString());
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

  Future<void> _refreshData() async {
    await _fetchAlarms();
    await _fetchSleepLogs();
    setState(() {});
  }

  Future<void> _fetchSleepLogs() async {
    try {
      final user = await UserService.fetchUserData();
      final username = user.username;
      print('Username: $username');

      final sleepLogs = await ApiService.getSleepLogs(username); // Corrected to ApiService
      print('Raw Sleep Logs: $sleepLogs');

      // Convert and sort sleep logs by date
      List<Map<String, dynamic>> parsedLogs = sleepLogs.map((log) {
        final dateStr = log['date'];
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        return {
          'date': date, // Store DateTime for sorting
          'day': DateFormat('E').format(date),
          'sleep_duration': (log['sleep_duration'] != null)
              ? double.tryParse(log['sleep_duration'].toString()) ?? 0.0
              : 0.0,
          'deep_sleep_duration': (log['deep_sleep_duration'] != null)
              ? double.tryParse(log['deep_sleep_duration'].toString()) ?? 0.0
              : 0.0,
        };
      }).toList();

      // Sort by date
      parsedLogs.sort((a, b) => a['date'].compareTo(b['date']));

      setState(() {
        sleepData = parsedLogs.map((log) => {
              'day': log['day'],
              'sleep_duration': log['sleep_duration'],
              'deep_sleep_duration': log['deep_sleep_duration'],
            }).toList();

        lastNightSleep = sleepData.isNotEmpty
            ? {
                'total': sleepData.last['sleep_duration'],
                'deep': sleepData.last['deep_sleep_duration'],
              }
            : {};
        print('Processed Sleep Data: $sleepData');
      });
    } catch (e) {
      log("Failed to fetch sleep logs: $e");
      setState(() {
        sleepData = [];
        lastNightSleep = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

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
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
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
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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
              if (sleepData.isNotEmpty) _buildLineChart(media),
              const SizedBox(height: 20),
              if (lastNightSleep.isNotEmpty) _buildLastNightSleepCard(media),
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
    return SizedBox(
      height: media.width * 0.5,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: false,
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              if (response == null || response.lineBarSpots == null) {
                return;
              }
              setState(() {
                showingTooltipOnSpots = response.lineBarSpots!.map((spot) => spot.spotIndex).toList();
              });
            },
            mouseCursorResolver: (FlTouchEvent event, LineTouchResponse? response) {
              return (response == null || response.lineBarSpots == null)
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click;
            },
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  const FlLine(color: Colors.transparent),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: TColor.secondaryColor1,
                    ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 20,
              getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                return lineBarsSpot.map((lineBarSpot) {
                  return LineTooltipItem(
                    "${lineBarSpot.y.toStringAsFixed(1)}h",
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: TColor.primaryColor1,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [TColor.primaryColor1.withOpacity(0.3), Colors.transparent],
                ),
              ),
              spots: sleepData.asMap().entries.map((entry) {
                return FlSpot(entry.key + 1, entry.value['sleep_duration']);
              }).toList(),
            ),
            LineChartBarData(
              isCurved: true,
              color: TColor.secondaryColor1.withOpacity(0.5),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [TColor.secondaryColor1.withOpacity(0.3), Colors.transparent],
                ),
              ),
              spots: sleepData.asMap().entries.map((entry) {
                return FlSpot(entry.key + 1, entry.value['deep_sleep_duration']);
              }).toList(),
            ),
          ],
          minY: 0,
          maxY: 12,
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() > 0 && value.toInt() <= sleepData.length) {
                    return Text(
                      sleepData[value.toInt() - 1]['day'],
                      style: TextStyle(color: TColor.gray, fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}h',
                    style: TextStyle(color: TColor.gray, fontSize: 12),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 2,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: TColor.gray.withOpacity(0.15),
                strokeWidth: 2,
              );
            },
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.transparent)),
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
              fontWeight: FontWeight.w700,
            ),
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
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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
}