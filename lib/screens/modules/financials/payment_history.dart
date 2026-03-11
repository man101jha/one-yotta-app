import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/utilities/string_utils.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class PaymentHistoryView extends StatefulWidget {
  const PaymentHistoryView({super.key});

  @override
  State<PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<PaymentHistoryView> {
  final FinancialServices _financialServices = FinancialServices();
  List<Map<String, String>> transactions = [];
  bool isLoading = true;
  String? errorMessage;
bool _isSearching = false;
TextEditingController _searchController = TextEditingController();
String _searchText = '';
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: CommonAppBar(
      title: 'Payment History',
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FE),
                  border: Border.all(
                    width: 1.0,
                    color: GlobalColors.borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    // Search input above the list
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search Transaction No, Date...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchText = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchText = value;
                            });
                          },
                        ),
                      ),

                    // List of transactions filtered by search
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions
                            .where((transaction) =>
                                _searchText.isEmpty ||
                                (transaction['Transaction No'] ?? '')
                                    .toLowerCase()
                                    .contains(_searchText.toLowerCase()) ||
                                (transaction['Date'] ?? '')
                                    .toLowerCase()
                                    .contains(_searchText.toLowerCase()))
                            .length,
                        itemBuilder: (context, index) {
                          final filteredTransactions = transactions
                              .where((transaction) =>
                                  _searchText.isEmpty ||
                                  (transaction['Transaction No'] ?? '')
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()) ||
                                  (transaction['Date'] ?? '')
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()))
                              .toList();

                          final transaction = filteredTransactions[index];

                          return Card(
                            elevation: 2,
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: transaction['Status'] ==
                                            'Success' ||
                                        transaction['Status'] == 'success'
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                child: Icon(
                                  transaction['Status'] == 'Success' ||
                                          transaction['Status'] == 'success'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: transaction['Status'] == 'Success' ||
                                          transaction['Status'] == 'success'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                'Txn : ${transaction['Transaction No'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                transaction['Date'] ?? '',
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 14),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${transaction['Currency'] == 'INR' ? '₹' : '\$'}${(transaction['Amount'] ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    toTitleCase(transaction['Status'] ?? ''),
                                    style: TextStyle(
                                      color: transaction['Status'] ==
                                                  'Success' ||
                                              transaction['Status'] == 'success'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () =>
                                  _showTransactionDetails(context, transaction),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    // bottomNavigationBar: const BottomNavigation(),
  );
}

  @override
  void initState() {
    super.initState();
    fetchPaymentHistoryData(); 
  }

  String formatValue(dynamic value) {
  if (value == null) return '-';
  final stringValue = value.toString().trim();
  return stringValue.isEmpty  ? '-' : stringValue;
}

  Future<void> fetchPaymentHistoryData() async  {
    try {
      final response = await _financialServices.getPaymentHistoryData();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> notes = data ?? [];

        setState(() {
          transactions = 
              notes.map<Map<String, String>>((item) {
                return {
                  'Transaction No': formatValue(item['transactionNo']),
                  'Invoice No': formatValue(item['invoiceNo']),
                  'Payment Id': formatValue(item['paymentId']),
                  'Currency': formatValue(item['currency']),
                  'Payment Method': formatValue(item['paymentMethod']),
                  'Amount': formatValue(item['amount']),
                  'Wallet Amount': formatValue(item['walletAmount']),
                  'TDS Amount': formatValue(item['tdsAmount']),
                  'Date': formatValue(item['createdAt']),
                  'Status': toTitleCase(item['status']),
                  'Payment Type' : item['orderType'] == 'INVOICE' ? 'Invoice Payment' : item['orderType']== 'ACCOUNT_PAYMENT' ? 'Wallet Payment' :'-',
                };
              }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load credit notes. Status Code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }
}

 void _showTransactionDetails(BuildContext context, Map<String, dynamic> txn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Online Payment History',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                txn.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${(entry.key)} : ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          WidgetSpan(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                             '${entry.value}',
                             style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            )
                            )
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }
