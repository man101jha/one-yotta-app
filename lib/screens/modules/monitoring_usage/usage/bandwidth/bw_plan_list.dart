import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class BandwidthPlanListView extends StatefulWidget {
  const BandwidthPlanListView({super.key});

  @override
  State<BandwidthPlanListView> createState() => _BandwidthPlanListViewState();
}

class _BandwidthPlanListViewState extends State<BandwidthPlanListView> {
  final List<Map<String, String>> bandwidthPlans = [
    {
      'Order No': '001',
      'Type': 'Fiber',
      'Subscribed': 'Yes',
      'Location': 'New York'
    },
    {
      'Order No': '002',
      'Type': 'DSL',
      'Subscribed': 'No',
      'Location': 'Los Angeles'
    },
    {
      'Order No': '003',
      'Type': 'Satellite',
      'Subscribed': 'Yes',
      'Location': 'Chicago'
    },
    {
      'Order No': '004',
      'Type': 'Cable',
      'Subscribed': 'No',
      'Location': 'Houston'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Subscribe Bandwidth Plans'),
      body: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: ListView.builder(
          itemCount: bandwidthPlans.length,
          itemBuilder: (context, index) {
            final plan = bandwidthPlans[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                color: Colors.white,
              ),
              child: ListTile(
                title: Text("Order No: ${plan['Order No']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Type", plan['Type']!),
                    _buildDetailRow("Subscribed", plan['Subscribed']!),
                    _buildDetailRow("Location", plan['Location']!),
                  ],
                ),
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
