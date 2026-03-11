import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:myaccount/screens/modules/financials/applied_voucher.dart';
import 'package:myaccount/screens/modules/financials/credit_voucher_details.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class MicrositeData {
  final String name;
  final int availableINR, usedINR, expiredINR;
  final double availableUSD, usedUSD, expiredUSD;
  MicrositeData({
    required this.name,
    required this.availableINR,
    required this.availableUSD,
    required this.usedINR,
    required this.usedUSD,
    required this.expiredINR,
    required this.expiredUSD,
  });
}

final FinancialServices financialServices = FinancialServices();

Future<List<MicrositeData>> fetchCombinedMicrosites() async {
  final micrositeResponse = await financialServices.getAvailableBalance();
  final usedExpiredResponse = await financialServices.getUsedExpiredBalance();

  final List<dynamic> microsites =
      jsonDecode(micrositeResponse.body)['microsites'] ?? [];
  final Map<String, dynamic> usedInfo =
      jsonDecode(usedExpiredResponse.body)['used_info'] ?? {};
  final Map<String, dynamic> expiredInfo =
      jsonDecode(usedExpiredResponse.body)['exp_info'] ?? {};

  final Map<String, MicrositeData> micrositeMap = {};

  // Helper functions to safely parse values
  int parseInt(dynamic value) => (value ?? 0).toInt();
  double parseDouble(dynamic value) => (value ?? 0).toDouble();

  // Populate available balances
  for (var site in microsites) {
    final name = site['name'] ?? 'Unknown';
    micrositeMap[name] = MicrositeData(
      name: name,
      availableINR: parseInt(site['amountInINR']),
      availableUSD: parseDouble(site['amountInUSD']),
      usedINR: 0,
      usedUSD: 0.0,
      expiredINR: 0,
      expiredUSD: 0.0,
    );
  }

  // Add used amounts
  usedInfo.forEach((key, value) {
    final name = key.replaceAll('_microsite', '');
    final existing = micrositeMap[name];

    micrositeMap[name] = MicrositeData(
      name: name,
      availableINR: existing?.availableINR ?? 0,
      availableUSD: existing?.availableUSD ?? 0.0,
      usedINR: parseInt(value['amountInINR']),
      usedUSD: parseDouble(value['amountInUSD']),
      expiredINR: existing?.expiredINR ?? 0,
      expiredUSD: existing?.expiredUSD ?? 0.0,
    );
  });

  // Add expired amounts
  expiredInfo.forEach((key, value) {
    final name = key.replaceAll('_microsite', '');
    final existing = micrositeMap[name];

    micrositeMap[name] = MicrositeData(
      name: name,
      availableINR: existing?.availableINR ?? 0,
      availableUSD: existing?.availableUSD ?? 0.0,
      usedINR: existing?.usedINR ?? 0,
      usedUSD: existing?.usedUSD ?? 0.0,
      expiredINR: parseInt(value['amountInINR']),
      expiredUSD: parseDouble(value['amountInUSD']),
    );
  });

  return micrositeMap.values.toList();
}

// Card UI Widget
class MicrositeCard extends StatelessWidget {
  final String name;
  final int availableINR, usedINR, expiredINR;
  final double availableUSD, usedUSD, expiredUSD;

  const MicrositeCard({
    super.key,
    required this.name,
    required this.availableINR,
    required this.availableUSD,
    required this.usedINR,
    required this.usedUSD,
    required this.expiredINR,
    required this.expiredUSD,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: GlobalColors.mainColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _buildAmountSection(
      "Available Balance",
      availableINR,
      availableUSD,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditVoucherDetailsPage(
              voucherType: 'availableBalance',
              microService: name,
            ),
          ),
        );
      },
    ),
    _buildAmountSection(
      "Used Amount",
      usedINR,
      usedUSD,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditVoucherDetailsPage(
              voucherType: 'usedAmount',
              microService: name,
            ),
          ),
        );
      },
    ),
    _buildAmountSection(
      "Expired Amount",
      expiredINR,
      expiredUSD,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditVoucherDetailsPage(
              voucherType: 'expiredAmount',
              microService: name,
            ),
          ),
        );
      },
    ),
  ],
),
 ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(String title, int inr, double usd, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [const Icon(Icons.currency_rupee, size: 16), Text('$inr')],
        ),
        Row(children: [const Icon(Icons.attach_money, size: 16), Text('$usd')]),
      ],
    ),
  );
}
}

// Main Screen
class CreditVoucherScreen extends StatefulWidget {
  const CreditVoucherScreen({super.key});
  @override
  State<CreditVoucherScreen> createState() => _CreditVoucherScreenState();
}

class _CreditVoucherScreenState extends State<CreditVoucherScreen> {
  late Future<List<MicrositeData>> micrositesFuture;
  final FinancialServices _financialServices = FinancialServices();
  @override
  void initState() {
    super.initState();
    micrositesFuture = fetchCombinedMicrosites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: const CommonAppBar(title: 'Credit Voucher'),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
              ),
              child: FutureBuilder<List<MicrositeData>>(
                future: micrositesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No microsites found"));
                  }

                  final microsites = snapshot.data!;
                  final totalINR = microsites.fold<int>(
                    0,
                    (sum, m) => sum + m.availableINR,
                  );
                  final totalUSD = microsites.fold<double>(
                    0.0,
                    (sum, m) => sum + m.availableUSD,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCreditBalanceCard(totalINR, totalUSD),
                        const SizedBox(height: 16),
                        ...microsites.map(
                          (microsite) => MicrositeCard(
                            name: microsite.name,
                            availableINR: microsite.availableINR,
                            availableUSD: microsite.availableUSD,
                            usedINR: microsite.usedINR,
                            usedUSD: microsite.usedUSD,
                            expiredINR: microsite.expiredINR,
                            expiredUSD: microsite.expiredUSD,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildCreditBalanceCard(int totalINR, double totalUSD) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF283E81), size: 22),
              SizedBox(width: 6),
              Text(
                'Credit Account Balance',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF283E81),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAmountBox(
                Icons.currency_rupee,
                totalINR.toString(),
                const Color(0xFFE1E3E6),
              ),
              const SizedBox(width: 12),
              _buildAmountBox(
                Icons.attach_money,
                totalUSD.toStringAsFixed(2),
                const Color(0xFFE1E3E6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 130,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 1,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => RedeemVoucherDialog(
                            onRedeemed: () {
                              setState(() {
                                micrositesFuture = fetchCombinedMicrosites();
                              });
                            },
                          ),
                    );
                  },
                  child: const Text(
                    "Redeem",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 130,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: GlobalColors.mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide.none,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppliedVoucherView(),
                      ),
                    );
                  },
                  child: const Text(
                    "Applied Vouchers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAmountBox(IconData icon, String amount, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Microsite>> fetchMicrosites() async {
    final response = await _financialServices.getAvailableBalance();

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final microsites =
          (jsonData['microsites'] as List)
              .map((e) => Microsite.fromJson(e))
              .toList();
      return microsites;
    } else {
      throw Exception('Failed to load microsites');
    }
  }
}

class Microsite {
  final String name;
  final double amountInINR;
  final double amountInUSD;

  Microsite({
    required this.name,
    required this.amountInINR,
    required this.amountInUSD,
  });

  factory Microsite.fromJson(Map<String, dynamic> json) {
    return Microsite(
      name: json['name'],
      amountInINR: (json['amountInINR'] ?? 0).toDouble(),
      amountInUSD: (json['amountInUSD'] ?? 0).toDouble(),
    );
  }
}

class RedeemVoucherDialog extends StatefulWidget {
  final VoidCallback onRedeemed;

  const RedeemVoucherDialog({super.key, required this.onRedeemed});

  @override
  State<RedeemVoucherDialog> createState() => _RedeemVoucherDialogState();
}

class _RedeemVoucherDialogState extends State<RedeemVoucherDialog> {
  final TextEditingController _controller = TextEditingController();
  bool isRedeeming = false;
  String? errorText;

  final FinancialServices _financialServices = FinancialServices();

  Future<void> redeemCoupon() async {
    final code = _controller.text.trim();

    if (code.isEmpty) {
      setState(() => errorText = 'Coupon code is required');
      return;
    }

    final sessionData = SessionManager().getSessionData();
    final accountData = AccountDataManager().getAccountData();
    final uuid = sessionData?['userUUID'];
    final crmId = sessionData?['sto'];
    final kycStatus = accountData?['accountKYCApprovalStatus'];

    if (kycStatus != 'Approved') {
      _showErrorDialog("Please complete your KYC to redeem vouchers.");
      return;
    }

    setState(() {
      isRedeeming = true;
      errorText = null;
    });

    try {
      final result = await _financialServices.redeemVoucher(
        voucherCode: code,
        customerId: crmId,
        userUUID: uuid,
        applyFrom: 'Shakti',
      );

      Navigator.pop(context);
      widget.onRedeemed();
      _showSuccessDialog("Voucher redeemed successfully.");
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => isRedeeming = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Success"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    String finalMessage = message;

    try {
      final Map<String, dynamic> json = jsonDecode(message);
      finalMessage = json['message'] ?? 'Something went wrong';
    } catch (_) {}

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Error"),
            content: Text(finalMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Redeem Credit Voucher",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F6BED),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter Voucher Code',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: const Color(0xFF4F6BED),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              isRedeeming
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: redeemCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F6BED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        "Redeem",
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
    );
  }
}
