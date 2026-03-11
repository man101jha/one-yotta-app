import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/financials_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FinancialServices {
  final AuthService _authService = AuthService();

  String padWithZeroes(int number, {int width = 10}) {
    return number.toString().padLeft(width, '0');
  }

  Future<http.Response> getCreditNotesData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }

    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/cn/details',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [padWithZeroes(bto)],
        "credt_note_from_date": "",
        "credt_note_to_date": "",
        "support_to_customerid": padWithZeroes(sto),
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      FinancialsDataManager().setFinancialsData(jsonData);
    }
    return response;
  }

  Future<http.Response> getPaymentHistoryData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    print('sessiondata');
    print(sessionData);
    final uuid = sessionData?['acctUUID'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_payment/api/v1/paymentHistory/accountId/$uuid',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      FinancialsDataManager().setPaymentHistoryData(jsonData);
    }
    return response;
  }

  Future<http.Response> getInvoicesData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }

    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/invoice/create_invoices',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [padWithZeroes(bto)],
        "invoice_from": "",
        "invoice_to": "",
        "support_to_customerid": padWithZeroes(sto),
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      FinancialsDataManager().voidSetInvoicesData(jsonData);
    }
    return response;
  }

  Future<String?> downloadInvoicePdf(String invoiceId) async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();

    if (token == null) {
      throw Exception('Access token not found.');
    }

    try {
      final response = await http.post(
        Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/invoice/get_invoice',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"invoice_no": invoiceId}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        dynamic base64String = jsonData['file'] ?? jsonData['content'] ?? jsonData['Content'];
        
        // Handle case where it might be inside 'Response'
        if (base64String == null && jsonData['Response'] != null) {
          if (jsonData['Response'] is List && jsonData['Response'].isNotEmpty) {
            base64String = jsonData['Response'][0]['file'] ?? jsonData['Response'][0]['content'] ?? jsonData['Response'][0]['Content'] ?? jsonData['Response'][0]['base64'];
          } else if (jsonData['Response'] is Map) {
            base64String = jsonData['Response']['file'] ?? jsonData['Response']['content'] ?? jsonData['Response']['Content'] ?? jsonData['Response']['base64'];
          } else if (jsonData['Response'] is String) {
            base64String = jsonData['Response'];
          }
        }

        final filename = jsonData['filename'] ?? 'invoice_$invoiceId.pdf';

        if (base64String == null || base64String.toString().isEmpty) {
          throw Exception("No file content found. Response: ${response.body}");
        }

        String rawBase64 = base64String.toString();
        // Remove data URI prefix if present
        if (rawBase64.contains(',')) {
          rawBase64 = rawBase64.split(',').last;
        }

        final bytes = base64Decode(rawBase64.replaceAll(RegExp(r'\s+'), ''));

        // Request storage permission
        final permissionStatus = await Permission.storage.request();
        if (!permissionStatus.isGranted && !kIsWeb) {
           throw Exception("Storage permission not granted");
        }

        Directory directory;
        if (!kIsWeb && Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
             directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        String safeFilename = filename;
        if (!safeFilename.toLowerCase().endsWith('.pdf')) {
          safeFilename = '$safeFilename.pdf';
        }
        final filePath = '${directory.path}/$safeFilename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        return filePath;
      } else {
        throw Exception("Failed to download PDF. Status code: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error downloading PDF: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) throw Exception('Access token not found.');

    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/trans/get_transactions',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [padWithZeroes(bto)],
        "transaction_to_date": "",
        "transaction_from_date": "",
        "support_to_customerid": padWithZeroes(sto),
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      final List<dynamic> transactionList = jsonData['Response'] ?? [];

      return transactionList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<Map<String, dynamic>> getUnbilledData(String customerId) async {
    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('Access token not found.');
    }

    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_erp/api/v1/sap/unbilled/get_unbilled_details',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"customerId": int.parse(customerId)}),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to load unbilled data');
    }
  }

  Future<http.Response> getAvailableBalance() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_credit/api/v1/transactions/cb/$bto',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      FinancialsDataManager().setAvailableBalanceData(jsonData);
    }
    return response;
  }

  Future<http.Response> getUsedExpiredBalance() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_credit/api/v1/transactions/exu/$bto',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      FinancialsDataManager().setUsedExpiredBalanceData(jsonData);
    }
    return response;
  }

  Future<http.Response> getAppliedHistory() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_credit/api/v1/transactions/history/$bto',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<List<Map<String, dynamic>>> redeemVoucher({
    required String voucherCode,
    required int customerId,
    required String userUUID,
    required String applyFrom,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Access token not found.');

    final response = await http.post(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_credit/api/v1/transactions/credit/redemption',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "customer_id": customerId,
        "userUUID": userUUID,
        "couponCode": voucherCode,
        "applyFrom": applyFrom,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> transactionList = jsonData['Response'] ?? [];
      return transactionList.cast<Map<String, dynamic>>();
    } else {
      throw response.body;
    }
  }
}
