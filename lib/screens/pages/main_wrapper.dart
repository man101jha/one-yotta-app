import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myaccount/screens/modules/assets/assets_list.dart';
import 'package:myaccount/screens/modules/financials/invoice_list.dart';
import 'package:myaccount/screens/modules/orders/order_list.dart';
import 'package:myaccount/screens/modules/ticket/ticket_list.dart';
import 'package:myaccount/screens/pages/controller/main_wrapper_controller.dart';
import 'package:myaccount/screens/pages/dashboard.view.dart';
import 'package:myaccount/utilities/global.colors.dart';

class HomeScreen extends StatelessWidget {
  final NavigationController navController = Get.put(NavigationController());

  Widget getPage(int index) {
    switch (index) {
      case 0:
        return DashboardView();
      case 1:
        return InvoiceListView();
      case 2:
        return AssetsView(selectedTypeFilter: "All");
      case 3:
        return OrdersView();
      case 4:
        return TicketListView(
          selectedSeverityFilter: 'all',
          selectedStatusFilter: 'all',
        );
      default:
        return DashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: getPage(navController.currentIndex.value),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: GlobalColors.mainColor,
            currentIndex: navController.currentIndex.value,
            onTap: navController.changePage,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Billing',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                label: 'Assets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.support_agent_outlined),
                label: 'Support',
              ),
            ],
          ),
        ));
  }
}
