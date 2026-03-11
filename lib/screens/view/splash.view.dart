import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myaccount/screens/pages/dashboard.view.dart';
import 'package:myaccount/screens/pages/main_wrapper.dart';
import 'package:myaccount/screens/view/login.view.dart';
import 'package:myaccount/screens/view/onboarding.view.dart';
import 'package:myaccount/services/app_services/onboard_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/services/auth_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AuthService _authService = AuthService();
  final OnboardService _onboardService = OnboardService();

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    bool loggedIn = await _authService.isLoggedIn();

    Timer(const Duration(seconds: 1), () async {
      if (loggedIn) {
        // Get.off(() => HomeScreen());
        try {
          final response = await _onboardService.getOnboardingData();
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['accountStatus'] == "NonActive") {
              Get.off(() => const OnboardingView());
            } else {
              Get.off(() => HomeScreen());
            }
          } else {
            // If onboarding API fails, fallback to dashboard or login
            Get.off(() => LoginView());
          }
        } catch (e) {
          // On error, fallback to dashboard or login
          Get.off(() => LoginView());
        }
      } else {
        Get.off(() => LoginView());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      body: Center(child: Image.asset('assets/images/oneYotta.png')),
    );
  }
}
