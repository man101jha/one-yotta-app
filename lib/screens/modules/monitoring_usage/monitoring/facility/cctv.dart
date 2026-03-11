import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class CctvListView extends StatefulWidget {
  const CctvListView({super.key});

  @override
  State<CctvListView> createState() => _CctvListViewState();
}

class _CctvListViewState extends State<CctvListView> {
  final List<Map<String, String>> infraAlerts = [
    {
      'Order No.': '1141251',
      'Line No.': '2',
      'Location': 'NM1 - Data Center',
      'No. of Camera': '8'
    },
    {
      'Order No.': '1141252',
      'Line No.': '3',
      'Location': 'HQ - Security Room',
      'No. of Camera': '12'
    },
    {
      'Order No.': '1141253',
      'Line No.': '4',
      'Location': 'Warehouse - Main Entrance',
      'No. of Camera': '6'
    },
    {
      'Order No.': '1141254',
      'Line No.': '5',
      'Location': 'Office - Reception',
      'No. of Camera': '10'
    },
  ];

  Map<String, bool> expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'CCTV Plan List'),
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
            bool isExpanded = expandedRows[alert['Order No.']] ?? false;
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
                    title: Text("Order No.: ${alert['Order No.']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("Location: ${alert['Location']}",
                        style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blueAccent),
                      onPressed: () {
                        setState(() {
                          expandedRows[alert['Order No.']!] = !isExpanded;
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
                          _buildDetailRow("Line No.", alert['Line No.']!),
                          _buildDetailRow("No. of Camera", alert['No. of Camera']!),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
        ],
      ),
    );
  }
}
