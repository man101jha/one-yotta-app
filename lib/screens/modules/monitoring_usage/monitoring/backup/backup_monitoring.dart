import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class BackupDashboardView extends StatefulWidget {
  const BackupDashboardView({super.key});

  @override
  State<BackupDashboardView> createState() => _BackupDashboardViewState();
}

class _BackupDashboardViewState extends State<BackupDashboardView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Backup Dashboard'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Column(
          children: [
            _buildJobsCard(),
            const SizedBox(height: 16),
            _buildEnvironmentCard(),
            const SizedBox(height: 16),
            _buildPolicyCard(),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildJobsCard() {
    return _buildCard(
      title: 'Jobs (Last 24 Hours)',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusColumn('Completed', '3', Colors.green),
          _buildStatusColumn('Failed', '1', Colors.red),
          _buildStatusColumn('Running', '2', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    return _buildCard(
      title: 'Environment',
      content: Column(
        children: [
          _buildEnvironmentRow('File Servers', '10'),
          _buildEnvironmentRow('VMs', '25'),
          _buildEnvironmentRow('DB Instances', '5'),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return _buildCard(
      title: 'Policy',
      content: Text(
        '5',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF283e81)),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF283e81),
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildStatusColumn(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEnvironmentRow(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            count,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF283e81)),
          ),
        ],
      ),
    );
  }
}