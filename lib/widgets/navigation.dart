import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/financials/invoice_list.dart';
import 'package:myaccount/screens/pages/dashboard.view.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class BtmNavigationBar extends StatelessWidget {
  const BtmNavigationBar({super.key});

  List<PersistentTabConfig> _tabs() => [
        PersistentTabConfig(
          screen: const SizedBox.shrink(),
          item: ItemConfig(
            activeForegroundColor: Colors.white,
            inactiveBackgroundColor: Colors.white,
            icon: const Icon(Icons.home),
            title: "Home",
          ),
        ),
        PersistentTabConfig(
          screen: const SizedBox.shrink(),
          item: ItemConfig(
            icon: const Icon(Icons.message),
            title: "Messages",
          ),
        ),
        PersistentTabConfig(
          screen: const SizedBox.shrink(), // Shows nothing
          item: ItemConfig(
            icon: const Icon(Icons.settings),
            title: "Settings",
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      backgroundColor: Colors.transparent,
      tabs: _tabs(),
      navBarBuilder: (navBarConfig) => Style1BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(color: Colors.transparent),
      ),
      navBarOverlap: NavBarOverlap.custom(),
    );
  }
}
