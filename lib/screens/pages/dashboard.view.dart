import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myaccount/screens/modules/orders/order_list.dart';
import 'package:myaccount/screens/modules/profile/address.dart';
import 'package:myaccount/screens/modules/profile/contact.dart';
import 'package:myaccount/screens/modules/profile/profile.dart';
import 'package:myaccount/screens/modules/financials/wallet.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/accounts_service.dart';
import 'package:myaccount/services/app_services/asset_service/asset_service.dart';
import 'package:myaccount/services/app_services/finance_service/invoice_service.dart';
import 'package:myaccount/services/app_services/order_service/order_service.dart';
import 'package:myaccount/services/app_services/starter_service.dart';
import 'package:myaccount/services/app_services/finance_service/service_balance_service.dart';
import 'package:myaccount/screens/modules/financials/service_balance.dart';
import 'package:myaccount/services/app_services/ticket_service/ticket_list_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myaccount/widgets/invoice_summary_card.dart';
import 'package:myaccount/widgets/order_summary_card.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ticket_summary_card.dart';
import '../../widgets/assets_summary_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ApiClient _apiClient = ApiClient();
  final AccountDataService _accountDataClient = AccountDataService();
  final AccountsService _accountClient = AccountsService();
  final TicketListService _ticketDataClient = TicketListService();
  final AssetService _assetDataClient = AssetService();
  final OrderService _orderDataClient = OrderService();
  final InvoiceService _invoiceDataClient = InvoiceService();
  final ServiceBalanceService _serviceBalanceClient = ServiceBalanceService();

  Map<String, dynamic>? sessionData;
  String? serviceBalance;
  bool isLoading = true;
  bool isTicketLoading = true;
  bool isAssetLoading = true;
  bool isOrderLoading = true;
  bool isInvoiceLoading = true;

  Map<String, int> severity = {};
  List<Map<String, dynamic>> ticketNameCount = [];
  int totalTickets = 0;

  int totalAssets = 0;
  Map<String, double> assetDistribution = {};

  int totalOrders = 0;
  Map<String, double> orderDistribution = {};

  double invoiceAmount = 0;
  Map<String, double> invoiceDistribution = {};

  @override
  void initState() {
    super.initState();
    fetchSessionStarter();
  }

  Future<void> fetchSessionStarter() async {
    try {
      final response = await _apiClient.getSessionStarter();
      if (response.statusCode == 200) {
        setState(() {
          sessionData = jsonDecode(response.body);
          isLoading = false;
        });
        await fetchAccountData();
        await fetchAssetData();
        await fetchOrderData();
        await fetchInvoiceData();
        await fetchServiceBalance();
        await projectList();
        await categorySubcategory();
        await categorySubcategoryServRequest();
        await fetchAccount();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAccountData() async {
    try {
      final response = await _accountDataClient.getAccountData();
      if (response.statusCode == 200) {
        await fetchTicketData();
      }
    } catch (_) {}
  }

  Future<void> fetchTicketData() async {
    setState(() => isTicketLoading = true);
    try {
      final response = await _ticketDataClient.getTicketData();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        parseTicketData(data);
      } else {
        setState(() => isTicketLoading = false);
      }
    } catch (e) {
      setState(() => isTicketLoading = false);
    }
  }

  void parseTicketData(Map<String, dynamic> json) {
    final Map<String, int> severityMap = {};
    final Map<String, dynamic> severityRaw =
        json['ticketSeverityWiseInfo'] ?? {};
    severityRaw.forEach((key, value) {
      severityMap[key.toLowerCase()] = int.tryParse(value.toString()) ?? 0;
    });

    final List<Map<String, dynamic>> statusList = [];
    final Map<String, dynamic> statusRaw = json['ticketStateWiseInfo'] ?? {};
    statusRaw.forEach((key, value) {
      statusList.add({
        'title': key,
        'value': int.tryParse(value.toString()) ?? 0,
      });
    });

    final int total = statusList.fold(0, (sum, e) => sum + (e['value'] as int));

    setState(() {
      severity = severityMap;
      ticketNameCount = statusList;
      totalTickets = total;
      isTicketLoading = false;
    });
  }

  Future<void> fetchAssetData() async {
    setState(() => isAssetLoading = true);
    try {
      final response = await _assetDataClient.getAssetData();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final int count = int.tryParse(data['totalCount']) ?? 0;
        final Map<String, dynamic> rawDetails = data['assetTypeDetails'] ?? {};

        final Map<String, double> distribution = {};
        rawDetails.forEach((key, value) {
          if (value is num) {
            distribution[key] = value.toDouble();
          } else {
            distribution[key] = double.tryParse(value.toString()) ?? 0.0;
          }
        });

        setState(() {
          totalAssets = count;
          assetDistribution = distribution;
          isAssetLoading = false;
        });
      } else {
        setState(() => isAssetLoading = false);
      }
    } catch (e) {
      setState(() => isAssetLoading = false);
    }
  }

  Future<void> fetchOrderData() async {
    setState(() => isOrderLoading = true);
    try {
      final response = await _orderDataClient.getOrdersHeadDetails();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final int count = data['clubTotalCount']['All Services'] ?? 0;
        final Map<String, dynamic> rawDetails = data['clubTotalCount'] ?? {};

        final Map<String, double> distribution = {};
        rawDetails.forEach((key, value) {
          if (value is num) {
            distribution[key] = value.toDouble();
          } else {
            distribution[key] = double.tryParse(value.toString()) ?? 0.0;
          }
        });

        setState(() {
          totalOrders = count;
          orderDistribution = distribution;
          isOrderLoading = false;
        });
      } else {
        setState(() => isOrderLoading = false);
      }
    } catch (e) {
      setState(() => isOrderLoading = false);
    }
  }

  Future<void> fetchInvoiceData() async {
    setState(() => isInvoiceLoading = true);
    int greaterSixty = 0;
    int lessSixty = 0;
    int lessThirty = 0;
    try {
      final response = await _invoiceDataClient.getInvoiceData();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> items = data['Response'] ?? [];
        double outstandingBalance = 0.0;
        final DateTime today = DateTime.now();
        final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
        for (var item in items) {
          final status = item['invoice_status']?.toString().toLowerCase();
          final amountDue =
              double.tryParse(item['invoice_amount_due'].toString()) ?? 0.0;

          if (status == 'open') {
            outstandingBalance += amountDue;
          } else if (status == 'clear') {
            outstandingBalance -= amountDue;
          }

          if (status == 'open') {
            final invoiceDateStr = item['invoice_date']?.toString().trim();
            if (invoiceDateStr == null || invoiceDateStr.isEmpty) continue;
            DateTime? invoiceDate;
            try {
              invoiceDate = dateFormat.parseStrict(invoiceDateStr);
            } catch (e) {
              continue;
            }
            final difference = today.difference(invoiceDate).inDays;
            if (difference > 60) {
              greaterSixty++;
            } else if (difference > 30) {
              lessSixty++;
            } else {
              lessThirty++;
            }
          }
        }

        setState(() {
          invoiceAmount = outstandingBalance;
          invoiceDistribution = {
            '>60': greaterSixty.toDouble(),
            '<60': lessSixty.toDouble(),
            '<30': lessThirty.toDouble(),
          };
          isInvoiceLoading = false;
        });
      } else {
        setState(() => isInvoiceLoading = false);
      }
    } catch (e) {
      setState(() => isInvoiceLoading = false);
    }
  }

  Future<void> projectList() async {
    setState(() => isTicketLoading = true);
    try {
      final response = await _ticketDataClient.getProjectList();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() => isTicketLoading = false);
      } else {
        setState(() => isTicketLoading = false);
      }
    } catch (e) {
      setState(() => isTicketLoading = false);
    }
  }

  Future<void> categorySubcategory() async {
    setState(() => isTicketLoading = true);
    try {
      final response = await _ticketDataClient.getDomainCategorySubCategory();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() => isTicketLoading = false);
      } else {
        setState(() => isTicketLoading = false);
      }
    } catch (e) {
      setState(() => isTicketLoading = false);
    }
  }

  Future<void> categorySubcategoryServRequest() async {
    setState(() => isTicketLoading = true);
    try {
      final response =
          await _ticketDataClient.getDomainCategorySubCategoryServRequest();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() => isTicketLoading = false);
      } else {
        setState(() => isTicketLoading = false);
      }
    } catch (e) {
      setState(() => isTicketLoading = false);
    }
  }

  Future<void> fetchAccount() async {
    try {
      final response = await _accountClient.getAccountsData();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
      }
    } catch (_) {}
  }

  Future<void> fetchServiceBalance() async {
    try {
      final response = await _serviceBalanceClient.getServiceBalance();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          serviceBalance = data['service_balance'];
        });
      }
    } catch (_) {}
  }

  String _formatCurrency(String? value) {
    if (value == null) return '0.00';
    final double amount = double.tryParse(value) ?? 0.00;
    final format = NumberFormat("#,##0.00", "en_US");
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: GlobalColors.borderColor,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  Row(
                    children: [
                      InkWell(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ServiceBalanceView(),
                              ),
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: GlobalColors.mainColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: serviceBalance == null
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: 80,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Text(
                                      '\u20B9',
                                      style: TextStyle(
                                        color: GlobalColors.mainColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatCurrency(serviceBalance),
                                      style: TextStyle(
                                        color: GlobalColors.mainColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      InkWell(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileView(),
                              ),
                            ),
                        child: Icon(
                          Icons.account_circle_outlined,
                          color: GlobalColors.mainColor,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 5),

                      /// Popup Menu (3 dots)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Contacts') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ContactView(),
                              ),
                            );
                          } else if (value == 'Address') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddressView(),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: GlobalColors.mainColor,
                          size: 25,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1),
                        ),
                        position: PopupMenuPosition.under,
                        itemBuilder:
                            (context) => const [
                              PopupMenuItem<String>(
                                value: 'Contacts',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.contact_emergency_outlined,
                                    color: Colors.black,
                                  ),
                                  title: Text(
                                    'Contacts',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Address',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.pin_drop_outlined,
                                    color: Colors.black,
                                  ),
                                  title: Text(
                                    'Address',
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
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: OrderSummaryCard(
                        isLoading: isOrderLoading,
                        totalOrders: totalOrders,
                        orderDistribution: orderDistribution,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: InvoiceSummaryCard(
                        isLoading: isInvoiceLoading,
                        totalOutstanding: invoiceAmount,
                        invoiceDistribution: invoiceDistribution,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TicketSummaryCard(
                        isLoading: isTicketLoading,
                        severity: severity,
                        statusList: ticketNameCount,
                        totalTickets: totalTickets,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: AssetsSummaryCard(
                        isLoading: isAssetLoading,
                        totalAssets: totalAssets,
                        assetDistribution: assetDistribution,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
