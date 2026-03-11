// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class ContactFormGlobal extends StatelessWidget {
  const ContactFormGlobal({
    Key? key,
    required this.controller,
    required this.text,
    required this.textInputType,
    required this.obscure,
    this.onChanged, // ✅ Add onChanged as optional parameter
  }) : super(key: key);

  final TextEditingController controller;
  final String text;
  final TextInputType textInputType;
  final bool obscure;
  final Function(String)? onChanged; // ✅ Declare onChanged callback

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntlPhoneField(
        controller: controller,
        decoration: InputDecoration(
          labelText: text,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.only(left: 15),
          hintStyle: const TextStyle(height: 1),
          floatingLabelStyle:
              WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
            return const TextStyle(color: Colors.black, letterSpacing: 1.3);
          }),
        ),
        initialCountryCode: 'IN',
        onChanged: (phone) {
          if (onChanged != null) {
            onChanged!(phone.completeNumber); 
          }
        },
      ),
    );
  }
}
