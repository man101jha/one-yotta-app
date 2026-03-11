import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myaccount/services/app_services/finance_service/service_balance_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:myaccount/screens/modules/financials/wallet.dart';
import 'package:myaccount/screens/modules/financials/invoice_list.dart';
import 'package:myaccount/screens/modules/financials/unbilled_transactions.dart';
import 'package:myaccount/screens/modules/financials/credit_voucher_screen.dart';

class ServiceBalanceView extends StatefulWidget {
  const ServiceBalanceView({super.key});

  @override
  State<ServiceBalanceView> createState() => _ServiceBalanceViewState();
}

class _ServiceBalanceViewState extends State<ServiceBalanceView> {
  final ServiceBalanceService _serviceBalanceService = ServiceBalanceService();
  bool isLoading = true;
  Map<String, dynamic>? balanceData;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await _serviceBalanceService.getServiceBalance();
      if (response.statusCode == 200) {
        setState(() {
          balanceData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred';
        isLoading = false;
      });
    }
  }

  String _formatCurrency(String? value) {
    if (value == null) return '0.00';
    final double amount = double.tryParse(value) ?? 0.00;
    final format = NumberFormat("#,##0.00", "en_US");
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: const CommonAppBar(title: 'Service Balance'),
      body:
          isLoading
              ? _buildShimmerLoading()
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Balance',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2541),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildRow(
                            'Wallet Balance (+)',
                            balanceData?['details']?['wallet_total_amount_inr'],
                            Colors.green,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WalletView(),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildRow(
                            'Credit Voucher (+)',
                            balanceData?['details']?['cr_voucher_balance_total_inr'],
                            Colors.green,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const CreditVoucherScreen(),
                                  ),
                                ),
                          ),
                          _buildRow(
                            'Credit Limit (+)',
                            balanceData?['details']?['cr_limit'],
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildRow(
                            'Outstanding Balance (-)',
                            balanceData?['details']?['total_outstanding_amount'],
                            Colors.red,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const InvoiceListView(),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildRow(
                            'Unbilled (-)',
                            balanceData?['details']?['unbilled_amount'],
                            Colors.red,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const UnbilledTransactionsView(),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Service Balance',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1B2541),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          '\u20B9', // Rupee Symbol
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatCurrency(
                                            balanceData?['service_balance'],
                                          ),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRow(
    String title,
    String? amountStr,
    Color valueColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: onTap != null ? const Color(0xFF0056D2) : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    Text(
                      '\u20B9',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(amountStr),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 120, height: 16, color: Colors.white),
                        Container(width: 100, height: 16, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 140, height: 20, color: Colors.white),
                      Container(width: 150, height: 24, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
