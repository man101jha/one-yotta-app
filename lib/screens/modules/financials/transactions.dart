import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  bool isLoading = true;
  List<Map<String, String>> transactions = [];
bool _isSearching = false;
TextEditingController _searchController = TextEditingController();
String _searchText = '';
  @override
  void initState() {
    super.initState();
    getTransactionsData();
  }
  final FinancialServices _financialServices = FinancialServices();

  Future<void> getTransactionsData() async {
    try {
      final response = await _financialServices.getTransactionData();

      if (response.isNotEmpty) {
        final List<Map<String, String>> formattedTransactions = response.map<Map<String, String>>((item) {
          return {
            'Transaction No': item['transaction_no'] ?? 'NA',
            'Invoice Ref No': item['invoice_ref_no'] ?? 'NA',
            'Order Ref No': item['sof_ref_no'] ?? 'NA',
            'Posting Date': item['posting_date'] ?? '',
            'Currency': item['transaction_currency'] ?? 'NA',
            'Amount': item['transaction_amount']?.toString() ?? 'NA',
            'Type': item['drcr_indicator'] ?? 'NA',
            'Mode': item['transaction_mode'] ?? 'NA',
            'Status': item['transaction_status'] ?? 'NA',
            'Customer': item['bill_to_customername'] ?? 'NA',
            'PO No': item['customer_po_no'] ?? 'NA',
            'Support To Customer': item['support_to_customername'] ?? 'NA',
            'Description': item['transaction_descrption'] ?? 'NA',
          };
        }).toList();

        formattedTransactions.sort((a, b) {
          final dateA = DateTime.tryParse(a['Posting Date'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['Posting Date'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });

        setState(() {
          transactions = formattedTransactions;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: CommonAppBar(
      title: 'Transaction List',
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
        : transactions.isEmpty
            ? const Center(child: Text('No transactions found',style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey,
                              ),))
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
                            hintText: 'Search Transaction No, Date, Customer...',
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
                            .where((tx) =>
                                _searchText.isEmpty ||
                                (tx['Transaction No'] ?? '')
                                    .toLowerCase()
                                    .contains(_searchText.toLowerCase()) ||
                                (tx['Posting Date'] ?? '')
                                    .toLowerCase()
                                    .contains(_searchText.toLowerCase()) ||
                                (tx['Customer'] ?? '')
                                    .toLowerCase()
                                    .contains(_searchText.toLowerCase()))
                            .length,
                        itemBuilder: (context, index) {
                          final filteredTx = transactions
                              .where((tx) =>
                                  _searchText.isEmpty ||
                                  (tx['Transaction No'] ?? '')
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()) ||
                                  (tx['Posting Date'] ?? '')
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()) ||
                                  (tx['Customer'] ?? '')
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()))
                              .toList();

                          final tx = filteredTx[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                width: 1.0,
                                color: GlobalColors.borderColor,
                              ),
                              color: Colors.white,
                            ),
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  tx['Transaction No'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Transaction Type: ${tx['Mode'] ?? '-'}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      "Amount: ${tx['Amount'] ?? '-'} ${tx['Currency'] ?? ''}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      "Date: ${tx['Posting Date'] ?? '-'}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      "Status: ${tx['Status'] ?? '-'}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                childrenPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                children: [
                                  _buildDetailRow("Customer", tx['Customer'] ?? '-'),
                                  _buildDetailRow("DR/CR", tx['Type'] ?? '-'),
                                  _buildDetailRow("PO No", tx['PO No'] ?? '-'),
                                  _buildDetailRow("Invoice Ref", tx['Invoice Ref No'] ?? '-'),
                                  _buildDetailRow("Support To Customer", tx['Support To Customer'] ?? '-'),
                                  _buildDetailRow("Description", tx['Description'] ?? '-'),
                                ],
                              ),
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
 }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }