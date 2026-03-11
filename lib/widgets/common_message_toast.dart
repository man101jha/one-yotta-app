import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class CommonMessageToast {
  static void showMessage(BuildContext context, QuickAlertType alertType, String message, String closeButtonText) {
    QuickAlert.show(
      context: context,
      type: alertType,
      text: message,
      confirmBtnText: closeButtonText,
      showConfirmBtn: false,
    );
  }
}
