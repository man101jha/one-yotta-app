import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 16),
            // SizedBox(height: screenHeight* 0.3, child: child),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
