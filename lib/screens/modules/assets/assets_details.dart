import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/utilities/string_utils.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class AssetsDetailsView extends StatefulWidget {
  final Map<String, String> asset;

  const AssetsDetailsView({super.key, required this.asset});

  @override
  State<AssetsDetailsView> createState() => _AssetsDetailsViewState();
}

class _AssetsDetailsViewState extends State<AssetsDetailsView> {
  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Assets Details'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset['Asset Name'] ?? '-',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Divider(thickness: 1, color: GlobalColors.borderColor),
                  SizedBox(height: 10),
                  // 3 rows, 2 columns
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.textcolor,
                              ),
                            ),
                            Text(
                              asset['Category'] ?? '-',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.textcolor,
                              ),
                            ),
                            Text(
                              asset['Type'] ?? '-',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subtype',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.textcolor,
                              ),
                            ),
                            Text(
                              asset['Subtype'] ?? '-',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Make',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.textcolor,
                              ),
                            ),
                            Text(
                              asset['Make'] ?? '-',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Model',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.textcolor,
                              ),
                            ),
                            Text(
                              asset['Model'] ?? '-',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assest ID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.textcolor,
                              ),
                            ),
                            Text(
                              asset['Asset ID'] ?? '-',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueAccent,
                      tabs: const [
                        Tab(text: "Basic Details"),
                        Tab(text: "Technical Details"),
                        Tab(text: "Location"),
                        Tab(text: "Order Details"),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(0),
                            child: _buildDetailSection("Basic Details", {
                              "Serial No": asset['Serial Number'] ?? '-',
                              "UAN": asset['UAN'] ?? '-',
                              "Manufacture Sr No":
                                  asset['Manufacture Sr No'] ?? '-',
                              "Supplier": asset['Supplier'] ?? '-',
                              "Quantity": asset['Quantity'] ?? '-',
                              "AMC Vendor": asset['AMC Vendor'] ?? '-',
                              "AMC Type": asset['AMC Type'] ?? '-',
                              "AMC Start Date": asset['AMC Start Date'] ?? '-',
                              "AMC Expire Date":
                                  asset['AMC Expire Date'] ?? '-',
                              "Commission Date":
                                  asset['Commission Date'] ?? '-',
                              "Warranty Start Date":
                                  asset['Warranty Start Date'] ?? '-',
                              "Warranty Expire Date":
                                  asset['Warranty Expire Date'] ?? '-',
                              "Asset Status": asset['Asset Status'] ?? '-',
                            }),
                          ),
                          SingleChildScrollView(
                         child:_buildDetailSection(
                            "Technical Details",
                            (asset['Technical Detail'] != null)
                                ? Map<String, String>.from(
                                  (asset['Technical Detail'] is String)
                                      ? (jsonDecode(
                                                asset['Technical Detail']
                                                    as String,
                                              )
                                              as Map)
                                          .map(
                                            (k, v) => MapEntry(
                                              k.toString(),
                                              v?.toString() ?? '-',
                                            ),
                                          )
                                      : (asset['Technical Detail'] as Map).map(
                                        (k, v) => MapEntry(
                                          k.toString(),
                                          v?.toString() ?? '-',
                                        ),
                                      ),
                                )
                                : {},
                          ),),
                          SingleChildScrollView(
                          child:_buildDetailSection("Location", {
                            "Location": asset['Location'] ?? '-',
                            "Floor": asset['Floor'] ?? '-',
                            "Functional Location":
                                asset['Functional Location'] ?? '-',
                          }),),
                          SingleChildScrollView(

                            padding: const EdgeInsets.fromLTRB(15,0,15,0),
                          child:_buildOrderDetailsSection(asset['SOF details']),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
             
             ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildDetailSection(String title, Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15,0,15,0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 10),
            for (var entry in data.entries)
              _buildInfoRow(entry.key, entry.value),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              toTitleCase(label),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: GlobalColors.textcolor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection(String? sofDetailsRaw) {
    List sofDetails = [];
    if (sofDetailsRaw != null && sofDetailsRaw.isNotEmpty) {
      try {
        sofDetails = jsonDecode(sofDetailsRaw);
      } catch (_) {}
    }

    if (sofDetails.isEmpty) {
      return const Center(child: Text("No order details found"));
    }

    return SingleChildScrollView(
      child: Column(
        children:
            sofDetails.map<Widget>((item) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Order No: ${item['SOFNumber'] ?? '-'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Line No: ${item['SOFLineSrNo'] ?? '-'}"),
                          Spacer(),
                          Text("Project: ${item['SOFProject'] ?? '-'}"),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
