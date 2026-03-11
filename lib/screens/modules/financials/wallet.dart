import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/financials/add_money.dart';
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/wallet_data_manager.dart';
import 'package:myaccount/services/app_services/wallet_service/wallet_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:myaccount/widgets/common_message_toast.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:shimmer/shimmer.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  double walletInr = 0.0;
  double walletUsd = 0.0;
  bool isLoading = true;
  bool isHistoryLoading = true;
  List<Map<String, dynamic>> transactions = [];
  String kycStatus = "";
  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    _fetchWalletHistory();
    var accountData = AccountDataManager().getAccountData();
    kycStatus = accountData?['accountKYCApprovalStatus'];
  }

  Future<void> _fetchWalletData() async {
    try {
      await WalletService().getWalletData(
        requestSourse: "one_yotta",
        requestId: "id012300hjuy0fhgk0",
      );
      final data = WalletDataManager().getWalletData();
      setState(() {
        walletInr = double.tryParse(data?['wallet_amount_inr'] ?? "0") ?? 0.0;
        walletUsd = double.tryParse(data?['wallet_amount_usd'] ?? "0") ?? 0.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchWalletHistory() async {
    try {
      await WalletService().getWalletHistory();
      final historyData = WalletDataManager().getWalletHistoryData();
      setState(() {
        // If API returns a list directly
        if (historyData is List) {
          transactions = List<Map<String, dynamic>>.from(historyData);
        } else if (historyData is Map && historyData['data'] is List) {
          // If API wraps list in a 'data' field
          transactions = List<Map<String, dynamic>>.from(historyData['data']);
        } else {
          transactions = [];
        }
        isHistoryLoading = false;
      });
    } catch (e) {
      setState(() {
        transactions = [];
        isHistoryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: const CommonAppBar(title: 'Wallet'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
          // borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Balance',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF283e81),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceTile('INR', '₹', walletInr, Colors.green),
                _buildBalanceTile('USD', '\$', walletUsd, Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: InkWell(
                  onTap: () {
                    if (kycStatus == 'Approved') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddMoneyPage()),
                      );
                    } else {
                      CommonMessageToast.showMessage(
                        context,
                        QuickAlertType.warning,
                        "Please Complete the KYC to Add Money into the wallet.",
                        'Failed !',
                      );
                    }
                  },
                  child: Text(
                    'Add Money',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transaction History',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283e81),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  isHistoryLoading
                      ? ListView.builder(
                          itemCount: 5, // Show 5 shimmer items as placeholders
                          itemBuilder: (context, index) {
                            return Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  leading: const CircleAvatar(backgroundColor: Colors.white),
                                  title: Container(
                                    width: double.infinity,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                  subtitle: Container(
                                    width: 100,
                                    height: 14,
                                    margin: const EdgeInsets.only(top: 8, right: 100),
                                    color: Colors.white,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 40,
                                        height: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : transactions.isEmpty
                      ? Center(
                        child: Text(
                          'No transactions found',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final txn = transactions[index];
                          return Card(
                            elevation: 0,
                            color: Colors.white70,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    txn['status'] == 'Success'
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                child: Icon(
                                  txn['status'] == 'Success'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color:
                                      txn['status'] == 'Success'
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                              title: Text(
                                'Txn: ${txn['transactionNo'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                txn['createdAt'] ?? txn['date'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${txn['currency'] == 'INR' ? '₹' : '\$'}${(txn['amount'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    txn['status'] ?? '',
                                    style: TextStyle(
                                      color:
                                          txn['status'] == 'Success'
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap:
                                  () => _showTransactionDetails(context, txn),
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

  Widget _buildBalanceTile(
    String currency,
    String symbol,
    double amount,
    Color iconColor,
  ) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withAlpha((0.2 * 255).toInt()),
              child: Text(
                symbol,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withAlpha((0.2 * 255).toInt()),
          child: Text(
            symbol,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            Text(
              '$symbol${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> txn) {
    final String dateValue = (txn['createdAt'] ?? txn['date'] ?? '').toString();
    final Map<String, dynamic> displayData = Map<String, dynamic>.from(txn);
    displayData['dateDisplay'] = dateValue;

    final List<Map<String, String>> displayFields = [
      {'key': 'transactionNo', 'label': 'Transaction No'},
      {'key': 'orderId', 'label': 'Order ID'},
      {'key': 'paymentId', 'label': 'Payment ID'},
      {'key': 'currency', 'label': 'Currency'},
      {'key': 'paymentMethod', 'label': 'Payment Method'},
      {'key': 'amount', 'label': 'Amount'},
      {'key': 'tdsAmount', 'label': 'TDS Amount'},
      {'key': 'dateDisplay', 'label': 'Date'},
      {'key': 'status', 'label': 'Status'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Transaction Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                displayFields
                    .where(
                      (field) =>
                          displayData[field['key']] != null &&
                          displayData[field['key']].toString().isNotEmpty,
                    )
                    .map((field) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${field['label']}: ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: '${displayData[field['key']]}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                    .toList(),
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
}
