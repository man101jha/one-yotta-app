// Make sure to import this at the top
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/assets/assets_list.dart';
import 'package:myaccount/screens/modules/financials/invoice_list.dart';
import 'package:myaccount/screens/modules/orders/order_list.dart';
import 'package:myaccount/screens/modules/profile/address.dart';
import 'package:myaccount/screens/modules/profile/contact.dart';
import 'package:myaccount/screens/modules/profile/profile.dart';
import 'package:myaccount/screens/modules/financials/wallet.dart';
import 'package:myaccount/screens/modules/ticket/new_ticket.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/starter_service.dart';
import 'package:myaccount/services/app_services/ticket_service/ticket_list_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import '../../widgets/bottom_navigation.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}


class _DashboardViewState extends State<DashboardView> {
  final ApiClient _apiClient = ApiClient();
  final AccountDataService _accountDataClient = AccountDataService();
  final TicketListService _ticketDataClient = TicketListService();
  Map<String, dynamic>? sessionData;
  bool isLoading = true;
  Map<String, dynamic> ticketsDataCount = {
  "status": {},
  "severity": {},
};

List<Map<String, dynamic>> ticketNameCount = [];

  @override
  void initState() {
    super.initState();
    print('DashboardView: initState()');
    fetchSessionStarter();
  }

  Future<void> fetchSessionStarter() async {
    try {
      final response = await _apiClient.getSessionStarter();

      if (response.statusCode == 200) {
        setState(() {
          sessionData = jsonDecode(response.body);

          isLoading = false;
          fetchAccountData();
        });
      } else {
        print('API error: ${response.statusCode}');
        print('Response: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }
  Future<void> fetchAccountData() async {
    try {
      final response = await _accountDataClient.getAccountData();
      if (response.statusCode == 200) {
        // setState(() {
        //   sessionData = jsonDecode(response.body);
        // });
          isLoading = false;
          fetchTicketData();
      } else {
        print('API error: ${response.statusCode}');
        print('Response: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }
  Future<void> fetchTicketData() async {
    try {
      print('Fetching Ticket details');
      final response = await _ticketDataClient.getTicketData();
      if (response.statusCode == 200) {
        // setState(() {
        //   sessionData = jsonDecode(response.body);
        // });
          isLoading = false;
      } else {
        print('API error: ${response.statusCode}');
        print('Response: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: <Widget>[
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
                      Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WalletView()),
                              );
                            },
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: GlobalColors.mainColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileView()),
                              );
                            },
                            child: Icon(
                              Icons.account_circle_outlined,
                              color: GlobalColors.mainColor,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F7FE),
                  ),
                  child: Column(
                    children: [
                      _buildTicketCard(),
                      const SizedBox(height: 16),
                      Row(children: [
                        Text(
                          const JsonEncoder.withIndent('  ').convert(sessionData),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF283e81),
                          ),
                        ),
                      ],),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildDashboardCard(
                                  icon: Icons.monetization_on_outlined,
                                  title: 'Outstanding',
                                  value: '\$174,437',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const InvoiceListView()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDashboardCard(
                                  icon: Icons.inventory_outlined,
                                  title: 'Assets',
                                  value: '178',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AssetsView()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildDashboardCard(
                                  icon: Icons.miscellaneous_services_outlined,
                                  title: 'Services',
                                  value: '15',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const OrdersView()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReportsCard(
                        icon: Icons.contact_emergency_outlined,
                        title: 'Contact',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ContactView()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildReportsCard(
                        icon: Icons.pin_drop_outlined,
                        title: 'Address',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddressView()),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(),
    );
  }
void parseTicketData(Map<String, dynamic> data) {
  // Ticket Status Info
  if (data['ticketStateWiseInfo'] != null) {
    Map<String, dynamic> tickStatus = {};
    data['ticketStateWiseInfo'].forEach((key, value) {
      tickStatus[key.toLowerCase()] = value;
    });
    tickStatus['workInProgress'] = tickStatus['work in progress'];
    tickStatus.remove('work in progress');
    ticketsDataCount['status'] = tickStatus;

    // Also build name count list
    ticketNameCount = [];
    data['ticketStateWiseInfo'].forEach((key, value) {
      ticketNameCount.add({
        'title': key,
        'value': value,
        'url': key.replaceAll(' ', '-'),
        'icon': key.toLowerCase().replaceAll(' ', '-'),
      });
    });
    ticketNameCount.sort((a, b) => a['title'].compareTo(b['title']));
  }

  // Ticket Severity Info
  if (data['ticketSeverityWiseInfo'] != null) {
    Map<String, int> tickSeverity = {
      's1': 0,
      's2': 0,
      's3': 0,
      's4': 0,
    };
    data['ticketSeverityWiseInfo'].forEach((key, value) {
      tickSeverity[key.toLowerCase()] = value;
    });
    ticketsDataCount['severity'] = tickSeverity;
  }
}

  Widget _buildTicketCard() {
  final severity = ticketsDataCount['severity'] ?? {};
  final statusList = ticketNameCount;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(width: 1.0, color: GlobalColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tickets',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF283e81),
              ),
            ),
            Text(
              // Total tickets count
              statusList.fold<int>(0, (sum, item) => sum + (item['value'] as int? ?? 0)).toString(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GlobalColors.secondaryColor,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTicketView()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlobalColors.secondaryColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_outlined, color: GlobalColors.secondaryColor, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      'New',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: GlobalColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),

        const SizedBox(height: 16),

        // Priorities row (severity)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PriorityItem(label: 'Critical', count: severity['s1'] ?? 0),
              _PriorityItem(label: 'High', count: severity['s2'] ?? 0),
              _PriorityItem(label: 'Moderate', count: severity['s3'] ?? 0),
              _PriorityItem(label: 'Low', count: severity['s4'] ?? 0),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status list
        ...statusList.map((status) => _StatusItem(
              label: status['title'],
              count: status['value'],
            )),
      ],
    ),
  );
}

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: GlobalColors.secondaryColor),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF283e81),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GlobalColors.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF283e81),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF283e81),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Priority Row Item
class _PriorityItem extends StatelessWidget {
  final String label;
  final int count;

  const _PriorityItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// Reusable Status Column Item
class _StatusItem extends StatelessWidget {
  final String label;
  final int count;

  const _StatusItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
