import 'package:flutter/material.dart';

class TextFormGlobal extends StatelessWidget {
  const TextFormGlobal({
    Key? key,
    required this.controller,
    required this.text,
    required this.textInputType,
    required this.obscure,
    this.suffixIcon,
    this.validator,
    this.focusNode,

  }) : super(key: key);

  final TextEditingController controller;
  final String text;
  final TextInputType textInputType;
  final bool obscure;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: textInputType,
      obscureText: obscure,
      validator: validator,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: text,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        hintStyle: const TextStyle(height: 1),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners ✅
          borderSide: const BorderSide(color: Colors.white),
        ),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners ✅
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners ✅
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1,
          ),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((
          Set<WidgetState> states,
        ) {
          return const TextStyle(color: Colors.black, letterSpacing: 1.3);
        }),
      ),
      onSaved: (String? newValue) {
        print(newValue);
      },
    );
  }
}
