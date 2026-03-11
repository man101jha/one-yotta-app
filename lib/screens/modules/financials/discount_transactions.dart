import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class DiscountTransactionsView extends StatefulWidget {
  const DiscountTransactionsView({super.key});

  @override
  State<DiscountTransactionsView> createState() =>
      _DiscountTransactionsViewState();
}

class _DiscountTransactionsViewState extends State<DiscountTransactionsView> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDiscountTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiscountTransactions() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) throw Exception('Access token not found.');

      final sessionData = SessionManager().getSessionData();
      final crmId = sessionData?['crmId']?.toString() ??
          sessionData?['bto']?.toString() ??
          '';

      final response = await http.get(
        Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_credit/api/v1/dcod/transactions/$crmId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];

        final mapped = data
            .map<Map<String, dynamic>>((item) => {
                  'Reference No': item['referenceNo'] ?? '-',
                  'Discount Code': item['discountCode'] ?? '-',
                  'Amount': (item['discountCodeDetails']?['discountValue'] != null)
                      ? double.tryParse(
                              item['discountCodeDetails']['discountValue'].toString()) ??
                          0.0
                      : 0.0,
                  'Type': item['discountCodeDetails']?['discountCodeType'] ?? '-',
                  'Currency': item['discountCodeDetails']?['currency'] ?? '-',
                  'Applied From': item['applyFrom'] ?? '-',
                  'Discount Description':
                      item['discountCodeDetails']?['discountDesc'] ?? '-',
                  'Used Amount': (item['usedAmount'] != null)
                      ? double.tryParse(item['usedAmount'].toString()) ?? 0.0
                      : 0.0,
                  'Transaction Date': item['usedOn'] != null
                      ? _formatDateTime(item['usedOn'].toString())
                      : '-',
                  'Remark': item['remark'] ?? '-',
                  '_rawDate': item['usedOn'] ?? '',
                })
            .toList();

        // Sort by Transaction Date descending
        mapped.sort((a, b) {
          final da = DateTime.tryParse(a['_rawDate'].toString()) ?? DateTime(0);
          final db = DateTime.tryParse(b['_rawDate'].toString()) ?? DateTime(0);
          return db.compareTo(da);
        });

        setState(() {
          allTransactions = mapped;
          filteredTransactions = mapped;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data (${response.statusCode})';
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

  String _formatDateTime(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MMM-yyyy hh:mm a').format(date);
    } catch (_) {
      return dateTimeStr;
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      filteredTransactions = q.isEmpty
          ? allTransactions
          : allTransactions.where((item) {
              return item.values.any(
                (v) => v.toString().toLowerCase().contains(q),
              );
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: const CommonAppBar(title: 'Discount Transactions'),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFFF4F7FE),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          // Body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
              ),
              child: isLoading
                  ? _buildShimmer()
                  : errorMessage != null
                      ? Center(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : filteredTransactions.isEmpty
                          ? const Center(child: Text('No Data Available'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                return _buildCard(filteredTransactions[index]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final amount = item['Amount'] as double;
    final usedAmount = item['Used Amount'] as double;
    final numFmt = NumberFormat('#,##0.00', 'en_US');

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['Discount Code'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GlobalColors.mainColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GlobalColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['Type'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GlobalColors.mainColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['Discount Description'],
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Divider(height: 18),
            _row('Reference No', item['Reference No']),
            _row('Currency', item['Currency']),
            _row('Discount Amount',
                '${item['Currency']} ${numFmt.format(amount)}'),
            _row('Used Amount',
                '${item['Currency']} ${numFmt.format(usedAmount)}'),
            _row('Applied From', item['Applied From']),
            _row('Transaction Date', item['Transaction Date']),
            if ((item['Remark'] ?? '-') != '-')
              _row('Remark', item['Remark']),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(height: 140, color: Colors.white),
        ),
      ),
    );
  }
}
