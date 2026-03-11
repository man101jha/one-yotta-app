import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class InfraAlertsView extends StatefulWidget {
  const InfraAlertsView({super.key});

  @override
  State<InfraAlertsView> createState() => _InfraAlertsViewState();
}

class _InfraAlertsViewState extends State<InfraAlertsView> {
  final List<Map<String, String>> infraAlerts = [
    {
      'IP': '10.0.3.17',
      'Host Name': 'NM1BMSVM2',
      'CPU': '0.65%',
      'Memory': '23.34%',
      'Infra Type': 'Server-Windows',
      'Ping': 'Up',
      'Uptime': '83 days, 13:53:38'
    },
    {
      'IP': '10.59.2.15',
      'Host Name': 'VIO1_7836E41(IBM_VIO_CLOUD_VM)',
      'CPU': '1.51%',
      'Memory': '29.18%',
      'Infra Type': 'Server-Linux-IBM-VIO',
      'Ping': 'Up',
      'Uptime': '408 days, 1:22:8'
    },
    {
      'IP': '172.16.1.6',
      'Host Name': 'NM1P3HUBCLLANAC01(Client-LAN-SW)',
      'CPU': '5.00%',
      'Memory': '0.00%',
      'Infra Type': 'Network-Switches',
      'Ping': 'Up',
      'Uptime': '62 days, 0:52:42'
    },
    {
      'IP': '10.0.82.28',
      'Host Name': 'intranetapp',
      'CPU': '17.00%',
      'Memory': '0.00%',
      'Infra Type': 'Network-Firewall-LB',
      'Ping': 'Up',
      'Uptime': '160 days, 7:49:6'
    },
  ];

  Map<String, bool> expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Infra Alerts List'),
      body: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: ListView.builder(
          itemCount: infraAlerts.length,
          itemBuilder: (context, index) {
            final alert = infraAlerts[index];
            bool isExpanded = expandedRows[alert['IP']] ?? false;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(alert['Host Name']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("IP: ${alert['IP']!}",
                        style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blueAccent),
                      onPressed: () {
                        setState(() {
                          expandedRows[alert['IP']!] = !isExpanded;
                        });
                      },
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow("CPU", alert['CPU']!),
                          _buildDetailRow("Memory", alert['Memory']!),
                          _buildDetailRow("Infra Type", alert['Infra Type']!),
                          Row(
                            children: [
                              Text("Ping: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Icon(
                                alert['Ping'] == 'Up'
                                    ? Icons.circle
                                    : Icons.warning,
                                color: alert['Ping'] == 'Up'
                                    ? Colors.green
                                    : Colors.red,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(alert['Ping']!,
                                  style: TextStyle(
                                    color: alert['Ping'] == 'Up'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                          _buildDetailRow("Uptime", alert['Uptime']!),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label + ":",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
        ],
      ),
    );
  }
}
