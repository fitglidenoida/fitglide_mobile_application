import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/bmr_tdee_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:flutter/material.dart';

class DietService {
  final ApiService _apiService = ApiService();
  final BmrTdeeService _tdeeService = BmrTdeeService();

  Future<List<Map<String, dynamic>>> fetchDietComponents(String dietPreference) async {
    try {
      final response = await ApiService.fetchDietComponents(dietPreference);
      final List<dynamic> components = response['data'] ?? [];
      return components
          .where((component) => component['food_type'] == dietPreference)
          .map((component) => component as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error fetching diet components: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> createMeals({
    required String dietPreference,
    required int mealsPerDay,
    required double targetCalories,
  }) async {
    try {
      final components = await fetchDietComponents(dietPreference);
      if (components.isEmpty) {
        throw Exception('No diet components available for $dietPreference');
      }

      final mealNames = _getMealNames(mealsPerDay);
      final calorieDistribution = _getCalorieDistribution(mealsPerDay, targetCalories);
      List<Map<String, dynamic>> createdMeals = [];

      for (int i = 0; i < mealsPerDay; i++) {
        final component = components[i % components.length];
        final baseCalories = (component['calories'] as num).toDouble();
        final portionSize = (component['portion_size'] as num?)?.toDouble() ?? 100.0; // Default 100g if missing
        final caloriesPerUnit = baseCalories / portionSize; // Calories per gram
        final requiredPortion = calorieDistribution[i] / caloriesPerUnit; // Portion to match target

        final mealData = {
          'name': mealNames[i],
          'description': '$dietPreference ${mealNames[i]}',
          'meal_time': _getMealTime(i),
          'base_portion': requiredPortion.round(),
          'base_portion_unit': component['unit'] ?? 'g', // Default to grams if missing
          'diet_components': [component['id']],
        };

        final response = await ApiService.addMeal(mealData);
        createdMeals.add(response['data']..['calculatedCalories'] = calorieDistribution[i]);
      }

      return createdMeals;
    } catch (e) {
      debugPrint('Error creating meals: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDietPlan({
    required String username,
    required String dietPreference,
    required int mealsPerDay,
    required double targetCalories,
  }) async {
    try {
      final meals = await createMeals(
        dietPreference: dietPreference,
        mealsPerDay: mealsPerDay,
        targetCalories: targetCalories,
      );
      final user = await UserService.fetchUserData();

      final dietPlanData = {
        'total_calories': targetCalories,
        'diet_preference': dietPreference,
        'meals_per_day': mealsPerDay,
        'users_permissions_user': username,
        'meals': meals.map((meal) => meal['id']).toList(),
      };

      final response = await ApiService.addDietPlan(dietPlanData);
      return response['data'];
    } catch (e) {
      debugPrint('Error creating diet plan: $e');
      rethrow;
    }
  }

  List<String> _getMealNames(int mealsPerDay) {
    switch (mealsPerDay) {
      case 3:
        return ['Breakfast', 'Lunch', 'Dinner'];
      case 5:
        return ['Breakfast', 'Morning Snack', 'Lunch', 'Evening Snack', 'Dinner'];
      case 6:
        return ['Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Evening Snack', 'Dinner'];
      default:
        throw Exception('Unsupported meals per day: $mealsPerDay');
    }
  }

  String _getMealTime(int index) {
    switch (index) {
      case 0: return '07:00:00.000';
      case 1: return '10:00:00.000';
      case 2: return '13:00:00.000';
      case 3: return '16:00:00.000';
      case 4: return '19:00:00.000';
      case 5: return '21:00:00.000';
      default: return '00:00:00.000';
    }
  }

  List<double> _getCalorieDistribution(int mealsPerDay, double targetCalories) {
    switch (mealsPerDay) {
      case 3:
        return [
          targetCalories * 0.25,
          targetCalories * 0.40,
          targetCalories * 0.35,
        ];
      case 5:
        return [
          targetCalories * 0.20,
          targetCalories * 0.10,
          targetCalories * 0.35,
          targetCalories * 0.10,
          targetCalories * 0.25,
        ];
      case 6:
        return [
          targetCalories * 0.20,
          targetCalories * 0.10,
          targetCalories * 0.30,
          targetCalories * 0.10,
          targetCalories * 0.10,
          targetCalories * 0.20,
        ];
      default:
        throw Exception('Unsupported meals per day: $mealsPerDay');
    }
  }
}