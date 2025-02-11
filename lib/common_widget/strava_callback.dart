import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StravaCallbackHandler {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> handleDeepLink(Uri uri) async {
    if (uri.queryParameters.containsKey('code')) {
      String code = uri.queryParameters['code']!;
      await _fetchAccessToken(code);
    }
  }

  Future<void> _fetchAccessToken(String code) async {
    final response = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': '117285',
        'client_secret': 'f745c3921d32c355143d001e177b9d717ceb201d',
        'code': code,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      await storage.write(key: 'strava_access_token', value: data['access_token']);
      await storage.write(key: 'strava_athlete_id', value: data['athlete']['id'].toString());

      // Navigate back to your app's main screen
      // Adjust the navigation logic as per your app's requirements
    } else {
      print('Failed to fetch access token: ${response.body}');
    }
  }
}
