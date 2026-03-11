import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/invoice_data_manager.dart';
import 'package:myaccount/services/app_services/session/order_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class InvoiceService {
  final AuthService _authService = AuthService();

  Future<http.Response> getInvoiceData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/invoice/create_invoices'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [
            bto
        ],
        "invoice_from": "",
        "invoice_to": "",
        "support_to_customerid": sto
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print(jsonData);
      InvoiceDataManager().setInvoiceData(jsonData);
    }

    return response;
  }
}