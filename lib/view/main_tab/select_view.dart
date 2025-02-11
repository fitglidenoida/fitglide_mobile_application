import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_tracker_view.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_planner_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_tracker_view.dart';

class SelectView extends StatefulWidget {
  const SelectView({super.key});

  @override
  _SelectViewState createState() => _SelectViewState();
}

class _SelectViewState extends State<SelectView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitglide Tracker"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Workout"),
            Tab(text: "Meal"),
            Tab(text: "Sleep"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WorkoutTrackerView(),
          MealPlannerView(),
          SleepTrackerView(),
        ],
      ),
    );
  }
}
