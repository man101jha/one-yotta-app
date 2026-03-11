import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class OnboardService {
  final AuthService _authService = AuthService();

  Future<http.Response> getOnboardingData() async {
    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('Access token not found.');
    }

    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_account/api/v1/onboarding/onboard',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<http.Response> completeOnboarding({
    required String accountName,
    required String pan,
    required String gstin,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String postalCode,
    required String country,
    required int state,
    required String addressType,
    required bool showMSA,
    String? sez,
    required String? addressLUTNumber,
    required DateTime? addressLUTExpiry,
    required String contactFirstName,
    required String contactLastName,
  }) async {
    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['userUUID'];

    final Map<String, dynamic> payload = {
      "accountName": accountName,
      "contactFirstName": contactFirstName,
      "contactLastName": contactLastName,
      "userUUID": uuid,
      "addressGSTApplicable": 0,
      "addressLine1": addressLine1,
      "addressLine2": addressLine2,
      "addressCity": city,
      "addressPINCode": postalCode,
      "addressCountry": country,
      "addressState": state,
      "addressName": addressType,
      "addressSEZ": sez,
      "showMSA": showMSA== true ? 1 : 0,
      "addressLUTNumber": addressLUTNumber,
      "addressLUTExpiryDate": addressLUTExpiry != null ? "${addressLUTExpiry!.year.toString().padLeft(4, '0')}-" "${addressLUTExpiry!.month.toString().padLeft(2, '0')}-" "${addressLUTExpiry!.day.toString().padLeft(2, '0')}" : "",
    };

    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_account/api/v1/onboarding/onboard',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );
    return response;
  }
}
