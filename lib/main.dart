import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import 'package:myaccount/screens/view/login.view.dart';
import 'package:myaccount/screens/pages/main_wrapper.dart';
import 'package:myaccount/screens/view/splash.view.dart';
import 'navigation/route_observer.dart';

// ✅ Define global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp( App());
}

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      navigatorObservers: [routeObserver],
      getPages: [
        GetPage(name: '/splash', page: () => const SplashView()),
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/home', page: () => HomeScreen()),
      ],
    );
  }
}
