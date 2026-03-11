import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/session/wallet_data_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class WalletService {
  final AuthService _authService = AuthService();

  Future<http.Response> getWalletData({
    required String requestSourse,
    required String requestId,
  }) async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/wallet'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customer_id": bto,
        "request_source": requestSourse,
        "request_id": requestId,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      WalletDataManager().setWalletData(jsonData);
    }

    return response;
  }

  Future<http.Response> getWalletHistory() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Access token not found.');
    }
    final url =
        'https://uatmyaccountapi.yotta.com/my_payment/api/v1/paymentHistory/accountId/xo67vg9UsbK7m9Gc/walletHistory';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      WalletDataManager().setWalletHistoryData(jsonData);
    } else {
      throw Exception('Failed to load wallet history');
    }
    return response;
  }

  Future<http.Response> addMoneyInWallet({
    required int amount,
    required bool applyTds,
    int? tdsAmount,
    required int consentGiven,
    required double net_amount,
  }) async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final accountData = AccountDataManager().getAccountData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_payment/api/v1/wallet/new/pay',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "payment_type": "ACCOUNT_PAYMENT",
        "payment_gateway": "ccavenue",
        "order_from": "oneyotta_pg_url",
        "customer_crm_id": bto,
        "user_uuid": sessionData?['userUUID'],
        "account_uuid": sessionData?['acctUUID'],
        "company_name": sessionData?['accountName'],
        "consent_flag": consentGiven,
        "company_email": sessionData?['email'],

        "details_info": [
          {
            "pg_amount": net_amount,
            "reference_id": '', //data[0].p_title,
            "currency": "INR",
            "billing_org": "IN10",
            "billing_country": "IN",
            "net_amount": amount,
            "tax_amount": 0,
            "tds_amount": tdsAmount,
            "wallet_amount": 0,
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print(jsonData);
      // WalletDataManager().setWalletData(jsonData);
    }

    return response;
  }

  Future<Map<String, dynamic>> getEnc(
    List<Map<String, dynamic>> data,
    String paymentType,
    bool isWalletChecked,
  ) async {
    List<Map<String, dynamic>> invoices =
        data.map((invoice) {
          return {
            "pg_amount": double.tryParse(invoice['pg_amount'].toString()) ?? 0,
            "reference_id": invoice['reference_id'],
            "currency": invoice['currency'],
            "billing_org": invoice['invoice_bill_from_org'],
            "company_name": invoice['company_name'],
            "billing_country": invoice['billing_country'],
            "net_amount":
                double.tryParse(invoice['net_amount'].toString()) ?? 0,
            "tax_amount":
                double.tryParse(invoice['tax_amount'].toString()) ?? 0,
            "tds_amount":
                double.tryParse(invoice['tds_amount'].toString()) ?? 0,
            "wallet_amount":
                double.tryParse(invoice['wallet_amount'].toString()) ?? 0,
          };
        }).toList();
    final userData = SessionManager().getSessionData();
    final accounts = AccountDataManager().getAccountStoBtoData();
    final details = SessionManager().getSessionData();
    final bool hasMultipleAccounts =
        (accounts?['support_to_customers'] as List).length > 1;
    final order = {
      "payment_type": "invoice",
      "payment_gateway":
          isWalletChecked && data[0]['pg_amount'] == 0 ? "wallet" : "ccavenue",
      "order_from": "oneyotta_pg_url",
      // "customer_crm_id": 13477,
      // "user_uuid": "uUinBYKS9wJYUGPT",
      // "account_uuid": "DfggDw3Cp8mqShId",
      // "company_name": "yanlimb",
      // "company_email": "waghharish03909@yopmail.com",
      "customer_crm_id":
          hasMultipleAccounts
              ? (userData != null ? userData['bto'] : null)
              : (userData != null ? userData['sto'] : null),
      "user_uuid": userData?['userUUID'],
      "account_uuid": userData?['acctUUID'],
      "company_name": invoices[0]['company_name'],
      "company_email": details?['email'],
      "details_info": invoices,
    };

    print('order details : ${order}');

    final token = await _authService.getAccessToken();
    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_payment/api/v1/pay/new/order',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(order),
    );

    if (response.statusCode != 200) {
      throw Exception('Payment API failed: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
