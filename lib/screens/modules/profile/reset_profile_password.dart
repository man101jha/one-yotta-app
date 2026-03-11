import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import '../../widgets/bottom_navigation.dart';

class ResetProfilePasswordView extends StatefulWidget {
  const ResetProfilePasswordView({super.key});

  @override
  State<ResetProfilePasswordView> createState() => _ResetProfilePasswordViewState();
}

class _ResetProfilePasswordViewState extends State<ResetProfilePasswordView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE), // Set background color to light grey
      appBar: AppBar(
        title: const Text(
          'Reset Profile Password',
          style: TextStyle(
            fontFamily: 'Poppins', // Set font family to Poppins
            color: Color(0xFF283e81),
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF283e81)),
      ),
      body: const Center(
        child: Text(
          'ResetProfilePassword Page Content Goes Here',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF283e81),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }
}
