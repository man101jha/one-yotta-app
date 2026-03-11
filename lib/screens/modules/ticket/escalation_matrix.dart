import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class EscalationMatrixView extends StatefulWidget {
  const EscalationMatrixView({super.key});

  @override
  State<EscalationMatrixView> createState() => _EscalationMatrixViewState();
}

class _EscalationMatrixViewState extends State<EscalationMatrixView> {
  TableRow _headerRow(List<String> headers) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF283E81)),
      children: headers
          .map((h) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  h,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ))
          .toList(),
    );
  }

  TableRow _dataRow(List<String> data) {
    return TableRow(
      children: data
          .map((d) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(d, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
    );
  }

  Widget _section(String title, List<String> headers, List<List<String>> rows) {
    return Card(
      margin: const EdgeInsets.only(bottom: 25),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            // Table
            Table(
              border: TableBorder.all(
                color: GlobalColors.borderColor,
                width: 1,
              ),
              columnWidths: {
                for (int i = 0; i < headers.length; i++)
                  i: const FlexColumnWidth(),
              },
              children: [
                _headerRow(headers),
                for (var r in rows) _dataRow(r),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Escalation Matrix'),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// -----------------------------------------
            /// For General Operations Concerns
            /// -----------------------------------------
            _section(
              "For General Operations Concerns",
              [
                "1st Level",
                "2nd Level",
                "3rd Level",
                "4th Level",
                "5th Level",
              ],
              [
                [
                  "Service Desk",
                  "Shift Lead",
                  "Lead Service Assurance & Customer Happiness",
                  "Head Service Assurance",
                  "Head Of Operations"
                ],
                [
                  "24×7 On Floor",
                  "24×7 On Floor",
                  "24×7 On Call",
                  "24×7 On Call",
                  "24×7 On Call"
                ],
                [
                  "Help Desk Engineer",
                  "Shift In-charge",
                  "Ms. Chetna Bhatnagar",
                  "Mr. Atul Revankar",
                  "Mr. Rajesh Garg"
                ],
                [
                  "18002096882",
                  "+91-9321701819",
                  "+91-9320006631",
                  "+91-8451847845",
                  "+91-9560637781",
                ],
                [
                  "helpdesk@yotta.com",
                  "ops.shiftincharge@yotta.com",
                  "cbhatnagar@yotta.com",
                  "headserviceassurance@yotta.com",
                  "headoperations@yotta.com"
                ],
              ],
            ),

            /// -----------------------------------------
            /// Material IN/OUT Movement
            /// -----------------------------------------
            _section(
              "For concerns related to Material IN/OUT Movement",
              ["1st Level", "2nd Level", "3rd Level"],
              [
                ["Stores Team", "Service Desk", "Shift Lead"],
                ["18×7 On Floor", "24×7 On Floor", "24×7 On Floor"],
                ["Store Assistant", "Help Desk Engineer", "Shift In-charge"],
                ["+91-2192-400000", "18002096882", "+91-9321701819"],
                [
                  "stores@yotta.com",
                  "helpdesk@yotta.com",
                  "ops.shiftincharge@yotta.com"
                ],
              ],
            ),

            /// -----------------------------------------
            /// Billing
            /// -----------------------------------------
            _section(
              "For concerns related to Billing",
              ["1st Level", "2nd Level"],
              [
                ["Billing Team", "Service Desk"],
                ["Mon-Fri 9AM – 6:30PM", "24×7 On Floor"],
                ["Billing Team", "Help Desk Engineer"],
                ["022-68689000", "18002096882"],
                ["billing@yotta.com", "helpdesk@yotta.com"],
              ],
            ),

            /// -----------------------------------------
            /// DC Access Panvel-NM1
            /// -----------------------------------------
            _section(
              "For DC Access Panvel-NM1",
              ["1st Level", "2nd Level", "3rd Level"],
              [
                ["Security Team", "Service Desk", "Shift Lead"],
                ["18×7 On Floor", "24×7 On Floor", "24×7 On Floor"],
                ["Security Assistant", "Help Desk Engineer", "Shift In-charge"],
                ["+91-8433997478", "18002096882", "+91-9321701819"],
                [
                  "dcsecurity.nm1@yotta.com",
                  "helpdesk@yotta.com",
                  "ops.shiftincharge@yotta.com"
                ],
              ],
            ),

            /// -----------------------------------------
            /// DC Access TB2
            /// -----------------------------------------
            _section(
              "For DC Access Mumbai-TB2",
              ["1st Level", "2nd Level", "3rd Level"],
              [
                ["Security Team", "Service Desk", "Shift Lead"],
                ["24×7 On Floor", "24×7 On Floor", "24×7 On Floor"],
                ["Security Assistant", "Help Desk Engineer", "Shift In-charge"],
                ["-", "18002096882", "+91-9321701819"],
                [
                  "dcsecurity.tb2@yotta.com",
                  "helpdesk@yotta.com",
                  "ops.shiftincharge@yotta.com"
                ],
              ],
            ),

            /// -----------------------------------------
            /// DC Access Noida-D1
            /// -----------------------------------------
            _section(
              "For DC Access Noida-D1",
              ["1st Level", "2nd Level", "3rd Level"],
              [
                ["Security Team", "Service Desk", "Shift Lead"],
                ["24×7 On Floor", "24×7 On Floor", "24×7 On Floor"],
                ["Security Assistant", "Help Desk Engineer", "Shift In-charge"],
                ["-", "18002096882", "+91-9321701819"],
                [
                  "dcsecurity.d1@yotta.com",
                  "helpdesk@yotta.com",
                  "ops.shiftincharge@yotta.com"
                ],
              ],
            ),

            /// -----------------------------------------
            /// DC Access Gujarat-G1
            /// -----------------------------------------
            _section(
              "For DC Access Gujarat-G1",
              ["1st Level", "2nd Level", "3rd Level"],
              [
                ["Security Team", "Service Desk", "Shift Lead"],
                ["24×7 On Floor", "24×7 On Floor", "24×7 On Floor"],
                ["Security Assistant", "Help Desk Engineer", "Shift In-charge"],
                ["-", "18002096882", "+91-9321701819"],
                [
                  "dcsecurity.g1@yotta.com",
                  "helpdesk@yotta.com",
                  "ops.shiftincharge@yotta.com"
                ],
              ],
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
