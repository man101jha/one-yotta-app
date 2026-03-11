import 'dart:convert';
import 'package:get/get.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:intl/intl.dart';

class InvoiceController extends GetxController {
  final FinancialServices _financialServices = FinancialServices();

  var invoices = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  bool _hasLoaded = false; // Track if data has been fetched once

  String selectedTab = 'All';
  String operatorStorage = '';
  DateTime? lastDate;

  String searchText = '';

  void initData({String? xAxisValue}) {
    if (_hasLoaded) return;
    lastDate = getDateBefore(xAxisValue);
    fetchInvoicesData();
    _hasLoaded = true;
  }

  DateTime getDateBefore(dynamic input) {
    if (input == null || input.toString().trim().isEmpty) {
      operatorStorage = '';
      return DateTime.now();
    }

    String operator = '';
    String numericPart = input.toString().trim();
    if (numericPart.startsWith('>') || numericPart.startsWith('<')) {
      operator = numericPart[0];
      numericPart = numericPart.substring(1).trim();
      selectedTab = 'Open';
    }
    operatorStorage = operator;
    int daysBefore = int.tryParse(numericPart) ?? 0;
    DateTime today = DateTime.now();
    return today.subtract(Duration(days: daysBefore));
  }

  Future<void> fetchInvoicesData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _financialServices.getInvoicesData();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notes = data['Response'] ?? [];
        final dateFormat = DateFormat('dd-MM-yyyy');
        final today = DateTime.now();

        List<Map<String, dynamic>> filteredInvoices = [];

        for (var item in notes) {
          final rawDate = item['invoice_date'];
          if (rawDate == null) continue;
          final invoiceDateStr = rawDate.toString().trim();
          if (invoiceDateStr.isEmpty) continue;

          DateTime? invoiceDate;
          try {
            invoiceDate = dateFormat.parseStrict(invoiceDateStr);
          } catch (e) {
            continue;
          }

          bool include = true;

          if (lastDate != null && operatorStorage.isNotEmpty) {
            final status = item['invoice_status']?.toString().toUpperCase() ?? '';
            if (operatorStorage == '>') {
              include = invoiceDate.isBefore(lastDate!) && status == 'OPEN';
            } else if (operatorStorage == '<') {
              include = invoiceDate.isAfter(lastDate!) &&
                        invoiceDate.isBefore(today) &&
                        status == 'OPEN';
            }
          }

          if (include) {
            filteredInvoices.add({
              'invoiceNumber': item['invoice_no']?.toString() ?? '-',
              'orderNo': item['sof_no']?.toString() ?? '-',
              'period': item['invoice_period']?.toString() ?? '-',
              'dueDate': item['invoice_due_date']?.toString() ?? '-',
              'invoiceDate': item['invoice_date']?.toString() ?? '-',
              'currency': item['invoice_currency']?.toString() ?? '-',
              'totalAmount': item['invoice_total_amount']?.toString() ?? '-',
              'amountPaid': item['invoice_amount_paid']?.toString() ?? '-',
              'amountDue': item['invoice_amount_due']?.toString() ?? '-',
              'status': item['invoice_status']?.toString() ?? '-',
              'billingCountry': item['invoice_bill_address_country']?.toString() ?? '-',
              'billingOrgName': item['invoice_bill_from_org_name']?.toString() ?? '-',
              'companyName': item['bill_to_customername']?.toString() ?? '-',
            });
          }
        }

        invoices.value = filteredInvoices;
      } else {
        errorMessage.value = 'Failed to load invoices. Status Code: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredInvoices {
    return invoices.where((invoice) {
      final status = (invoice['status'] ?? '').toString().toLowerCase();
      final invoiceNumber = (invoice['invoiceNumber'] ?? '').toString().toLowerCase();
      final date = (invoice['invoiceDate'] ?? '').toString().toLowerCase();

      final matchesTab = selectedTab == 'All' || status == selectedTab.toLowerCase();
      final matchesSearch = searchText.isEmpty ||
          invoiceNumber.contains(searchText.toLowerCase()) ||
          date.contains(searchText.toLowerCase());

      return matchesTab && matchesSearch;
    }).toList();
  }
}
