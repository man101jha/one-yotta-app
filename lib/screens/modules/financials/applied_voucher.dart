import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class AppliedVoucherView extends StatefulWidget {
  const AppliedVoucherView({super.key});

  @override
  State<AppliedVoucherView> createState() => _AppliedVoucherViewState();
}

class _AppliedVoucherViewState extends State<AppliedVoucherView> {
  final FinancialServices _financialServices = FinancialServices();
  List<Map<String, dynamic>> appliedVouchers = [];
  bool isLoading = true;
bool _isSearching = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchAppliedHistory();
  }

  Future<void> fetchAppliedHistory() async {
    try {
      final response = await _financialServices.getAppliedHistory();
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        setState(() {
          appliedVouchers =
              jsonList.map<Map<String, dynamic>>((entry) {
                return {
                  "voucher_code": entry["coupon_code"],
                  "microsite": entry["coupon_for"],
                  "currency": entry["coupon_currency"],
                  "amount": entry["coupon_amount"].toStringAsFixed(2),
                  "applied_by": entry["coupon_used_by"],
                  "applied_on": _formatDate(entry["coupon_applied_at"]),
                  "expiry_on":
                      entry["coupon_expired_at"] != null
                          ? _formatDate(
                            entry["coupon_expired_at"],
                            isDateOnly: true,
                          )
                          : "-",
                  "status": entry["coupon_status"],
                  "Min_bill_amount": entry["coupon_min_bill_amt"],
                  "Max_credit_usage": entry["coupon_max_credit_usage"],
                  "Invoice %": entry["coupon_usage_percent"],
                  "products": entry["products"] ?? [],
                };
              }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load vouchers');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String? rawDate, {bool isDateOnly = false}) {
    if (rawDate == null) return "-";
    try {
      final date = DateTime.parse(rawDate.split('.')[0]);
      return isDateOnly
          ? "${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}"
          : "${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final filteredVouchers = appliedVouchers.where((voucher) {
      final code = (voucher['voucher_code'] ?? '').toString().toLowerCase();
      final microsite = (voucher['microsite'] ?? '').toString().toLowerCase();
      return _searchText.isEmpty ||
          code.contains(_searchText.toLowerCase()) ||
          microsite.contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: GlobalColors.backgroundColor,
      appBar: CommonAppBar(
        title: 'Applied Vouchers',
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchText = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search voucher code or microsite...',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVouchers.isEmpty
                    ? const Center(child: Text('No vouchers found'))
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FE),
                          border: Border.all(
                            width: 1.0,
                            color: GlobalColors.borderColor,
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: filteredVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher = filteredVouchers[index];
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
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    voucher['voucher_code'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Currency: ${voucher['currency']}", style: const TextStyle(color: Colors.grey)),
                                      Text("Amount: ${voucher['amount']}", style: const TextStyle(color: Colors.grey)),
                                      Text("Microsite: ${voucher['microsite']}", style: const TextStyle(color: Colors.grey)),
                                      Text("Status: ${voucher['status']}", style: const TextStyle(color: Colors.grey)),
                                      Text("Applied On: ${voucher['applied_on']}", style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  children: [
                                    _buildDetailRow("Min Bill Amount", voucher['Min_bill_amount']),
                                    _buildDetailRow("Max Credit Usage", voucher['Max_credit_usage']),
                                    _buildDetailRow("Invoice %", voucher['Invoice %']),
                                    _buildDetailRow("Expiry On", voucher['expiry_on']),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        final products = voucher['products'] ?? [];
                                        showProductDialog(context, products);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: GlobalColors.mainColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                      ),
                                      child: const Text('Services', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                    ),
                                    const SizedBox(height: 8),
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
  void showProductDialog(BuildContext context, List<dynamic> products) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 25,
                spreadRadius: 4,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align title left
            children: [
              const Text(
                'Applied Voucher - Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F6BED),
                ),
              ),
              const SizedBox(height: 16),

              // Container to visually separate the table/message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: products.isEmpty
                    ? const Text(
                        'Voucher Applicable for all services.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 360),
                          child: Table(
                            border: TableBorder.all(color: Colors.grey.shade300),
                            columnWidths: const {
                              0: FixedColumnWidth(60),
                              1: FlexColumnWidth(),
                              2: FixedColumnWidth(80),
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              // Table header
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F0FE),
                                ),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      'Sr. No.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F6BED),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      'Product',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F6BED),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      'Amount',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F6BED),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Data rows
                              for (int i = 0; i < products.length; i++)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: i % 2 == 0
                                        ? Colors.grey.shade50
                                        : Colors.transparent,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text('${i + 1}'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(products[i]['prd_name'] ?? '-'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        products[i]['prd_amount']?.toStringAsFixed(2) ?? '0.00',
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Close button with compact width and right alignment
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F6BED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}