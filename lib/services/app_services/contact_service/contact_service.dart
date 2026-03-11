import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class ContactService {
  final AuthService _authService = AuthService();

Future<http.Response> getContactTypeList() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/contact/contacttypes');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }


 Future<http.Response> getContactDetails() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/contact/$uuid');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

Future<void> sendJsonForNewContact(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();
  final sessionData = SessionManager().getSessionData();
  final acctUUID = sessionData?['acctUUID'];

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/contact');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      ...payload,
      "acctUUID": acctUUID,
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Error: ${response.body}");
  }
}

Future<void> sendJsonForEditContact(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();
  final sessionData = SessionManager().getSessionData();
  final acctUUID = sessionData?['acctUUID'];

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/contact');

  final response = await http.put(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      ...payload,
      "acctUUID": acctUUID,
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Error: ${response.body}");
  }
}

Future<http.Response> getCallingCodes() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/callingcodes');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }
Future<http.Response> deactivateContact(Map<String, dynamic> contactJson) async {
    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('Access token not found.');
    }

    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/contact/deactivate');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(contactJson),
    );

    return response;
  }
  Future<http.Response> addUser(Map<String, dynamic> userJson) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');

    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/user');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userJson),
    );
    return response;
  }

  Future<http.Response> reactivateUser(Map<String, dynamic> userJson) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');

    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/user/re-activate');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userJson),
    );
    return response;
  }

  Future<http.Response> editUser(Map<String, dynamic> userJson) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');

    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/user');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userJson),
    );
    return response;
  }

  Future<http.Response> revokeUser(String userUUID) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');

    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/user/$userUUID');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<http.Response> resendVerificationMail(String userUUID) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');

    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/user/resend-verification-mail/$userUUID');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }
}