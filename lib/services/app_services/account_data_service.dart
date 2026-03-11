import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class AccountDataService {
  final AuthService _authService = AuthService();

  Future<http.Response> getAccountData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/accounts/$uuid');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      AccountDataManager().setAccountData(jsonData);
      print('Response code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    return response;
  }
  Future<http.Response> updateProfileData(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/user');

  final response = await http.put(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
      AccountDataManager().setAccountData(payload);

    print('Account updated successfully.');
  } else {
    print('Failed to update account: ${response.statusCode}');
    print(response.body);
  }

  return response;
}
Future<http.Response> updateCompanyData(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();
  if (token == null) {
    throw Exception('Access token not found.');
  }
  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/accounts/update');

  final response = await http.put(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
      AccountDataManager().setAccountData(payload);

  } else {
    print('Failed to update account: ${response.statusCode}');
    print(response.body);
  }

  return response;
}
  Future<bool> isKycApproved() async {
    try {
      final response = await getAccountData();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['accountKYCApprovalStatus'] == 'Approved';
      }
      return false;
    } catch (e) {
      print('Error checking KYC status: $e');
      return false;
    }
  }
}