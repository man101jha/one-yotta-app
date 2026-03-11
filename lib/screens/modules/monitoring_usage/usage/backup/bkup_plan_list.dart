import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class BackupPlanListView extends StatefulWidget {
  const BackupPlanListView({super.key});

  @override
  State<BackupPlanListView> createState() => _BackupPlanListViewState();
}

class _BackupPlanListViewState extends State<BackupPlanListView> {
  final List<Map<String, String>> backupPlans = [
    {
      'Order No': '001',
      'Plan Name': 'Premium Backup',
      'Plan Type': 'Cloud',
      'Subscribed Quota': '500GB',
      'Overage': '10GB',
      'Location': 'New York'
    },
    {
      'Order No': '002',
      'Plan Name': 'Standard Backup',
      'Plan Type': 'On-Prem',
      'Subscribed Quota': '1TB',
      'Overage': '50GB',
      'Location': 'Los Angeles'
    },
    {
      'Order No': '003',
      'Plan Name': 'Enterprise Backup',
      'Plan Type': 'Hybrid',
      'Subscribed Quota': '2TB',
      'Overage': '100GB',
      'Location': 'Chicago'
    },
    {
      'Order No': '004',
      'Plan Name': 'Basic Backup',
      'Plan Type': 'Cloud',
      'Subscribed Quota': '200GB',
      'Overage': '5GB',
      'Location': 'Houston'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Subscribe Backup Plans'),
      body: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: ListView.builder(
          itemCount: backupPlans.length,
          itemBuilder: (context, index) {
            final plan = backupPlans[index];
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
                    _buildDetailRow("Plan Name", plan['Plan Name']!),
                    _buildDetailRow("Plan Type", plan['Plan Type']!),
                    _buildDetailRow("Subscribed Quota", plan['Subscribed Quota']!),
                    _buildDetailRow("Overage", plan['Overage']!),
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