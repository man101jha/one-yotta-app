import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class AssetService {
  final AuthService _authService = AuthService();

  Future<http.Response> getAssetData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_asset/api/get_asset_details'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": bto,
        "support_to_customerid": sto
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      AssetDataManager().setAssetData(jsonData);
    }

    return response;
  }
}