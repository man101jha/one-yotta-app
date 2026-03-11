import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions; // Added actions parameter

  const CommonAppBar({Key? key, required this.title, this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: GlobalColors.mainColor,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
        
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: GlobalColors.mainColor),
      actions: actions, // Use actions if provided
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
