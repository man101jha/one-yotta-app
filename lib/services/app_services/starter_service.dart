import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class ApiClient {
  final AuthService _authService = AuthService();

  Future<http.Response> getSessionStarter() async {
    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('Access token not found.');
    }

    final response = await http.get(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/session/starter'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      SessionManager().setSessionData(jsonData); // store the data
    }

    return response;
  }
}
