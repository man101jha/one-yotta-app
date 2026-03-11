import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class AddressService {
  final AuthService _authService = AuthService();


 Future<http.Response> getAddressDetails() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/address/account/$uuid');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

 Future<http.Response> saveAddress(Map<String, dynamic> addressData, {String? addressId}) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];
  if (uuid != null) {
    addressData["accountUUID"] = uuid;
  }
    // If editing, include addressUUID in the body
    if (addressId != null) {
      addressData["addressUUID"] = addressId;
    }
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/address');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(addressData),
    );

    return response;
  }

Future<http.Response> editAddress(Map<String, dynamic> addressData, {String? addressId}) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];
  if (uuid != null) {
    addressData["accountUUID"] = uuid;
  }
    // If editing, include addressUUID in the body
    if (addressId != null) {
      addressData["addressUUID"] = addressId;
    }
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/address');
    

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(addressData),
    );

    return response;
  }

Future<http.Response> deleteAddress(String addressId) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/address/$addressId');
  final response = await http.delete(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  return response;
}

Future<List<Map<String, dynamic>>> fetchCountriesAndStates() async {
  try {
    final response = await http.get(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/countrystates'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to fetch country/state list");
    }
  } catch (e) {
    throw Exception("Error: $e");
  }
}
}