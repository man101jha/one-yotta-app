import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:myaccount/screens/modules/financials/credit_notes.dart';
import 'package:myaccount/screens/modules/financials/credit_voucher_screen.dart';
import 'package:myaccount/screens/modules/financials/discount_transactions.dart';
import 'package:myaccount/screens/modules/financials/invoice_payment_dialouge.dart';
import 'package:myaccount/screens/modules/financials/payment_history.dart';
import 'package:myaccount/screens/modules/financials/service_balance.dart';
import 'package:myaccount/screens/modules/financials/transactions.dart';
import 'package:myaccount/screens/modules/financials/wallet.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:myaccount/screens/modules/financials/unbilled_transactions.dart';
import 'package:shimmer/shimmer.dart';

import 'package:http/http.dart' as http;
import 'package:myaccount/navigation/route_observer.dart';

class InvoiceListView extends StatefulWidget {
  final String? xAxisValue;
  final String? selectedLabel;
  final bool refresh;
  const InvoiceListView({super.key, this.selectedLabel, this.xAxisValue, this.refresh = false,});

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> with RouteAware{
  DateTime? lastDate;
  String operatorStorage = '';
  bool isSelectionMode = false;
  List<Map<String, dynamic>> selectedInvoices = [];
  Map<String, String> countryMap = {};
  String selectedTypeFilter = "All";
  @override
  void initState() {
    super.initState();
    lastDate = getDateBefore(widget.xAxisValue);
    debugPrint('🔥 InvoiceListView initState called, refresh=${widget.refresh}');
    selectedTypeFilter = widget.selectedLabel ?? 'ALL';
    print("selectedTypeFilter: $selectedTypeFilter");
    if (widget.refresh) {
      fetchInvoicesData(); // force reload
    } else {
      fetchInvoicesData(); // normal load
    }
    loadCallingCodes();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    debugPrint('🔄 InvoiceListView resumed');
    fetchInvoicesData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  String selectedTab = 'Open';
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, String>> invoices = [];
  Map<int, bool> expandedRows = {};
  final FinancialServices _financialServices = FinancialServices();
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';

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

  DateTime? parseInvoiceDate(dynamic dateStr) {
    if (dateStr == null) return null;
    final str = dateStr.toString().trim();
    if (str.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(str);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadCallingCodes() async {
    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/callingcodes',
      ),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      countryMap = {
        for (var item in list) item['countryKey']: item['countryName'],
      };
    }
  }

  Future<void> fetchInvoicesData() async {
    try {
      final response = await _financialServices.getInvoicesData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notes = data['Response'] ?? [];

        final dateFormat = DateFormat('dd-MM-yyyy');
        final today = DateTime.now();

        List<Map<String, String>> filteredInvoices = [];

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

          // If a type filter was provided (from chart tap), apply age-based filtering
          final status = item['invoice_status']?.toString().toUpperCase() ?? '';
          final sel = selectedTypeFilter?.toString().trim().toLowerCase() ?? '';

          if (sel.isNotEmpty && sel != 'all' && sel != 'all'.toLowerCase()) {
            // Only consider open invoices for age-based filters
            if (status == 'OPEN') {
              final ageDays = today.difference(invoiceDate).inDays;

              if (sel.startsWith('>')) {
                final num = int.tryParse(sel.substring(1).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                include = ageDays > num;
              } else if (sel.contains('-')) {
                final parts = sel.split('-');
                final a = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                final b = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                final low = a <= b ? a : b;
                final high = a <= b ? b : a;
                include = ageDays >= low && ageDays <= high;
              } else if (sel.endsWith('+')) {
                final num = int.tryParse(sel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                include = ageDays >= num;
              } else {
                // If it's just a number, treat as "within last N days" (<= N)
                final num = int.tryParse(sel.replaceAll(RegExp(r'[^0-9]'), ''));
                if (num != null) {
                  include = ageDays <= num;
                }
              }
            } else {
              include = false;
            }
          } else {
            // Fallback: existing operatorStorage logic
            if (lastDate != null && operatorStorage.isNotEmpty) {
              if (operatorStorage == '>') {
                include = invoiceDate.isBefore(lastDate!) && status == 'OPEN';
              } else if (operatorStorage == '<') {
                include =
                    invoiceDate.isAfter(lastDate!) &&
                    invoiceDate.isBefore(today) &&
                    status == 'OPEN';
              }
            }
          }

          if (include) {
            filteredInvoices.add({
              'invoiceNumber':
                  (item['invoice_no']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_no'],
              'order no':
                  (item['sof_no']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['sof_no'],
              'period':
                  (item['invoice_period']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_period'],
              'dueDate':
                  (item['invoice_due_date']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_due_date'],
              'due date search':
                  (item['invoice_due_date']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_due_date'],
              'invoice date':
                  (item['invoice_date']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_date'],
              // 'invoice date search': item['invoice_date'] ?? '-',
              'currency':
                  (item['invoice_currency']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_currency'],
              'total amount':
                  (item['invoice_total_amount']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_total_amount'],
              'amount paid':
                  (item['invoice_amount_paid']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_amount_paid'],
              'amount due':
                  (item['invoice_amount_due']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_amount_due'],
              'status':
                  (item['invoice_status']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['invoice_status'],
              'billing country':
                  (item['invoice_bill_address_country']
                              ?.toString()
                              .trim()
                              .isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_bill_address_country'],
              'net_amount':
                  (item['invoice_net_amount']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_net_amount'],
              'tax_amount':
                  (item['invoice_tax_amount']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_tax_amount'],
              'invoice_bill_from_org':
                  (item['invoice_bill_from_org']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_bill_from_org'],
              'billing_org_name':
                  (item['invoice_bill_from_org_name']
                              ?.toString()
                              .trim()
                              .isEmpty ??
                          true)
                      ? '-'
                      : item['invoice_bill_from_org_name'],
              'company_name':
                  (item['bill_to_customername']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['bill_to_customername'],
              'crmid':
                  (item['bill_to_customerid']?.toString().trim().isEmpty ??
                          true)
                      ? '-'
                      : item['bill_to_customerid'],
            });
          }
        }

        setState(() {
          invoices = filteredInvoices;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load invoices. Status Code: ${response.statusCode}';
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

  void _showInvoiceDetails(BuildContext context, Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.85,
            minChildSize: 0.5,
            initialChildSize: 0.7,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const Text(
                    'Invoice Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(thickness: 1.5, color: Colors.grey),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildStyledDetailRow(
                              Icons.receipt_long,
                              'Invoice No:',
                              invoice['invoiceNumber'],
                            ),
                            _buildStyledDetailRow(
                              Icons.calendar_today,
                              'Invoice Date:',
                              invoice['invoice date'],
                            ),
                            _buildStyledDetailRow(
                              Icons.date_range,
                              'Due Date:',
                              invoice['dueDate'],
                            ),
                            _buildStyledDetailRow(
                              Icons.timelapse,
                              'Period:',
                              invoice['period'],
                            ),
                            _buildStyledDetailRow(
                              Icons.attach_money,
                              'currency:',
                              invoice['currency'],
                            ),
                            _buildStyledDetailRow(
                              Icons.money,
                              'Total Amount:',
                              invoice['total amount'],
                            ),
                            _buildStyledDetailRow(
                              Icons.paid,
                              'Amount Paid:',
                              invoice['amount paid'],
                            ),
                            _buildStyledDetailRow(
                              Icons.warning_amber,
                              'Amount Due:',
                              invoice['amount due'],
                            ),
                            _buildStyledDetailRow(
                              Icons.assignment_turned_in,
                              'Status:',
                              invoice['status'],
                            ),
                            _buildStyledDetailRow(
                              Icons.shopping_cart,
                              'Order No:',
                              invoice['order no'],
                            ),
                            _buildStyledDetailRow(
                              Icons.business,
                              'Billing Org:',
                              invoice['billing_org_name'],
                            ),
                            _buildStyledDetailRow(
                              Icons.public,
                              'Billing Country:',
                              countryMap[invoice['billing country']] ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final invoiceId = invoice['invoiceNumber'];
                                String? filePath = await _financialServices
                                    .downloadInvoicePdf(invoiceId);
                                if (filePath != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Invoice downloaded to $filePath',
                                      ),
                                    ),
                                  );
                                  await OpenFile.open(filePath);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to download invoice'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Download',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStyledDetailRow(IconData icon, String label, String value) {
    print(value);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: GlobalColors.mainColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerInvoiceList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        border: Border.all(width: 1.0, color: GlobalColors.borderColor),
      ),
      child: Column(
        children: [
           Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(width: 1.0, color: GlobalColors.borderColor),
                  ),
                  color: Colors.white,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(width: 100, height: 16, color: Colors.white),
                              Container(width: 80, height: 16, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(width: 150, height: 14, color: Colors.white),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(width: 100, height: 14, color: Colors.white),
                              Container(width: 60, height: 14, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // List<Map<String, dynamic>> filteredInvoices = selectedTab == 'All' ? invoices : invoices.where((invoice) {
    //         final status = (invoice['status'] ?? '').toString().toLowerCase();
    //         return status == selectedTab.toLowerCase();
    //       }).toList();
    List<Map<String, dynamic>> filteredInvoices =
        invoices.where((invoice) {
          final status = (invoice['status'] ?? '').toString().toLowerCase();
          final invoiceNumber =
              (invoice['invoiceNumber'] ?? '').toString().toLowerCase();
          final date = (invoice['invoice date'] ?? '').toString().toLowerCase();
          final matchesTab =
              selectedTab == 'All' || status == selectedTab.toLowerCase();
          final matchesSearch =
              _searchText.isEmpty ||
              invoiceNumber.contains(_searchText.toLowerCase()) ||
              date.contains(_searchText.toLowerCase());
          return matchesTab && matchesSearch;
        }).toList();

    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: CommonAppBar(
        title: 'Invoice List',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Credit Notes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreditNotesView(),
                  ),
                );
              } else if (value == 'Payment History') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentHistoryView(),
                  ),
                );
              } else if (value == 'Transactions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsView(),
                  ),
                );
              } else if (value == 'Wallet') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletView()),
                );
              } else if (value == 'Credit Voucher') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreditVoucherScreen(),
                  ),
                );
              } else if (value == 'Unbilled Transactions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UnbilledTransactionsView(),
                  ),
                );
              } else if (value == 'Service Balance') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceBalanceView(),
                  ),
                );
              } else if (value == 'Discount Transactions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiscountTransactionsView(),
                  ),
                );
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            position: PopupMenuPosition.under,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'Credit Notes',
                    child: ListTile(
                      leading: Icon(Icons.credit_card, color: Colors.black),
                      title: Text(
                        'Credit Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Payment History',
                    child: ListTile(
                      leading: Icon(Icons.payments, color: Colors.black),
                      title: Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Transactions',
                    child: ListTile(
                      leading: Icon(Icons.paid, color: Colors.black),
                      title: Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Wallet',
                    child: ListTile(
                      leading: Icon(Icons.wallet, color: Colors.black),
                      title: Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Unbilled Transactions',
                    child: ListTile(
                      leading: Icon(Icons.receipt_long, color: Colors.black),
                      title: Text(
                        'Unbilled Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Credit Voucher',
                    child: ListTile(
                      leading: Icon(Icons.credit_card, color: Colors.black),
                      title: Text(
                        'Credit Voucher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Service Balance',
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet, color: Colors.black),
                      title: Text(
                        'Service Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Discount Transactions',
                    child: ListTile(
                      leading: Icon(Icons.local_offer_outlined, color: Colors.black),
                      title: Text(
                        'Discount Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: isLoading
          ? _buildShimmerInvoiceList()
          : Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: screenWidth,
              decoration: BoxDecoration(
                color: Color(0xFFF4F7FE),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            _isSearching
                                ? TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search invoice number...',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
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
                                )
                                : ToggleButtons(
                                  isSelected:
                                      ['All', 'Open', 'Clear']
                                          .map((tab) => tab == selectedTab)
                                          .toList(),
                                  onPressed: (index) {
                                    setState(() {
                                      selectedTab =
                                          ['All', 'Open', 'Clear'][index];
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  borderColor: GlobalColors.mainColor,
                                  selectedBorderColor: GlobalColors.mainColor,
                                  fillColor: GlobalColors.mainColor,
                                  selectedColor: Colors.white,
                                  children:
                                      ['All', 'Open', 'Clear']
                                          .map(
                                            (tab) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 0,
                                                    horizontal: 20,
                                                  ),
                                              child: Text(
                                                tab,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                      ),
                      const SizedBox(width: 8),
                      if (!_isSearching)
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
                  const SizedBox(height: 16),
                  if (isSelectionMode && selectedInvoices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalColors.mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (context) {
                                return InvoicePaymentDialog(
                                  selectedInvoices: selectedInvoices,
                                  parentContext:
                                      context, // <-- pass parent context
                                );
                              },
                            );
                            if (result == 'success') {
                              fetchInvoicesData();
                            }
                          },
                          child: const Text(
                            'Pay Now',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = filteredInvoices[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,

                          // onTap: () => _showInvoiceDetails(context, invoice),
                          onTap: () {
                            if (isSelectionMode) {
                              final invoiceNo = invoice['invoiceNumber'] ?? '';
                              if (invoiceNo.isEmpty) return;
                              
                              final companyName = invoice['invoice_bill_from_org'] ?? ''; 
                              if (companyName.toString().contains('IN30')) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        surfaceTintColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                                        content: const Text(
                                          'Payment is not allowed for this billing organisations.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            color: Color(0xFF545454),
                                            fontWeight: FontWeight.w400
                                          ),
                                        ),
                                        actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: GlobalColors.mainColor, // Typically dark blue #283e81
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Ok', style: TextStyle(fontSize: 16)),
                                          ),
                                        ],
                                      ),
                                );
                                return;
                              }
                              
                              // Check mismatch with first selected invoice
                              final firstInvoice =
                                  selectedInvoices.isNotEmpty
                                      ? selectedInvoices.first
                                      : null;
                                      
                              if (firstInvoice != null) {
                                if (invoice['invoice_bill_from_org'] != firstInvoice['invoice_bill_from_org']) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                                          content: const Text(
                                            'Billing organisation should be same for all selected invoices to proceed.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              color: Color(0xFF545454),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          actionsAlignment: MainAxisAlignment.center,
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: GlobalColors.mainColor,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Ok', style: TextStyle(fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                  );
                                  return;
                                }
                                
                                if (invoice['currency'] != firstInvoice['currency']) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                                          content: const Text(
                                            'Please select Invoices with same currency.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              color: Color(0xFF545454),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          actionsAlignment: MainAxisAlignment.center,
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: GlobalColors.mainColor,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Ok', style: TextStyle(fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                  );
                                  return;
                                }
                              }
                              setState(() {
                                final existingIndex = selectedInvoices
                                    .indexWhere(
                                      (inv) =>
                                          inv['invoiceNumber'] == invoiceNo,
                                    );
                                if (existingIndex >= 0) {
                                  selectedInvoices.removeAt(existingIndex);
                                } else {
                                  selectedInvoices.add(invoice);
                                }
                                if (selectedInvoices.isEmpty) {
                                  isSelectionMode = false;
                                }
                              });
                            } else {
                              _showInvoiceDetails(context, invoice);
                            }
                          },
                          onLongPress: () {
                            if (isSelectionMode) return;
                            
                            final invoiceNo = invoice['invoiceNumber'] ?? '';
                            final invoiceStatus = invoice['status'] ?? '';
                            if (invoiceStatus != 'OPEN') {
                              return;
                            }
                            if (invoiceNo.isEmpty) return;
                            
                            final companyName = invoice['invoice_bill_from_org'] ?? ''; 
                            if (companyName.toString().contains('IN30')) {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                                      content: const Text(
                                        'Payment is not allowed for this billing organisations.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          color: Color(0xFF545454),
                                          fontWeight: FontWeight.w400
                                        ),
                                      ),
                                      actionsAlignment: MainAxisAlignment.center,
                                      actions: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: GlobalColors.mainColor, // Typically dark blue #283e81
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          ),
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Ok', style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                    ),
                              );
                              return;
                            }
                            
                            setState(() {
                              isSelectionMode = true;
                              selectedInvoices.clear();
                              selectedInvoices.add(invoice);
                            });
                          },
                          child: Card(
                            color:
                                selectedInvoices.any(
                                      (inv) =>
                                          inv['invoiceNumber'] ==
                                          invoice['invoiceNumber'],
                                    )
                                    ? Colors.blue.shade100
                                    : Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            
                            ),
                            borderOnForeground: true,
                            shadowColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Builder(
                                builder: (context) {
                                  double totalAmount = 0.0;
                                  try {
                                    totalAmount = double.parse(
                                      invoice['total amount'].toString(),
                                    );
                                  } catch (e) {
                                    totalAmount = 0.0;
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Left Column: Invoice Number and Date
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invoice['invoiceNumber'] ?? '',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Due Date: ${invoice['dueDate'] ?? ''}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Right Column: Amount and Status Badge
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            totalAmount.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  invoice['status'] == 'CLEAR'
                                                      ? Colors.green
                                                      : Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              invoice['status'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }
}
