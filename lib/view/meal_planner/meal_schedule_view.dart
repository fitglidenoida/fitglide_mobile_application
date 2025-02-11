import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/meal_food_schedule_row.dart';
import '../../common_widget/nutritions_row.dart';
import '../../common_widget/custom_calendar.dart'; // Import the file where CustomCalendar is defined

class MealScheduleView extends StatefulWidget {
  const MealScheduleView({super.key});

  @override
  State<MealScheduleView> createState() => _MealScheduleViewState();
}

class _MealScheduleViewState extends State<MealScheduleView> {
  DateTime _selectedDate = DateTime.now(); // Initialize here

  final List breakfastArr = [
    {"name": "Honey Pancake", "time": "07:00am", "image": "assets/img/honey_pan.png"},
    {"name": "Coffee", "time": "07:30am", "image": "assets/img/coffee.png"},
  ];

  final List lunchArr = [
    {"name": "Chicken Steak", "time": "01:00pm", "image": "assets/img/chicken.png"},
    {"name": "Milk", "time": "01:20pm", "image": "assets/img/glass-of-milk 1.png"},
  ];

  final List snacksArr = [
    {"name": "Orange", "time": "04:30pm", "image": "assets/img/orange.png"},
    {"name": "Apple Pie", "time": "04:40pm", "image": "assets/img/apple_pie.png"},
  ];

  final List dinnerArr = [
    {"name": "Salad", "time": "07:10pm", "image": "assets/img/salad.png"},
    {"name": "Oatmeal", "time": "08:10pm", "image": "assets/img/oatmeal.png"},
  ];

  final List nutritionArr = [
    {"title": "Calories", "image": "assets/img/burn.png", "unit_name": "kCal", "value": "350", "max_value": "500"},
    {"title": "Proteins", "image": "assets/img/proteins.png", "unit_name": "g", "value": "300", "max_value": "1000"},
    {"title": "Fats", "image": "assets/img/egg.png", "unit_name": "g", "value": "140", "max_value": "1000"},
    {"title": "Carbo", "image": "assets/img/carbo.png", "unit_name": "g", "value": "140", "max_value": "1000"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
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
          "Meal Schedule",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {},
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
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: TColor.white,
            child: CustomCalendar(
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              initialDate: _selectedDate,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildMealSections(media),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealSections(Size media) {
    return [
      _buildMealSection("Breakfast", breakfastArr, "230 calories"),
      _buildMealSection("Lunch", lunchArr, "500 calories"),
      _buildMealSection("Snacks", snacksArr, "140 calories"),
      _buildMealSection("Dinner", dinnerArr, "120 calories"),
      SizedBox(height: media.width * 0.05),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          "Today Meal Nutritions",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: nutritionArr.length,
        itemBuilder: (context, index) {
          var nObj = nutritionArr[index] as Map? ?? {};
          return NutritionRow(nObj: nObj);
        },
      ),
      SizedBox(height: media.width * 0.05),
    ];
  }

  Widget _buildMealSection(String title, List items, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "${items.length} Items | $subtitle",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            var mObj = items[index] as Map? ?? {};
            return MealFoodScheduleRow(mObj: mObj, index: index);
          },
        ),
      ],
    );
  }
}
