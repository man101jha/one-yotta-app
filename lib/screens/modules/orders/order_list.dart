import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/orders/order_details.dart';
import 'package:myaccount/services/app_services/order_service/order_service.dart';
import 'package:myaccount/services/app_services/session/order_data_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:shimmer/shimmer.dart';

class OrdersView extends StatefulWidget {
  final String? selectedStatusFilter;
  final String? orderNo;
  final bool? flag;
  const OrdersView({
    super.key,
    this.selectedStatusFilter,
    this.orderNo,
    this.flag,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final List<Map<String, String>> orders = [
    {
      'Order No': '1149681',
      'Order Line No': '1',
      'Product Family': 'Network & Connectivity',
      'Product Name': 'Hosted Internet Bandwidth',
      'Bill Start Date': '01-Aug-2024',
      'Bill End Date': '31-Jul-2025',
      'Bill Currency': 'USD',
      'Location': 'NM1 - Data Center',
      'Status': 'Active',
    },
    {
      'Order No': '1149681',
      'Order Line No': '2',
      'Product Family': 'Network & Connectivity',
      'Product Name': 'Internet Bandwidth Usage',
      'Bill Start Date': '01-Aug-2024',
      'Bill End Date': '31-Jul-2025',
      'Bill Currency': 'USD',
      'Location': 'NM1 - Data Center',
      'Status': 'Inactive',
    },
  ];

  Map<String, bool> expandedRows = {};
  String selectedTypeFilter = "";
  String selectedStatusFilter = "All";
  List<Map<String, dynamic>> ordersData = [];
  String? _filteredOrderNo;
  int? _expandedIndex;
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> allOrders = [];

  bool isOrderLoading = true;
  @override
  void initState() {
    super.initState();
    if (widget.selectedStatusFilter != null &&
        widget.selectedStatusFilter!.isNotEmpty) {
      selectedStatusFilter = widget.selectedStatusFilter!;
    }
    _filteredOrderNo = widget.orderNo;
    // _loadCachedOrders();
    _fetchOrders();
    applyFilters();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isOrderLoading = true;
    });
    try {
      final response = await OrderService().getOrdersHeadDetails();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['orders'] != null) {
          _loadOrdersFromCache(data['orders']);
          setState(() {
            applyFilters();
            isOrderLoading = false;
          });
        }
      } else {
        setState(() {
          isOrderLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isOrderLoading = false;
      });
    }
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
      print(contractLines);
      for (final element in contractLines) {
        try {
          final product = element['product'];
          final isProductMap = product is Map;
          final pricing = element['pricing'];
          final isPricingMap = pricing is Map;
          final pricingMrc = (isPricingMap && pricing['mrc'] != null) ? pricing['mrc']['Year_1'] : null;
          final isPricingMrcMap = pricingMrc is Map;
          ordersData.add({
            'Order No':
                map['contract_number']?.toString().trim().isNotEmpty == true
                    ? map['contract_number'].toString()
                    : '-',

            'Product Family':
                isProductMap &&
                        product['product_family_text']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                    ? product['product_family_text'].toString()
                    : '-',

            'Product Name':
                isProductMap &&
                        product['name']?.toString().trim().isNotEmpty == true
                    ? product['name'].toString()
                    : '-',

            'Order Line No':
                element['line_sr_no']?.toString().trim().isNotEmpty == true
                    ? element['line_sr_no'].toString()
                    : '-',
            'Original Order Line No':
                element['original_line_sr_no']?.toString().trim().isNotEmpty ==
                        true
                    ? element['original_line_sr_no'].toString()
                    : '-',

            'Bill Start Date': element['billstartdate']?.toString() ?? '',
            'Bill End Date': element['billenddate']?.toString() ?? '',
            'Bill Currency':
                element['billing_currency']?.toString().trim().isNotEmpty ==
                        true
                    ? element['billing_currency'].toString()
                    : '-',
            'Status':
                element['status']?.toString().trim().isNotEmpty == true
                    ? element['status'].toString()
                    : '-',
            'Location':
                element['location']?.toString().trim().isNotEmpty == true
                    ? element['location'].toString()
                    : '-',
            'sub_external_id':
                element['sub_external_id']?.toString().trim().isNotEmpty == true
                    ? element['sub_external_id'].toString()
                    : '-',
            'nstatus':
                element['nstatus']?.toString().trim().isNotEmpty == true
                    ? element['nstatus'].toString()
                    : '-',
            'technical start date':
                element['technical_start_date']?.toString().trim().isNotEmpty ==
                        true
                    ? element['technical_start_date'].toString()
                    : '-',
            'technical end date':
                element['technical_end_date']?.toString().trim().isNotEmpty ==
                        true
                    ? element['technical_end_date'].toString()
                    : '-',
            'startdate':
                map['startdate']?.toString().trim().isNotEmpty == true
                    ? map['startdate'].toString()
                    : '-',
            'line item id':
                element['line_item_id']?.toString().trim().isNotEmpty == true
                    ? element['line_item_id'].toString()
                    : '-',
            'product description':
                element['bundle_description']?.toString().trim().isNotEmpty ==
                        true
                    ? element['bundle_description'].toString()
                    : '-',
            'Bill To Customer':
                map['bill_to_customername']?.toString().trim().isNotEmpty ==
                        true
                    ? map['bill_to_customername'].toString()
                    : '-',
            'Support To Customer':
                map['support_to_customername']?.toString().trim().isNotEmpty ==
                        true
                    ? map['support_to_customername'].toString()
                    : '-',
            'Payment Term':
                map['rc_advance_payment_term_sos']
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? map['rc_advance_payment_term_sos'].toString()
                    : '-',
            'Contract Start Date':
                map['startdate']?.toString().trim().isNotEmpty == true
                    ? map['startdate'].toString()
                    : '-',
            'Contract End Date':
                map['enddate']?.toString().trim().isNotEmpty == true
                    ? map['enddate'].toString()
                    : '-',
            'HSN/SAC Code':
                isProductMap &&
                        product['hsn_sac_code']?.toString().trim().isNotEmpty ==
                            true
                    ? product['hsn_sac_code'].toString()
                    : '-',
            'Product Line':
                isProductMap &&
                        product['product_line_text']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                    ? product['product_line_text'].toString()
                    : '-',
            'UoM':
                isProductMap &&
                        product['unit_of_measurement']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                    ? product['unit_of_measurement'].toString()
                    : '-',
            'Sale Type':
                isProductMap &&
                        product['sale_type_label']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                    ? product['sale_type_label'].toString()
                    : '-',
            'Cancelled Date':
                element['cancellation_date']?.toString().trim().isNotEmpty ==
                        true
                    ? element['cancellation_date'].toString()
                    : '-',
            'OTC (One Time Charge)':
                isPricingMap &&
                        pricing['otc']?.toString().trim().isNotEmpty == true
                    ? pricing['otc'].toString()
                    : '-',
            'MRC (Month Recurring Charge)':
                isPricingMap &&
                        isPricingMrcMap &&
                        pricingMrc['pricing']?.toString().trim().isNotEmpty ==
                            true
                    ? pricingMrc['pricing'].toString()
                    : '-',
            'MRC Start Date':
                isPricingMap &&
                        isPricingMrcMap &&
                        pricingMrc['startDate']?.toString().trim().isNotEmpty ==
                            true
                    ? pricingMrc['startDate'].toString()
                    : '-',
            'MRC End Date':
                isPricingMap &&
                        isPricingMrcMap &&
                        pricingMrc['endDate']?.toString().trim().isNotEmpty ==
                            true
                    ? pricingMrc['endDate'].toString()
                    : '-',
            'Contract period':
                '${map['contract_tenure_years']?.toString() ?? '0'}y '
                '${map['contract_tenure_months']?.toString() ?? '0'}m '
                '${map['contract_tenure_days']?.toString() ?? '0'}d',
            'PO': map['customer_po']?.toString() ?? '',
            'PO Date': map['customer_po_data']?.toString() ?? '',
            'pricing_data': pricing,
          });
        } catch (e, stack) {
          print('Error while processing element: $e\nStack:\n$stack');
        }
      }
    }
    setState(() {
      filteredOrders = ordersData;
      allOrders = ordersData;
      // applyFilters();
    });
  }

  void applyFilters() {
    List<String> selectedTypes =
        selectedTypeFilter == "All" || selectedTypeFilter.trim().isEmpty
            ? []
            : selectedTypeFilter.split(',').map((e) => e.trim()).toList();

    List<String> selectedCategories =
        selectedStatusFilter == "All" || selectedStatusFilter.trim().isEmpty
            ? []
            : selectedStatusFilter.split(',').map((e) => e.trim()).toList();

    if (widget.flag == false) {
      _filteredOrderNo = null;
    }

    var datasource = widget.flag == false ? ordersData : allOrders;

    List<Map<String, dynamic>> results =
        datasource.where((order) {
          bool matchesType =
              selectedTypes.isEmpty ||
              selectedTypes
                  .map((e) => e.toLowerCase().trim())
                  .contains(
                    order['Product Name']?.toString().toLowerCase().trim(),
                  );

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

                    List<String> statuses =
                        nstatusStr.split(',').map((s) => s.trim()).toList();

                    return statuses.any((status) {
                      return selectedCategories.any(
                        (cat) =>
                            status.toLowerCase() == cat.toLowerCase().trim(),
                      );
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

    if (_filteredOrderNo != null && _filteredOrderNo!.trim().isNotEmpty) {
      allOrders =
          datasource
              .where(
                (order) =>
                    order['Order No']?.toString() ==
                    _filteredOrderNo.toString(),
              )
              .toList();
      results = allOrders;
      _filteredOrderNo = null;
    }

    if (widget.orderNo != null) {
      allOrders.sort((a, b) {
        final aOrderNo = a['Order Line No']?.toString() ?? '';
        final bOrderNo = b['Order Line No']?.toString() ?? '';
        return aOrderNo.compareTo(bOrderNo);
      });
    }

    setState(() {
      filteredOrders = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: 'Order List',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () async {
              final filters = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FilterPage(
                        selectedType: selectedTypeFilter,
                        selectedStatus: selectedStatusFilter,
                        data: ordersData,
                      ),
                ),
              );
              if (filters != null) {
                setState(() {
                  selectedTypeFilter = filters['type'];
                  selectedStatusFilter = filters['status'];
                });
                applyFilters();
              }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.orderNo != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Order No: ${widget.orderNo?.toString() ?? '-'}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: isOrderLoading
                  ? _buildShimmerOrderList()
                  : filteredOrders.isEmpty
                      ? Center(
                          child: Text(
                            "No data available",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];

                          final orderNo = order['Order No']?.toString() ?? '';
                          final orderLineNo =
                              order['Order Line No']?.toString() ?? '';
                          final key = orderNo + orderLineNo;
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
                                  title:
                                      widget.orderNo != null
                                          ? Text(
                                            "Order Line No: ${order['Order Line No']?.toString() ?? '-'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          )
                                          : Text(
                                            "Order No: ${order['Order No']?.toString() ?? '-'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),

                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Product Name: ${order['Product Name']?.toString() ?? '-'}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () {
                                      // setState(() {
                                      //   expandedRows[order['Order No']! + order['Order Line No']!] = !isExpanded;
                                      // });
                                      setState(() {
                                        final orderNo =
                                            order['Order No']?.toString() ?? '';
                                        final orderLineNo =
                                            order['Order Line No']
                                                ?.toString() ??
                                            '';
                                        // expandedRows[orderNo + orderLineNo] =
                                        //     !isExpanded;
                                        final key = orderNo + orderLineNo;

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
                                          "Order Line No",
                                          order['Order Line No']?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Product Family",
                                          order['Product Family']?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Bill Start Date",
                                          order['Bill Start Date']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Bill End Date",
                                          order['Bill End Date']?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Bill Currency",
                                          order['Bill Currency']?.toString() ??
                                              '-',
                                        ),
                                        _buildDetailRow(
                                          "Location",
                                          order['Location']?.toString() ?? '-',
                                        ),
                                        _buildDetailRow(
                                          "Status",
                                          order['Status']?.toString() ?? '-',
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 16),
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor: Color(
                                                0xFFF3F2FF,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 8,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => OrderDetailsView(
                                                        orderNO:
                                                            order['Order No'],
                                                        data: order,
                                                        lineItemId: order[
                                                            'line item id'],
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Text('View Details'),
                                          ),
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

  Widget _buildShimmerOrderList() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 1.0, color: GlobalColors.borderColor),
            color: Colors.white,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              title: Container(
                width: 120,
                height: 16,
                color: Colors.white,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: 200,
                  height: 14,
                  color: Colors.white,
                ),
              ),
              trailing: Container(
                width: 24,
                height: 24,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class FilterPage extends StatefulWidget {
  final String selectedType;
  final String selectedStatus;
  final List<Map<String, dynamic>> data;

  const FilterPage({
    super.key,
    required this.selectedType,
    required this.selectedStatus,
    required this.data,
  });

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late String selectedCategory;
  late List<String> selectedTypes;
  late List<String> selectedCategories;

  late List<String?> productTypes;
  late List<String?> statuses = [
    'Active',
    'To Be Delivered',
    'Under Deactivation',
    'Under Cancellation',
    'To Be Renewed',
    'Deactivation',
    'Cancelled',
    'Expired',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = "Product Type"; // Ensure it has a value
    selectedTypes =
        widget.selectedType == "All" || widget.selectedType.trim().isEmpty
            ? []
            : widget.selectedType.split(',').map((e) => e.trim()).toList();
    selectedCategories =
        widget.selectedStatus == "All" || widget.selectedStatus.trim().isEmpty
            ? []
            : widget.selectedStatus.split(',').map((e) => e.trim()).toList();

    productTypes =
        widget.data
            .map((item) => item['Product Name']?.toString())
            .where(
              (name) => name != null && name.trim().isNotEmpty && name != '-',
            )
            .toSet()
            .toList();

    //   statuses=widget.data.map((item)=> item['nstatus']?.toString())
    //   .where((name) => name != null && name.trim().isNotEmpty && name != '-')
    //   .toSet().toList();
  }

  void toggleSelection(String value, List<String> selectedList) {
    setState(() {
      selectedList.removeWhere((item) => item == "ALL");
      if (selectedList.contains(value)) {
        selectedList.remove(value);
      } else {
        selectedList.add(value);
      }
    });
  }

  void resetFilters() {
    setState(() {
      selectedTypes.clear();
      selectedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Filter Order'),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Row(
          children: [
            // Left panel
            Container(
              width: 150,
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text("Product Type"),
                    selected: selectedCategory == "Product Type",
                    onTap:
                        () => setState(() => selectedCategory = "Product Type"),
                  ),
                  ListTile(
                    title: const Text("Status"),
                    selected: selectedCategory == "Status",
                    onTap: () => setState(() => selectedCategory = "Status"),
                  ),
                ],
              ),
            ),

            // Right panel
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCategory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children:
                            (selectedCategory == "Product Type"
                                    ? productTypes
                                    : statuses)
                                .map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: (selectedCategory ==
                                                      "Product Type"
                                                  ? selectedTypes
                                                  : selectedCategories)
                                              .contains(item),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              toggleSelection(
                                                item!,
                                                selectedCategory ==
                                                        "Product Type"
                                                    ? selectedTypes
                                                    : selectedCategories,
                                              );
                                            });
                                          },
                                        ),
                                        // Text(item, style: const TextStyle(fontSize: 16)),
                                        Flexible(
                                          child: Text(
                                            item!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                            softWrap: true,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow
                                                    .visible, // or .ellipsis
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Reset", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'type':
                      selectedTypes.isEmpty ? "All" : selectedTypes.join(", "),
                  'status':
                      selectedCategories.isEmpty
                          ? "All"
                          : selectedCategories.join(", "),
                });
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Apply Filters"),
            ),
          ],
        ),
      ),
    );
  }
}
