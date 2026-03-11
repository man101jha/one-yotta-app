import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class UnbilledTransactionsView extends StatefulWidget {
  const UnbilledTransactionsView({super.key});

  @override
  State<UnbilledTransactionsView> createState() =>
      _UnbilledTransactionsViewState();
}

class _UnbilledTransactionsViewState extends State<UnbilledTransactionsView> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> unbilledTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  double totalUnbilledMrc = 0.0;
  String currency = 'INR';
  final FinancialServices _financialServices = FinancialServices();

  String selectedProductLines = "";
  String selectedProductNames = "";

  @override
  void initState() {
    super.initState();
    fetchUnbilledData();
  }

  Future<void> fetchUnbilledData() async {
    try {
      final sessionData = SessionManager().getSessionData();
      final customerId = sessionData?['bto']?.toString() ?? '12184';
      final data = await _financialServices.getUnbilledData(customerId);

      setState(() {
        if (data['unbilled_data'] != null) {
          unbilledTransactions = List<Map<String, dynamic>>.from(
            data['unbilled_data'],
          );
          filteredTransactions = List.from(unbilledTransactions);
        }
        totalUnbilledMrc = data['total_unbilled_mrc'] ?? 0.0;
        currency = data['currency'] ?? 'INR';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    List<String> productLines =
        selectedProductLines.isEmpty
            ? []
            : selectedProductLines.split(',').map((e) => e.trim()).toList();

    List<String> productNames =
        selectedProductNames.isEmpty
            ? []
            : selectedProductNames.split(',').map((e) => e.trim()).toList();

    setState(() {
      filteredTransactions =
          unbilledTransactions.where((item) {
            bool matchesLine =
                productLines.isEmpty ||
                productLines.contains(item['product_line']?.toString().trim());

            bool matchesName =
                productNames.isEmpty ||
                productNames.contains(
                  item['product_description']?.toString().trim(),
                );

            return matchesLine && matchesName;
          }).toList();
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? input) {
    if (input == null || input.isEmpty) return '-';

    String convertSingleDate(String dateStr) {
      try {
        List<String> parts = dateStr.trim().split('.');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          final date = DateTime(year, month, day);
          return DateFormat('dd-MMM-yyyy').format(date);
        }
        return dateStr;
      } catch (e) {
        return dateStr;
      }
    }

    if (input.toLowerCase().contains(' to ')) {
      List<String> dates = input.toLowerCase().split(' to ');
      if (dates.length >= 2) {
        return '${convertSingleDate(dates[0])} to ${convertSingleDate(dates[1])}';
      }
    }
    return convertSingleDate(input);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: CommonAppBar(
        title: 'Unbilled Transactions',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () async {
              final filters = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => UnbilledFilterPage(
                        selectedProductLines: selectedProductLines,
                        selectedProductNames: selectedProductNames,
                        data: unbilledTransactions,
                      ),
                ),
              );

              if (filters != null) {
                setState(() {
                  selectedProductLines = filters['lines'];
                  selectedProductNames = filters['names'];
                });
                applyFilters();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF4F7FE),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Total Unbilled Amount",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${currency == 'INR' ? '₹' : currency} ${totalUnbilledMrc.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GlobalColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: screenWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
              ),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final item = filteredTransactions[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['product_description'] ??
                                              'Product',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${item['currency']} ${item['unbilled_in_inr']}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildDetailRow(
                                    "SOF Number",
                                    item['sof_number'] ?? '-',
                                  ),
                                  _buildDetailRow(
                                    "Order Line Number",
                                    item['sof_line_number']
                                            ?.toString()
                                            .replaceFirst(RegExp(r'^0+'), '') ??
                                        '-',
                                  ),

                                  _buildDetailRow(
                                    "Product Name", // Showing product_name code as requested in previous logic, description is title
                                    item['product_name'] ?? '-',
                                  ),
                                  _buildDetailRow(
                                    "Product Line",
                                    item['product_line'] ?? '-',
                                  ),
                                  _buildDetailRow(
                                    "Unbilled as on",
                                    item['unbilled_as_on_date'] ?? '-',
                                  ),
                                  _buildDetailRow(
                                    "Current Date",
                                    item['current_date'] ?? '-',
                                  ),
                                  _buildDetailRow(
                                    "Invoice No",
                                    (item['last_invoice_no'] != null &&
                                            item['last_invoice_no'].toString().trim().isNotEmpty)
                                        ? item['last_invoice_no'].toString()
                                        : '-',
                                  ),
                                  _buildDetailRow(
                                    "Invoice Period",
                                    _formatDate(
                                        item['last_invoice_period']?.toString()),
                                  ),
                                  _buildDetailRow(
                                    "Monthly Charges",
                                    "${item['currency'] ?? ''} ${item['total_mrc'] ?? '0.00'}",
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnbilledFilterPage extends StatefulWidget {
  final String selectedProductLines;
  final String selectedProductNames;
  final List<Map<String, dynamic>> data;

  const UnbilledFilterPage({
    super.key,
    required this.selectedProductLines,
    required this.selectedProductNames,
    required this.data,
  });

  @override
  State<UnbilledFilterPage> createState() => _UnbilledFilterPageState();
}

class _UnbilledFilterPageState extends State<UnbilledFilterPage> {
  String selectedCategory = "Product Line";
  late List<String> tempSelectedLines;
  late List<String> tempSelectedNames;

  late List<String> availableLines;
  late List<String> availableNames;

  @override
  void initState() {
    super.initState();
    tempSelectedLines =
        widget.selectedProductLines.isEmpty
            ? []
            : widget.selectedProductLines
                .split(',')
                .map((e) => e.trim())
                .toList();

    tempSelectedNames =
        widget.selectedProductNames.isEmpty
            ? []
            : widget.selectedProductNames
                .split(',')
                .map((e) => e.trim())
                .toList();

    availableLines =
        widget.data
            .map((e) => e['product_line']?.toString().trim())
            .where((e) => e != null && e.isNotEmpty && e != '-')
            .cast<String>()
            .toSet()
            .toList();
    availableLines.sort();

    availableNames =
        widget.data
            .map((e) => e['product_description']?.toString().trim())
            .where((e) => e != null && e.isNotEmpty && e != '-')
            .cast<String>()
            .toSet()
            .toList();
    availableNames.sort();
  }

  void toggleSelection(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  void resetFilters() {
    setState(() {
      tempSelectedLines.clear();
      tempSelectedNames.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Filter Transactions'),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Row(
          children: [
            // Left Panel (Categories)
            Container(
              width: 150,
              color: Colors.grey[200],
              child: ListView(
                children: [
                  ListTile(
                    title: const Text("Product Line"),
                    selected: selectedCategory == "Product Line",
                    onTap: () => setState(() => selectedCategory = "Product Line"),
                  ),
                  ListTile(
                    title: const Text("Product Name"),
                    selected: selectedCategory == "Product Name",
                    onTap: () => setState(() => selectedCategory = "Product Name"),
                  ),
                ],
              ),
            ),
            // Right Panel (Options)
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCategory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children:
                            (selectedCategory == "Product Line"
                                    ? availableLines
                                    : availableNames)
                                .map((item) {
                                  final isSelected =
                                      selectedCategory == "Product Line"
                                          ? tempSelectedLines.contains(item)
                                          : tempSelectedNames.contains(item);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (val) {
                                            toggleSelection(
                                              selectedCategory == "Product Line"
                                                  ? tempSelectedLines
                                                  : tempSelectedNames,
                                              item,
                                            );
                                          },
                                        ),
                                        Flexible(
                                          child: Text(
                                            item,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'lines': tempSelectedLines.join(','),
                  'names': tempSelectedNames.join(','),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
