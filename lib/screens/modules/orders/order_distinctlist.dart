import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/orders/order_list.dart';
import 'package:myaccount/screens/pages/utils/download.dart';
import 'package:myaccount/services/app_services/order_service/order_service.dart';
import 'package:myaccount/services/app_services/session/order_data_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class AllOrdersView extends StatefulWidget {
  final String? selectedStatusFilter;
  final bool? flag;
  const AllOrdersView({super.key, this.selectedStatusFilter, this.flag});

  @override
  State<AllOrdersView> createState() => _AllOrdersViewState();
}

class _AllOrdersViewState extends State<AllOrdersView> {
  bool isOrderLoading = true;
  final OrderService _orderDataClient = OrderService();
  List<Map<String, dynamic>> docData = [];
  Future<void> fetchOrderData() async {
    setState(() => isOrderLoading = true);
    try {
      final response = await _orderDataClient.getDocumentData();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // final int count = data['clubTotalCount']['All Services'] ?? 0;
        //  docData = data['documentWrapperList'] ?? {};
        docData = List<Map<String, dynamic>>.from(
          data['documentWrapperList'] ?? [],
        );

        setState(() {
          isOrderLoading = false;
        });
      } else {
        setState(() => isOrderLoading = false);
      }
    } catch (e) {
      setState(() => isOrderLoading = false);
    }
  }

  Map<String, bool> expandedRows = {};
  String selectedTypeFilter = "";
  String selectedStatusFilter = "All";
  List<Map<String, dynamic>> ordersData = [];
  @override
  void initState() {
    super.initState();
    if (widget.selectedStatusFilter != null &&
        widget.selectedStatusFilter!.isNotEmpty) {
      selectedStatusFilter = widget.selectedStatusFilter!;
    }
    fetchOrderData().then((_) {
      _loadCachedOrders(); // Now docData is available
    });
  }

  void _loadCachedOrders() {
    final cachedData = OrderDataManager().getOrdersHeadDetails();
    if (cachedData != null && cachedData['orders'] != null) {
      _loadOrdersFromCache(cachedData['orders']);
    }
  }

  void _loadOrdersFromCache(List<dynamic> ordersList) {
    ordersData = [];
    for (var item in ordersList) {
      final map = Map<String, dynamic>.from(item);
      final contractLines = map['ContractLines'] as List<dynamic>? ?? [];

      for (final element in contractLines) {
        try {
          ordersData.add({
            'Order No':
                map['contract_number']?.toString().trim().isNotEmpty == true
                    ? map['contract_number'].toString()
                    : '-',

            'Bill Start Date': map['startdate']?.toString() ?? '',
            'Bill End Date': map['enddate']?.toString() ?? '',
            'Contract Currency':
                map['contract_currency']?.toString().trim().isNotEmpty == true
                    ? map['contract_currency'].toString()
                    : '-',
            'Status':
                element['status']?.toString().trim().isNotEmpty == true
                    ? element['status'].toString()
                    : '-',
            'nstatus':
                element['nstatus']?.toString().trim().isNotEmpty == true
                    ? element['nstatus'].toString()
                    : '-',
            'Advance Payment Term':
                map['rc_advance_payment_term_sos']?.toString() ?? '-',
            'Contract Start Date': map['startdate']?.toString() ?? '',
            'Contract End Date': map['enddate']?.toString() ?? '',
            'Order period':
                '${map['contract_tenure_years']?.toString() ?? '0'}y '
                '${map['contract_tenure_months']?.toString() ?? '0'}m '
                '${map['contract_tenure_days']?.toString() ?? '0'}d',
          });
        } catch (e, stack) {
          print('Error while processing element: $e\nStack:\n$stack');
        }
      }
    }
    final seenOrderNos = <String>{};
    final uniqueOrders = <Map<String, dynamic>>[];

    for (final order in ordersData) {
      final orderNo = order['Order No']?.toString() ?? '-';
      if (!seenOrderNos.contains(orderNo)) {
        seenOrderNos.add(orderNo);
        uniqueOrders.add(order);
      }
    }

    // Now uniqueOrders contains distinct orders
    ordersData = uniqueOrders;
    List<Map<String, dynamic>> distinctOrders = [];

    for (final contract in ordersData) {
      final contractNumber = contract['Order No']?.toString();

      if (contractNumber != null && contractNumber.isNotEmpty) {
        final hasSignedContractDoc = docData.any(
          (doc) =>
              doc['Contract'] == contractNumber &&
              doc['Document'] == 'Signed Contract',
        );

        // Get list of URLs for this contract
        final contractDocumentUrls =
            docData
                .where((doc) => doc['Contract'] == contractNumber)
                .expand(
                  (doc) =>
                      (doc['ListofDocumentlink'] as List?)
                          ?.whereType<String>() ??
                      [],
                )
                .toList();

        distinctOrders.add({
          'Order No': contract['Order No'] ?? '-',
          'Bill Start Date': contract['Bill Start Date'] ?? '-',
          'Bill End Date': contract['Bill End Date'] ?? '-',
          'Order period': contract['Order period'] ?? '-',
          'total amount': contract['total_grand_total'] ?? '-',
          'Advance Payment Term':
              contract['Advance Payment Term']?.toString() ?? '-',
          'hasSignedContractDoc': hasSignedContractDoc,
          'url': contractDocumentUrls,
        });
      }
    }
    ordersData = distinctOrders;
    setState(() {});
  }

  void _editAllFields(url) {
    // Map<String, TextEditingController> controllers = {
    //   for (var key in companyData.keys)
    //     key: TextEditingController(text: companyData[key])
    // };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            initialChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          '📁 File List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if ((url as List).isNotEmpty)
                        ...url.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fileUrl = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 28,
                              ),
                              title: Text(
                                'File ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed:
                                    () => Iframe.show(
                                      context,
                                      fileUrl.toString(),
                                    ),
                              ),
                            ),
                          );
                        }).toList()
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No files available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showPreviewModal(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              AppBar(
                title: const Text('Preview'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1),
              // Expanded(
              //   // child: WebView(
              //   //   initialUrl: url,
              //   //   javascriptMode: JavascriptMode.unrestricted,
              //   // ),
              // ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> selectedTypes =
        selectedTypeFilter == "All" || selectedTypeFilter.trim().isEmpty
            ? []
            : selectedTypeFilter.split(',').map((e) => e.trim()).toList();
    List<String> selectedCategories =
        selectedStatusFilter == "All" || selectedStatusFilter.trim().isEmpty
            ? []
            : selectedStatusFilter.split(',').map((e) => e.trim()).toList();
    List<Map<String, dynamic>> filteredOrders =
        ordersData.where((order) {
          bool matchesType =
              selectedTypes.isEmpty ||
              selectedTypes.contains(order['Product Name']);

          bool matchesCategory =
              selectedCategories.isEmpty ||
              selectedCategories.any(
                (cat) => cat.toLowerCase().trim() == 'all',
              ) ||
              (order['nstatus'] != null &&
                  () {
                    String nstatusStr = order['nstatus'].toString().trim();
                    if (nstatusStr.startsWith('[') &&
                        nstatusStr.endsWith(']')) {
                      nstatusStr = nstatusStr.substring(
                        1,
                        nstatusStr.length - 1,
                      );
                    }

                    // Now split by comma and trim each
                    List<String> statuses =
                        nstatusStr.split(',').map((s) => s.trim()).toList();

                    return statuses.any((status) {
                      return selectedCategories.any((cat) {
                        return status.toLowerCase() == cat.toLowerCase().trim();
                      });
                    });
                  }());

          if (selectedTypes.isNotEmpty) {
            return matchesType;
          } else if (selectedCategories.isNotEmpty) {
            return matchesCategory;
          } else {
            return true; // No filters selected
          }
        }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: 'All Orders', actions: [
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
            Expanded(
              child:
                  isOrderLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final orderNo = order['Order No']?.toString() ?? '';
                          final key = orderNo;
                          final isExpanded = expandedRows[key] == true;
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                width: 1.0,
                                color: GlobalColors.borderColor,
                              ),
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    "Order No: ${order['Order No']?.toString() ?? '-'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  // subtitle: Text(
                                  //     "Product Name: ${order['Product Name']?.toString() ?? '-'}",
                                  //      style: const TextStyle(color: Colors.grey)),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        final orderNo =
                                            order['Order No']?.toString() ?? '';
                                        final key = orderNo;
                                        final isCurrentlyExpanded =
                                            expandedRows[key] == true;

                                        expandedRows.clear();
                                        if (!isCurrentlyExpanded) {
                                          expandedRows[key] = true;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                          "Order No",
                                          order['Order No']?.toString() ?? '-',
                                        ),
                                        _buildDetailRow(
                                          "Order Period",
                                          order['Order period']?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Start Date",
                                          order['Bill Start Date']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "End Date",
                                          order['Bill End Date']?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Contract Currency",
                                          order['Contract Currency']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Advance Payment Term",
                                          order['Advance Payment Term']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Status",
                                          order['Status']?.toString() ?? '-',
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(top: 16),
                                              child: TextButton(
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Color(
                                                    0xFFF3F2FF,
                                                  ), // light violet
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => OrdersView(
                                                            orderNo:
                                                                order['Order No'],
                                                            flag: true,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Text('View Details'),
                                              ),
                                            ),

                                            const SizedBox(
                                              width: 8,
                                            ), // spacing between buttons
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 16,
                                              ), // ⬅ outside the button
                                              child: TextButton(
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Color(
                                                    0xFFF3F2FF,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ), // internal padding
                                                ),
                                                onPressed: () {
                                                  _editAllFields(order['url']);
                                                },
                                                child: const Text(
                                                  'Document Details',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
