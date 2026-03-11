import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class KycService {
  final AuthService _authService = AuthService();


Future<http.Response> getKycDocs(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();
  final sessionData = SessionManager().getSessionData();
  final bto = sessionData?['bto'];

  if (token == null) {
    throw Exception('Access token not found.');
  }
  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/kyc/docs');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
        "accountNumber": bto,
        "docType":'kyc'
      }),  );

  return response;
}
Future<http.Response> uploadKycDoc(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/kyc/upload');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  return response;
}
 Future<http.Response> getKycDetails() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_kyc/api/v1/kyc/getKYCDetails/$uuid');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

 Future<http.Response> getAddressData() async {
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
Future<http.Response> verifyKycDetails(String crmId) async {
   final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/kyc/send?accountID=$crmId');
  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  return response;
}
Future<http.Response> kycInit(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_kyc/api/v1/kyc/init');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  return response;
}
Future<http.Response> verifyOtp(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_kyc/api/v1/kyc/verify');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  return response;
}

Future<http.Response> kycV2Init(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_kyc/api/v2/kyc/init');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  return response;
}

Future<http.Response> kycV2Verify(Map<String, dynamic> payload) async {
  final token = await _authService.getAccessToken();

  if (token == null) {
    throw Exception('Access token not found.');
  }

  final uri = Uri.parse('https://uatmyaccountapi.yotta.com/my_kyc/api/v2/kyc/verify');

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  return response;
}

}