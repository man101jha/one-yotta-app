import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/order_service/order_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class OrderDetailsView extends StatefulWidget {
  final String orderNO;
  final Map<String, dynamic> data;
  final String? lineItemId;

  const OrderDetailsView({
    super.key,
    required this.orderNO,
    required this.data,
    this.lineItemId,
  });

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  bool isLoading = true;
  Map<String, dynamic> orderDetails = {};

  @override
  void initState() {
    super.initState();
    orderDetails = Map.from(widget.data); // Initialize with passed data
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    if (widget.lineItemId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      String sofNo = widget.lineItemId!.length > 4
          ? widget.lineItemId!.substring(0, widget.lineItemId!.length - 4)
          : widget.orderNO; // Fallback or logic adjustment if needed

      final response =
          await OrderService().getOrderLineDetails(sofNo, widget.lineItemId!);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['orders'] != null && (data['orders'] as List).isNotEmpty) {
          final order = data['orders'][0];
          
          // Update contract-level fields if present
          if (order['bill_to_customername'] != null) {
            orderDetails['Bill To Customer'] = order['bill_to_customername'].toString();
          }
          if (order['support_to_customername'] != null) {
            orderDetails['Support To Customer'] = order['support_to_customername'].toString();
          }

          final contractLines = order['ContractLines'] as List?;
          
          if (contractLines != null) {
            final lineItem = contractLines.firstWhere(
              (element) =>
                  element['line_item_id'] == widget.lineItemId,
              orElse: () => null,
            );

            if (lineItem != null) {
              final pricing = lineItem['pricing'];
                 setState(() {
                // Merge new details into orderDetails
                orderDetails['pricing_data'] = pricing;
                
                // Update line-level fields from detailed response
                if (lineItem['bundle_description'] != null) {
                  orderDetails['product description'] = lineItem['bundle_description'].toString();
                }
                if (lineItem['billstartdate'] != null) orderDetails['Bill Start Date'] = lineItem['billstartdate'].toString();
                if (lineItem['billenddate'] != null) orderDetails['Bill End Date'] = lineItem['billenddate'].toString();
                if (lineItem['billing_currency'] != null) orderDetails['Bill Currency'] = lineItem['billing_currency'].toString();
                
                 // Update OTC if available in pricing
                if (pricing != null && pricing is Map && pricing['otc'] != null) {
                   orderDetails['OTC (One Time Charge)'] = pricing['otc'].toString();
                }

                isLoading = false;
              });
            } else {
                 setState(() => isLoading = false);
            }
          } else {
             setState(() => isLoading = false);
          }
        } else {
           setState(() => isLoading = false);
        }
      } else {
         setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching order details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Order Details'),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFF4F7FE),
            border: Border.all(width: 1.0, color: GlobalColors.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      width: 1.0,
                      color: GlobalColors.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order No: ${widget.orderNO?.toString() ?? '-'}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      width: 1.0,
                      color: GlobalColors.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DefaultTabController(
                    length: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        ..._buildDetailsList(orderDetails),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      width: 1.0,
                      color: GlobalColors.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DefaultTabController(
                    length: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getBillTypeTitle(orderDetails),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        ..._buildMrcDetailsList(orderDetails),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  List<Widget> _buildDetailsList(data) {
    print('order data ${data}');
    Map<String, String> details = {
      'Order Line No': data['Order Line No']?.toString() ?? '',
      'Original Order Line No':
          data['Original Order Line No']?.toString() ?? '',
      'Location': data['Location']?.toString() ?? '',
      'Bill To Customer': data['Bill To Customer']?.toString() ?? '',
      'Support To Customer': data['Support To Customer']?.toString() ?? '',
      'Bill Start Date': data['Bill Start Date']?.toString() ?? '',
      'Bill End Date': data['Bill End Date']?.toString() ?? '',
      'Technical Start Date': data['technical start date']?.toString() ?? '',
      'Technical End Date': data['technical end date']?.toString() ?? '',
      'Status': data['Status']?.toString() ?? '',
      'Currency': data['Bill Currency']?.toString() ?? '',
      'PO': data['PO']?.toString() ?? '',
      'PO Date': data['PO Date']?.toString() ?? '',
      'Payment Term': data['Payment Term']?.toString() ?? '',
      'Contract Period': data['Contract period']?.toString() ?? '',
      'Contract Start Date': data['Contract Start Date']?.toString() ?? '',
      'Contract End Date': data['Contract End Date']?.toString() ?? '',
      'Cancelled Date': data['Cancelled Date']?.toString() ?? '',
      'HSN/SAC Code': data['HSN/SAC Code']?.toString() ?? '',
      'UoM': data['UoM']?.toString() ?? '',
      'Sale Type': data['Sale Type']?.toString() ?? '',
      'Product Family': data['Product Family']?.toString() ?? '',
      'Product Line': data['Product Line']?.toString() ?? '',
      'Product Name': data['Product Name']?.toString() ?? '',
      'Product Description': data['product description']?.toString() ?? '',
      'OTC (One Time Charge)': data['OTC (One Time Charge)']?.toString() ?? '',
    };

    return details.entries
        .map((entry) => _buildDetailRow(entry.key, entry.value))
        .toList();
  }

  String _getBillTypeTitle(Map<String, dynamic> data) {
    if (data['pricing_data'] == null || data['pricing_data'] is! Map) {
      return 'MRC (Month Recurring Charge)';
    }
    final pricing = data['pricing_data'];
    if (pricing['vrc'] != null &&
        (pricing['vrc'] is Map) &&
        (pricing['vrc'] as Map).isNotEmpty) {
      return 'VRC (Variable Recurring Charge)';
    }
    return 'MRC (Month Recurring Charge)';
  }

  List<Widget> _buildMrcDetailsList(data) {
    if (data['pricing_data'] == null) return [];

    final pricing = data['pricing_data'];
    if (pricing is! Map) return [];

    Map<String, dynamic>? billJson;
    String typeLabel = 'MRC';

    if (pricing['mrc'] != null &&
        (pricing['mrc'] is Map) &&
        (pricing['mrc'] as Map).isNotEmpty) {
      billJson = pricing['mrc'];
      typeLabel = 'MRC';
    } else if (pricing['vrc'] != null &&
        (pricing['vrc'] is Map) &&
        (pricing['vrc'] as Map).isNotEmpty) {
      billJson = pricing['vrc'];
      typeLabel = 'VRC';
    }

    if (billJson == null) return [];

    List<Map<String, String>> billArray = [];
    billJson.forEach((year, value) {
      if (value is Map) {
        billArray.add({
          'Year': year,
          typeLabel: value['pricing']?.toString() ?? '',
          'Currency': data['Bill Currency']?.toString() ?? '',
          'Start Date': value['startDate']?.toString() ?? '-',
          'End Date': value['endDate']?.toString() ?? '-',
        });
      }
    });

    billArray.sort((a, b) => (a['Year'] ?? '').compareTo(b['Year'] ?? ''));

    return billArray.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children:
              item.entries
                  .map((entry) => _buildDetailRow(entry.key, entry.value))
                  .toList(),
        ),
      );
    }).toList();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black54, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  generateRcData(data, type) {}
}
