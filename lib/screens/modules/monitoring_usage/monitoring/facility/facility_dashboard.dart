import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/monitoring_usage/monitoring/facility/access_log.dart';
import 'package:myaccount/screens/modules/monitoring_usage/monitoring/facility/cctv.dart';
import 'package:myaccount/screens/modules/monitoring_usage/monitoring/facility/humidity.dart';
import 'package:myaccount/screens/modules/monitoring_usage/monitoring/facility/ipdu.dart';
import 'package:myaccount/screens/modules/monitoring_usage/monitoring/facility/power.dart';
import 'package:myaccount/screens/modules/monitoring_usage/monitoring/facility/temperature.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class FacilityDashboardView extends StatefulWidget {
  const FacilityDashboardView({super.key});

  @override
  State<FacilityDashboardView> createState() => _FacilityDashboardViewState();
}

class _FacilityDashboardViewState extends State<FacilityDashboardView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Facility Dashboard'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8, // Adjusted to make widgets smaller in height
          children: [
            _buildDashboardItem(Icons.power, 'Power',() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const PowerView()),
                                    );
                                  },),
            _buildDashboardItem(Icons.electrical_services, 'IPDU',() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => IpduView()),
                                    );
                                  },),
            _buildDashboardItem(Icons.thermostat, 'Temperature',() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const TemperatureView()),
                                    );
                                  },),
            _buildDashboardItem(Icons.water_drop, 'Humidity',() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const HumidityView()),
                                    );
                                  },),
            _buildDashboardItem(Icons.lock, 'Access Log',() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const AccessLogView()),
                                    );
                                  },),
            _buildDashboardItem(Icons.videocam, 'CCTV',() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const CctvListView()),
                                    );
                                  },),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildDashboardItem(IconData icon, String title, onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: const Color(0xFF283e81)), // Reduced icon size
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14, // Reduced text size
                fontWeight: FontWeight.w500,
                color: Color(0xFF283e81),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
