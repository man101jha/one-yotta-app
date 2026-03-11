import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/financials_services/financials_services.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class CreditVoucherDetailsPage extends StatefulWidget {
  final String voucherType;
  final String microService;

  const CreditVoucherDetailsPage({
    super.key,
    required this.voucherType,
    required this.microService,
  });

  @override
  State<CreditVoucherDetailsPage> createState() => _CreditVoucherDetailsPageState();
}

class _CreditVoucherDetailsPageState extends State<CreditVoucherDetailsPage> {
  final FinancialServices financialServices = FinancialServices();
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;
 bool _isSearching = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchAndFilterData());
  }

  Future<void> fetchAndFilterData() async {
    setState(() => isLoading = true);
    List<Map<String, dynamic>> rawData = [];

    try {
      if (widget.voucherType == 'availableBalance') {
        final response = await financialServices.getAvailableBalance();
        final json = jsonDecode(response.body);
        final List coupons = json['coupons'] ?? [];

        rawData = coupons
            .where((coupon) => coupon['microsite'] == widget.microService)
            .expand((coupon) => coupon['services'].map((service) => {
                  'Voucher_Code': coupon['coupon_code'],
                  'Microsite': coupon['microsite'],
                  'Currency': coupon['coupon_curr'],
                  'Balance': service['c_balance'],
                  'Service_Name': service['c_product_name'],
                  'Min_bill_amount': coupon['min_inv_bill_amt'],
                  'Max_credit_usage': coupon['max_use_amt'],
                  'Invoice %': coupon['max_perc_allow'],
                  'status': 'Active',
                  // 'services': coupon['services'],
                }))
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        final response = await financialServices.getUsedExpiredBalance();
        final json = jsonDecode(response.body);
        final String key = '${widget.microService}_microsite';
        final section = widget.voucherType == 'usedAmount'
            ? json['used_info']
            : json['exp_info'];

        if (section != null && section[key] != null) {
          rawData = List<Map<String, dynamic>>.from(
            (section[key]['details'] as List).map((data) =>
              widget.voucherType == 'usedAmount'
              ? {
                  'voucher_code': data['coupon_code'],
                  'applied_for': data['applied_for'] ?? '-',
                  'currency': data['coupon_currency'],
                  'microsite': data['microsite_name'],
                  'service_name': data['service_name'],
                  'used_amount': double.parse(data['used_amount'].toString()).toStringAsFixed(2),
                  'used_on': data['applied_on'],
                }
              : {
                  'voucher_code': data['coupon_code'],
                  'currency': data['coupon_currency'],
                  'microsite': data['microsite_name'],
                  'service_name': data['service_name'],
                  'used_amount': double.parse(data['used_amount'].toString()).toStringAsFixed(2),
                  'expired_on': data['applied_on'],
                }
            ),
          );
        }
      }

      setState(() {
        filteredData = rawData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vouchers: $e')),
      );
    }
  }

  String getVoucherTypeLabel(String type) {
    switch (type) {
      case 'availableBalance':
        return 'Available Balance';
      case 'usedAmount':
        return 'Used Vouchers';
      case 'expiredAmount':
        return 'Expired Vouchers';
      default:
        return 'Credit Voucher';
    }
  }

 @override
  Widget build(BuildContext context) {
 final filteredVouchers = filteredData.where((voucher) {
  final searchLower = _searchText.toLowerCase();

  if (widget.voucherType == 'availableBalance') {
    final code = (voucher['Voucher_Code'] ?? '').toString().toLowerCase();
    final service = (voucher['Service_Name'] ?? '').toString().toLowerCase();
    final microsite = (voucher['Microsite'] ?? '').toString().toLowerCase();
    return _searchText.isEmpty ||
        code.contains(searchLower) ||
        service.contains(searchLower) ||
        microsite.contains(searchLower);
  } else {
    final code = (voucher['voucher_code'] ?? '').toString().toLowerCase();
    final service = (voucher['service_name'] ?? '').toString().toLowerCase();
    final microsite = (voucher['microsite'] ?? '').toString().toLowerCase();
    return _searchText.isEmpty ||
        code.contains(searchLower) ||
        service.contains(searchLower) ||
        microsite.contains(searchLower);
  }
}).toList();


    return Scaffold(
      backgroundColor: GlobalColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('Credit Voucher', style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchText = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              getVoucherTypeLabel(widget.voucherType),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF283E81),
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search voucher code or description...',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVouchers.isEmpty
                    ? const Center(child: Text("No vouchers found."))
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FE),
                          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                        ),
                        child: ListView.builder(
                          itemCount: filteredVouchers.length,
                          itemBuilder: (context, index) {
                            final item = filteredVouchers[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                border: Border.all(color: GlobalColors.borderColor),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: _buildTileTitle(item),
                                  children: _buildTileDetails(item),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(),
    );
  }Widget _buildTileTitle(Map<String, dynamic> item) {
    if (widget.voucherType == 'availableBalance') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voucher: ${item['Voucher_Code']}'),
          Text('Currency: ${item['Currency']}'),
          Text('Balance: ${item['Balance']}'),
          Text('Microsite: ${item['Microsite']}'),
        ],
      );
    } else if (widget.voucherType == 'usedAmount') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voucher: ${item['voucher_code']}'),
          Text('Applied For: ${item['applied_for']}'),
          Text('Currency: ${item['currency']}'),
          Text('Used Amount: ${item['used_amount']}'),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voucher: ${item['voucher_code']}'),
          Text('Currency: ${item['currency']}'),
          Text('Microsite: ${item['microsite']}'),
          Text('Expired Amount: ${item['used_amount']}'),
        ],
      );
    }
  }

  List<Widget> _buildTileDetails(Map<String, dynamic> item) {
    return item.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(child: Text(entry.value.toString(), textAlign: TextAlign.right)),
          ],
        ),
      );
    }).toList();
  }
}
