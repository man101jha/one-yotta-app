import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/screens/modules/financials/payment/data/payData.dart';
import 'package:myaccount/screens/modules/financials/payment/pages/webview_page.dart';
import 'package:myaccount/utilities/env.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PaymentHandler {
  final BuildContext context;
  final TextEditingController amountController;
  bool _loading = false;
  String? errorText;

  PaymentHandler({
    required this.context,
    required this.amountController,
  });

  Future<void> fetchMerchantEncryptedData(
      List<Map<String, dynamic>> data, String paymentType) async {
    try {

      // Start loading
      _setLoading(true);

      // Prepare invoices
      List<Map<String, dynamic>> invoices = [];
      if (data.length == 1) {
        invoices = data.map((invoice) {
          return {
            "pg_amount": double.tryParse(invoice['pg_amount'].toString()) ?? 0,
            "reference_id": invoice['Invoice No'],
            "currency": invoice['Currency'],
            "billing_org": invoice['Billing Org'],
            "company_name": invoice['Customer Name'],
            "billing_country": invoice['Billing Country'],
            "net_amount": double.tryParse(invoice['Net Amount'].toString()) ?? 0,
            "tax_amount": double.tryParse(invoice['Tax Amount'].toString()) ?? 0,
            "tds_amount": double.tryParse(invoice['Tds Amount'].toString()) ?? 0,
            "wallet_amount":
                double.tryParse(invoice['wallet_amount'].toString()) ?? 0,
          };
        }).toList();
      } else {
        double grossAmt = 0;
        for (var invoice in data) {
          grossAmt += double.tryParse(invoice['Net Due'].toString()) ?? 0;
        }

        invoices = data.map((invoice) {
          return {
            "pg_amount": double.tryParse(invoice['pg_amount'].toString()) ?? 0,
            "reference_id": invoice['Invoice No'],
            "currency": invoice['Currency'],
            "billing_org": invoice['Billing Org'],
            "company_name": invoice['Customer Name'],
            "billing_country": invoice['Billing Country'],
            "net_amount":
                double.tryParse(invoice['Net Amount'].toString()) ?? 0,
            "tax_amount":
                double.tryParse(invoice['Tax Amount'].toString()) ?? 0,
            "tds_amount":
                double.tryParse(invoice['Tds Amount'].toString()) ?? 0,
            "wallet_amount":
                double.tryParse(invoice['wallet_amount'].toString()) ?? 0,
          };
        }).toList();
      }

      // Get local storage data
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('userData') ?? '{}');
      final accounts = jsonDecode(prefs.getString('accounts') ?? '{}');
      final details = jsonDecode(prefs.getString('details') ?? '{}');

      final hasMultipleAccounts =
          (accounts['support_to_customers'] as List?)?.length ?? 0 > 1;

      // Prepare order payload
      final order = {
        "payment_type": paymentType,
        "payment_gateway": data[0]['payWith'] == 'wallet' &&
                (double.tryParse(data[0]['pg_amount'].toString()) ?? 0) == 0
            ? "wallet"
            : "ccavenue",
        "order_from": "oneyotta_pg_url",
        "customer_crm_id": userData['bto'],
            // hasMultipleAccounts ? userData['bto'] : userData['sto'],
        "user_uuid": userData['userUUID'],
        "account_uuid": userData['acctUUID'],
        "company_name": invoices.first['company_name'],
        "company_email": details['email'],
        "details_info": invoices,
      };

      // Make API call
      final url = Uri.parse('${Env.uatapi}/pay/new/order');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(order),
      );

      // Parse response
      final json = jsonDecode(response.body);
      final dataResponse = PaymentData.fromJson(json);

      // Handle response
      if (dataResponse.statusMessage == "SUCCESS") {
        _setLoading(false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebviewPage(data: dataResponse),
          ),
        );
      } else {
        _setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please try again.")),
        );
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: ${e.toString()}")),
      );
    }
  }

  void _setLoading(bool value) {
    _loading = value;
  }
}
