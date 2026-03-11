import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class InvoiceView extends StatefulWidget {
  const InvoiceView({super.key});

  @override
  State<InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<InvoiceView> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = AppBar().preferredSize.height;
    double containerHeight = screenHeight - appBarHeight;
    String _searchText = '';
    final TextEditingController _searchController = TextEditingController();
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      
      appBar: const CommonAppBar(title: 'Invoice List'),
      body: Container(
        padding: const EdgeInsets.all(16),
        width: screenWidth,
        height: containerHeight, // Set height to fill the remaining space
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FE),
          // borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: const SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(0),
              child: Text(
                'Invoice Page Content Goes Here',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF283e81),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }
}
