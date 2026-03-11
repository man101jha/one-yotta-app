import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class EscalationMatrixView extends StatefulWidget {
  const EscalationMatrixView({super.key});

  @override
  State<EscalationMatrixView> createState() => _EscalationMatrixViewState();
}

class _EscalationMatrixViewState extends State<EscalationMatrixView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Escalation Matrix'),
      body: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Container(),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }
}