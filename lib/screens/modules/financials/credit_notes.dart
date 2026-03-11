import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'dart:convert';

class CreditNotesView extends StatefulWidget {
  const CreditNotesView({super.key});

  @override
  State<CreditNotesView> createState() => _CreditNotesViewState();
}

class _CreditNotesViewState extends State<CreditNotesView> {
  List<Map<String, String>> creditNotes = [];
  Map<int, bool> expandedRows = {};

  bool isLoading = true;
  String? errorMessage;
  bool _isSearching = false;
String _searchText = '';
final TextEditingController _searchController = TextEditingController();


   final FinancialServices _financialServices = FinancialServices();
  
  @override
   void initState() {
    super.initState();
    fetchCreditNotesData();
  }

 String formatValue(dynamic value) {
  if (value == null) return '-';
  final stringValue = value.toString().trim();
  return stringValue.isEmpty || stringValue == '0' ? '-' : stringValue;
}

Future<void> fetchCreditNotesData() async { 
  try {
    final response = await _financialServices.getCreditNotesData(); 

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> notes = data['Response'] ?? [];

      setState(() {
        creditNotes = notes.map<Map<String, String>>((item) {
          return {
            'Credit Note No': formatValue(item['credit_note_no']),
            'Invoice Ref No': formatValue(item['invoice_ref_no']),
            'Order Ref No': formatValue(item['sof_ref_no']),
            'Credit Note Date': formatValue(item['credit_note_date']),
            'Credit Note Period': formatValue(item['credit_note_period']),
            'Currency': formatValue(item['credit_note_currency']),
            'Amount': formatValue(item['credit_note_amount']),
            'Status': formatValue(item['credit_note_status']),
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load credit notes. Status Code: ${response.statusCode}';
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error: $e';
      isLoading = false;
    });
  }
}

   @override

  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: CommonAppBar(
      title: 'Credit Notes',
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      ],
    ),
    body: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        border: Border.all(width: 1.0, color: GlobalColors.borderColor),
      ),
      child: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Search Credit Note No...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchText = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: creditNotes
                  .where((note) =>
                      _searchText.isEmpty ||
                      note['Credit Note No']!
                          .toLowerCase()
                          .contains(_searchText.toLowerCase()) ||
                      note['Invoice Ref No']!
                          .toLowerCase()
                          .contains(_searchText.toLowerCase()) ||
                      note['Order Ref No']!
                          .toLowerCase()
                          .contains(_searchText.toLowerCase()))
                  .length,
              itemBuilder: (context, index) {
                final filteredNotes = creditNotes
                    .where((note) =>
                        _searchText.isEmpty ||
                        note['Credit Note No']!
                            .toLowerCase()
                            .contains(_searchText.toLowerCase()) ||
                        note['Invoice Ref No']!
                            .toLowerCase()
                            .contains(_searchText.toLowerCase()) ||
                        note['Order Ref No']!
                            .toLowerCase()
                            .contains(_searchText.toLowerCase()))
                    .toList();

                final creditNote = filteredNotes[index];
                final isExpanded = expandedRows[index] ?? false;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        width: 1.0, color: GlobalColors.borderColor),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          creditNote['Credit Note No']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Invoice Ref: ${creditNote['Invoice Ref No']!}",
                                style:
                                    const TextStyle(color: Color.fromARGB(255, 53, 52, 52))),
                            Text("Order Ref: ${creditNote['Order Ref No']!}",
                                style:
                                    const TextStyle(color: Color.fromARGB(255, 53, 52, 52))),
                            Text(
                                "Amount: ${creditNote['Amount']!} ${creditNote['Currency']!}",
                                style:
                                    const TextStyle(color: Color.fromARGB(255, 53, 52, 52))),
                            Text("Status: ${creditNote['Status']!}",
                                style:
                                    const TextStyle(color: Color.fromARGB(255, 53, 52, 52))),
                          ],
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            expandedRows[index] = !isExpanded;
                          });
                        },
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow("Credit Note Date",
                                  creditNote['Credit Note Date'] ?? '-'),
                              _buildDetailRow(
                                  "Credit Note Period",
                                  getDisplayValue(
                                      creditNote['Credit Note Period'])),
                              _buildDetailRow(
                                  "Currency", creditNote['Currency'] ?? '-'),
                              // _buildDetailRow(
                              //     "Amount", creditNote['Amount'] ?? '-'),
                              // _buildDetailRow(
                              //     "Status", creditNote['Status'] ?? '-'),
                                    if (creditNote['Status']?.toLowerCase() == 'open')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading credit note...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
                            ],
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    // bottomNavigationBar: const BottomNavigation(),
  );
}
}

String getDisplayValue(String? value) {
  return (value?.trim().isEmpty ?? true) ? '-' : value!;
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(value,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
      ],
    ),
  );
}
