import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      key: _bottomNavigationKey,
      index: 0,
      height: 55.0,
      items: const <Widget>[
        Icon(Icons.dashboard_outlined, size: 30, color: Colors.white),
        Icon(Icons.receipt_long, size: 30, color: Colors.white),
        Icon(Icons.dns, size: 30, color: Colors.white),
        Icon(Icons.call_split, size: 30, color: Colors.white),
        Icon(Icons.perm_identity, size: 30, color: Colors.white),
      ],
      color: GlobalColors.mainColor,
      buttonBackgroundColor: GlobalColors.mainColor,
      // backgroundColor: Colors.transparent,
      backgroundColor: GlobalColors.backgroundColor,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 200),
      onTap: (index) {
        setState(() {
          _page = index;
        });
      },
      letIndexChange: (index) => true,
    );
  }
}
