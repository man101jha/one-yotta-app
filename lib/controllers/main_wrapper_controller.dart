import 'package:get/get.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';

class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;

    // If Billing tab is selected → fetch invoices again
    if (index == 1) {
      FinancialServices().getInvoicesData();
    }

    // If Assets tab selected → refresh assets
    if (index == 2) {
      // FinancialServices().getAssetsData();  // if you want analogous refresh
    }

    // If Services tab selected → refresh orders
    if (index == 3) {
      // FinancialServices().getOrdersData();
    }

    // If Support tab selected → refresh tickets
    if (index == 4) {
      // FinancialServices().getTicketsData();
    }
  }
}
