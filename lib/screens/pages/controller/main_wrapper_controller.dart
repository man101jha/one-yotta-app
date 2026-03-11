import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myaccount/screens/modules/profile/profile.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/starter_service.dart';

class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    checkKyc();
  }

  void checkKyc() async {
    if (SessionManager().getSessionData() == null || SessionManager().getSessionData()!['acctUUID'] == null) {
      try {
        await ApiClient().getSessionStarter();
      } catch (e) {
        print("Failed to get session starter for KYC check: $e");
      }
    }

    final sessionData = SessionManager().getSessionData();
    if (sessionData == null || sessionData['acctUUID'] == null) {
      return;
    }

    final isKycApproved = await AccountDataService().isKycApproved();
    if (!isKycApproved) {
      Get.offAll(() => const ProfileView());
       Get.snackbar(
        "Action Required",
        "Please complete your KYC to access other features.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}