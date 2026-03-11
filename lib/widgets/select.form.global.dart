import 'package:flutter/material.dart';

class SelectFormGlobal extends StatefulWidget {
  const SelectFormGlobal(
      {Key? key,
      required this.controller,
      required this.text,
      required this.textInputType,
      required this.obscure})
      : super(key: key);
  final TextEditingController controller;
  final String text;
  final TextInputType textInputType;
  final bool obscure;
  @override
  State<SelectFormGlobal> createState() =>
      _SelectFormGlobalState();
}

class _SelectFormGlobalState extends State<SelectFormGlobal> {
  List<String> listItem = [
    'Item 1',
    'item 2',
    'item 3',
    'item 4',
    'item 5',
    'item 6',
    'item 7',
    'item 8',
    'item 9',
    'item 10',
    'item 11',
    'item 12',
    'item 13',
    'item 14',
    'item 15',
    'item 16',
    'item 17',
    'item 18',
    'item 19',
  ];
  String? valueChoose;

  void dropdownCallback(String? selectedValue) {
    if (selectedValue is String) {
      setState(() {
        valueChoose = selectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: widget.text,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.only(left: 15),
          hintStyle: const TextStyle(
            height: 1,
          ),
          floatingLabelStyle:
              WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
            Color color = Colors.black;
            return TextStyle(color: color, letterSpacing: 1.3);
          }),
        ),
        dropdownColor: Colors.grey,
        icon: const Icon(Icons.arrow_drop_down),
        value: valueChoose,
        onChanged: (newValue) {
          if (newValue is String) {
            setState(() {
              valueChoose = newValue;
            });
          }
        },
        items: listItem.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }
}
