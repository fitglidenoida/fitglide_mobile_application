import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/bmr_tdee_service.dart';
import 'package:fitglide_mobile_application/services/diet_service.dart'; // Add this import
import 'package:fitglide_mobile_application/services/user_service.dart'; // Add this for username
import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_schedule_view.dart'; // Add this import

class MealTdeeView extends StatefulWidget {
  final double maintainTdee;

  const MealTdeeView({super.key, required this.maintainTdee});

  @override
  State<MealTdeeView> createState() => _MealTdeeViewState();
}

class _MealTdeeViewState extends State<MealTdeeView> {
  late Future<Map<String, double>> tdeeOptionsFuture;

  @override
  void initState() {
    super.initState();
    final tdeeService = BmrTdeeService();
    tdeeOptionsFuture = Future.value(tdeeService.calculateTDEEOptions(widget.maintainTdee, 'sedentary'));
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
          "Calories Overview",
          style: TextStyle(color: TColor.black, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.white,
      body: FutureBuilder<Map<String, double>>(
        future: tdeeOptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tdeeOptions = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: TColor.gray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.05),
                  Text(
                    "Your Calorie Goals",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: media.width * 0.05),
                  _buildTdeeSection(context, "Maintain Weight", tdeeOptions['maintain']!),
                  _buildTdeeSection(context, "Weight Loss", tdeeOptions['loss_250g']!, tdeeOptions['loss_500g']!),
                  _buildTdeeSection(context, "Weight Gain", tdeeOptions['gain_250g']!, tdeeOptions['gain_500g']!),
                  SizedBox(height: media.width * 0.05),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: RoundButton(
                        title: "Create Diet Plan",
                        type: RoundButtonType.bgGradient,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        onPressed: () {
                          _showDietPlanDialog(context);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.25),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDietPlanDialog(BuildContext context) {
    String? dietPreference = 'Veg'; // Default selection
    int? mealsPerDay = 3; // Default selection

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                "Create Your Diet Plan",
                style: TextStyle(color: TColor.black, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diet Preference",
                      style: TextStyle(color: TColor.gray, fontSize: 14),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Veg',
                          groupValue: dietPreference,
                          onChanged: (value) {
                            setState(() {
                              dietPreference = value;
                            });
                          },
                          activeColor: TColor.primaryColor1,
                        ),
                        Text("Veg", style: TextStyle(color: TColor.black)),
                        Radio<String>(
                          value: 'Non-Veg',
                          groupValue: dietPreference,
                          onChanged: (value) {
                            setState(() {
                              dietPreference = value;
                            });
                          },
                          activeColor: TColor.primaryColor1,
                        ),
                        Text("Non-Veg", style: TextStyle(color: TColor.black)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Meals Per Day",
                      style: TextStyle(color: TColor.gray, fontSize: 14),
                    ),
                    DropdownButton<int>(
                      value: mealsPerDay,
                      items: [3, 5, 6].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value Meals", style: TextStyle(color: TColor.black)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          mealsPerDay = value;
                        });
                      },
                      underline: Container(),
                      isExpanded: true,
                      dropdownColor: TColor.white,
                      iconEnabledColor: TColor.primaryColor1,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: TColor.gray)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the dialog
                    try {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      // Fetch username
                      final user = await UserService.fetchUserData();
                      final username = user.username;

                      // Create diet plan using DietService
                      final dietService = DietService();
                      final dietPlan = await dietService.createDietPlan(
                        username: username,
                        dietPreference: dietPreference!,
                        mealsPerDay: mealsPerDay!,
                        targetCalories: widget.maintainTdee,
                      );

                      Navigator.pop(context); // Close loading dialog

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Diet Plan Created: ${dietPlan['id']}")),
                      );

                      // Navigate to MealScheduleView
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MealScheduleView()),
                      );
                    } catch (e) {
                      Navigator.pop(context); // Close loading dialog if open
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to create diet plan: $e")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Create", style: TextStyle(color: TColor.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTdeeSection(BuildContext context, String title, double value1, [double? value2]) {
    var media = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [TColor.primaryColor1.withOpacity(0.2), TColor.primaryColor2.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildTdeeRow(title == "Maintain Weight" ? "Maintain" : "250g/Week", value1),
              if (value2 != null) ...[
                const SizedBox(height: 8),
                _buildTdeeRow("500g/Week", value2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTdeeRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: TColor.black, fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TColor.secondaryColor1,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${value.toStringAsFixed(1)} kcal',
            style: TextStyle(
              color: TColor.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}