import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';

class ButtonGlobal extends StatelessWidget {
  final String buttonText;
  final VoidCallback? onTap; // <-- Add this line

  const ButtonGlobal({
    Key? key,
    required this.buttonText,
    this.onTap, // <-- Accept the parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // <-- Use the passed callback here
      child: Container(
        alignment: Alignment.center,
        height: 55,
        decoration: BoxDecoration(
          color: GlobalColors.mainColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
