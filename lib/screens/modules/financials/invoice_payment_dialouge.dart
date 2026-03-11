import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myaccount/screens/modules/financials/invoice_list.dart';
import 'package:myaccount/screens/modules/financials/payment/data/payData.dart';
import 'package:myaccount/screens/modules/financials/payment/pages/webview_page.dart';
import 'package:myaccount/services/app_services/wallet_service/wallet_service.dart';
import 'package:myaccount/services/app_services/session/wallet_data_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';

class InvoicePaymentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> selectedInvoices;
  final String title;
  final BuildContext parentContext; // ✅ for safe navigation after dialog closes

  const InvoicePaymentDialog({
    Key? key,
    required this.selectedInvoices,
    required this.parentContext,
    this.title = 'Checkout Validation',
  }) : super(key: key);

  @override
  State<InvoicePaymentDialog> createState() => _InvoicePaymentDialogState();
}

class _InvoicePaymentDialogState extends State<InvoicePaymentDialog> {
  double walletInr = 0.0;
  double walletUsd = 0.0;
  bool isLoading = true;
  bool hideWallet = false;
  String currency = '';
  String currencyIcon = '';
  double originalWalletBalance = 0.0;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taxController = TextEditingController(text: '0');
  String? _tdsError; // Error message for TDS validation
  bool isWalletChecked = false;
  bool isValid = true;

  late List<Map<String, dynamic>> tableData;
  late double netAmount;
  late double payableamount;
  late double totalDue;
  late double finalAmountDue;
  double allInvoiceDue = 0.0;

  String? bto;
  String walletConsent = 'False';

  @override
  void initState() {
    super.initState();
    _initFromInvoices();
    _fetchWalletData();
  }

  void _initFromInvoices() {
    final content = widget.selectedInvoices;
    if (content.isEmpty) return;

    final selectedCurrency = content.first['currency']?.toString() ?? '';
    currency = selectedCurrency;
    currencyIcon = currency;

    tableData = [];
    allInvoiceDue = 0.0;

    for (final item in content) {
      hideWallet =
          item['billing_org']?.toString() == 'IN20' ? true : hideWallet;
      final mapped = {
        'Invoice No': item['invoice no'] ?? item['invoiceNumber'] ?? '-',
        'Order No': item['order no'] ?? '-',
        'Due Date': item['due date'] ?? item['dueDate'] ?? '-',
        'Invoice Date': item['invoice date'] ?? item['invoiceDate'] ?? '-',
        'Billing Organization': item['billing_org_name'] ?? '-',
        'Customer Name': item['company_name'] ?? '-',
        'Currency': item['currency'] ?? currency,
        'Amount Due':
            (double.tryParse((item['amount due'] ?? 0).toString()) ?? 0.0),
        'Net Amount':
            (double.tryParse((item['net_amount'] ?? 0).toString()) ?? 0.0),
        'Tax Amount':
            (double.tryParse((item['tax_amount'] ?? 0).toString()) ?? 0.0),
        'Billing Country': item['billing country'] ?? '-',
        'invoice_bill_from_org': item['invoice_bill_from_org'] ?? '-',
      };
      tableData.add(mapped);
      allInvoiceDue += mapped['Amount Due'] ?? 0.0;
    }

    netAmount = tableData.fold(0.0, (sum, e) => sum + (e['Net Amount'] ?? 0.0));
    totalDue = allInvoiceDue;
    payableamount = netAmount;
    finalAmountDue = totalDue;
  }

  double get totalTaxAmount =>
      tableData.fold(0.0, (sum, e) => sum + ((e['Tax Amount'] as double?) ?? 0.0));

  Future<void> _fetchWalletData() async {
    try {
      await WalletService().getWalletData(
        requestSourse: "one_yotta",
        requestId: "id012300hjuy0fhgk0",
      );
      final data = WalletDataManager().getWalletData();
      if (!mounted) return;
      setState(() {
        walletInr =
            double.tryParse((data?['wallet_amount_inr'] ?? '0').toString()) ??
            0.0;
        walletUsd =
            double.tryParse((data?['wallet_amount_usd'] ?? '0').toString()) ??
            0.0;
        if (currency == 'INR') {
          originalWalletBalance = walletInr;
        } else if (currency == 'USD') {
          originalWalletBalance = walletUsd;
        }
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _onWalletToggle(bool? checked) {
    setState(() {
      isWalletChecked = checked ?? false;
      final walletBalance = currency == 'INR' ? walletInr : walletUsd;
      if (isWalletChecked) {
        finalAmountDue =
            totalDue > walletBalance
                ? totalDue - _taxAsDouble() - walletBalance
                : 0.0;
        payableamount =
            netAmount > walletBalance ? netAmount - walletBalance : 0.0;
      } else {
        finalAmountDue = totalDue - _taxAsDouble();
        payableamount = netAmount;
      }
    });
  }

  double _taxAsDouble() => double.tryParse(_taxController.text) ?? 0.0;

  void _validateTds(String value) {
    setState(() {
      double tds = double.tryParse(value) ?? 0.0;
      double maxTds = netAmount * 0.10; // 10% of Net Amount

      if (tds > maxTds) {
        _tdsError = 'TDS cannot exceed 10% of Net Amount (₹${maxTds.toStringAsFixed(2)})';
        isValid = false;
      } else {
        _tdsError = null;
        isValid = true;
      }
      
      // Recalculate amounts
       if (isWalletChecked) {
         final walletBalance = currency == 'INR' ? walletInr : walletUsd;
        finalAmountDue =
            totalDue > walletBalance
                ? totalDue - tds - walletBalance
                : 0.0;
      } else {
        finalAmountDue = totalDue - tds;
      }
    });
  }

  Future<void> _confirmPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Payment'),
            content: const Text('Do you want to proceed with the payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ok'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final walletUsed = isWalletChecked;
      if (walletUsed && finalAmountDue == 0) {
        await _walletPayment();
      } else {
        await _ccAvenuePayment();
      }
    }
  }

  Future<void> _walletPayment() async {
    try {
      final payload =
          tableData.map((invoice) {
            return {
              "pg_amount": invoice['pg_amount'] ?? 0,
              "reference_id": invoice['Invoice No'] ?? '-',
              "currency": invoice['Currency'] ?? 'INR',
              "billing_org": invoice['Billing Organization'] ?? '-',
              "company_name": invoice['Customer Name'] ?? '-',
              "billing_country": invoice['Billing Country'] ?? '-',
              "net_amount": invoice['Net Amount'] ?? 0,
              "tax_amount": invoice['Tax Amount'] ?? 0,
              "tds_amount": invoice['Tds Amount'] ?? 0,
              "invoice_bill_from_org": invoice['invoice_bill_from_org'] ?? '',
              "wallet_amount":
                  (invoice['wallet_used'] == true)
                      ? (currency == 'INR' ? walletInr : walletUsd)
                      : 0,
            };
          }).toList();

      final Map<String, dynamic> response = await WalletService().getEnc(
        payload,
        'invoice',
        isWalletChecked,
      );

      if (!mounted) return;

      final paymentId = response['payment_id']?.toString() ?? '-';
      print(response);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment is successfully completed.\nTransaction ID : $paymentId',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment failed')));
    }
  }

  Future<void> _ccAvenuePayment() async {
    try {
      final payload =
          tableData.map((invoice) {
            return {
              "pg_amount": invoice['pg_amount'] ?? 0,
              "reference_id": invoice['Invoice No'] ?? '-',
              "currency": invoice['Currency'] ?? 'INR',
              "billing_org": invoice['Billing Organization'] ?? '-',
              "company_name": invoice['Customer Name'] ?? '-',
              "billing_country": invoice['Billing Country'] ?? '-',
              "net_amount": invoice['Net Amount'] ?? 0,
              "tax_amount": invoice['Tax Amount'] ?? 0,
              "tds_amount": invoice['Tds Amount'] ?? 0,
              "invoice_bill_from_org": invoice['invoice_bill_from_org'] ?? '',
              "wallet_amount":
                  (invoice['wallet_used'] == true)
                      ? (currency == 'INR' ? walletInr : walletUsd)
                      : 0,
            };
          }).toList();

      final Map<String, dynamic> response = await WalletService().getEnc(
        payload,
        'invoice',
        isWalletChecked,
      );

      if (!mounted) return;

      // Close dialog
      Navigator.of(context).pop();

      // Open WebView
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => WebviewPage(
            data: PaymentData.fromJson(response),
          ),
        ),
      );

      if (result == true && mounted) {
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InvoiceListView(refresh: true)),
        );
      }



    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment failed')));
    }
  }

  void _proceedAction(String action) {
    if (action == 'Pay') {
      for (final invoice in tableData) {
        invoice['Tds Amount'] = _taxAsDouble();
        invoice['pg_amount'] = finalAmountDue;
        invoice['wallet_used'] = isWalletChecked;
      }
      _confirmPayment();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final walletDisplay = currency == 'INR' ? walletInr : walletUsd;
    final walletLabel =
        currency == 'INR'
            ? '₹ ${walletInr.toStringAsFixed(2)}'
            : currency == 'USD'
            ? '\$ ${walletUsd.toStringAsFixed(2)}'
            : '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, minWidth: 400),
        child: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey[200],
                    ),
                    columns: const [
                      DataColumn(label: Text('Invoice No')),
                      DataColumn(label: Text('Net Amount')),
                      DataColumn(label: Text('Tax Amount')),
                      DataColumn(label: Text('Amount Due')),
                    ],
                    rows:
                        tableData
                            .map(
                              (invoice) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(invoice['Invoice No'].toString()),
                                  ),
                                  DataCell(
                                    Text(
                                      numberFormat.format(
                                        invoice['Net Amount'],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      numberFormat.format(
                                        invoice['Tax Amount'],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      numberFormat.format(
                                        invoice['Amount Due'],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Net Amount: ₹${numberFormat.format(netAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Tax Amount: ₹${numberFormat.format(totalTaxAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Amount Due: ₹${numberFormat.format(finalAmountDue)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Amount Due: ₹${numberFormat.format(totalDue)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!hideWallet)
                  Row(
                    children: [
                      Checkbox(
                        value: isWalletChecked,
                        onChanged:
                            (walletDisplay == 0.0 || walletDisplay.isNaN)
                                ? null
                                : _onWalletToggle,
                      ),
                      Text(
                        isLoading
                            ? 'Loading Wallet...'
                            : 'Use Wallet Balance: $walletLabel',
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (tableData.isNotEmpty && tableData[0]['Currency'] == 'INR')
                  TextFormField(
                    controller: _taxController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Enter TDS (Max 10% of Net Amount)',
                      border: const OutlineInputBorder(),
                      errorText: _tdsError, // Show error message
                    ),
                    onChanged: _validateTds,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.backgroundColor,
                        ),
                        onPressed: () => _proceedAction('Cancel'),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GlobalColors.mainColor
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isValid ? GlobalColors.mainColor : Colors.grey,
                        ),
                        onPressed: isValid ? () => _proceedAction('Pay') : null,
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taxController.dispose();
    super.dispose();
  }
}
