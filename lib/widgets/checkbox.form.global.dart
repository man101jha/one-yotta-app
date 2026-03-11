// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class CheckboxFormGlobal extends StatelessWidget {
  const CheckboxFormGlobal({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Row(
        children: <Widget>[
          Checkbox(
            value: value,
            onChanged: (bool? newValue) {
              onChanged(newValue!);
              print(value);
            },
          ),
          Text(label),
        ],
      ),
    );
  }
}
