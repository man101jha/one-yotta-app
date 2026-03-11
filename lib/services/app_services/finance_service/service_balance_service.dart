import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class ServiceBalanceService {
  final AuthService _authService = AuthService();

  Future<http.Response> getServiceBalance() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    
    if (token == null) {
      throw Exception('Access token not found.');
    }
    
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];
    
    // Default to using typical IDs if likely strings, or handle nulls
    final String supportToId = sto?.toString() ?? ""; 
    final String billToId = bto?.toString() ?? "";

    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/srv-bal'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [billToId],
        "support_to_customerid": supportToId
      }),
    );

    return response;
  }
}
