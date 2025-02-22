import 'package:fitglide_mobile_application/services/api_service.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final response = await ApiService.getDietComponents();
    final jsonString = jsonEncode(response);
    final file = File('diet_components_updated.json');
    await file.writeAsString(jsonString);
    print('Diet components saved to diet_components_updated.json');
  } catch (e) {
    print('Error fetching diet components: $e');
  }
}