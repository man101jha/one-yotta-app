import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/assets/assets_details.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';

class AssetsView extends StatefulWidget {
  final String? selectedTypeFilter;
  const AssetsView({super.key, this.selectedTypeFilter});

  @override
  State<AssetsView> createState() => _AssetsViewState();
}

class _AssetsViewState extends State<AssetsView> {
  List<Map<String, String>> assetsData = [];
  bool isLoading = true;
  final AuthService _authService = AuthService();
  // final List<Map<String, String>> assetsData = [
  //   {
  //     'Asset ID': 'YSNM1CVBKP1',
  //     'Serial Number': '54667',
  //     'Type': 'Logical',
  //     'Category': 'End Point Backup',
  //     'Brand': 'Dell',
  //     'Location': 'Mumbai - HO'
  //   },
  //   {
  //     'Asset ID': 'YSNM1CVBKP1',
  //     'Serial Number': '54718',
  //     'Type': 'Logical',
  //     'Category': 'End Point Backup',
  //     'Brand': 'Dell',
  //     'Location': 'Mumbai - HO'
  //   },
  //   {
  //     'Asset ID': 'YIS-E819-6-win2k16_VM',
  //     'Serial Number': '44308',
  //     'Type': 'Virtual',
  //     'Category': 'Virtual Server',
  //     'Brand': '-',
  //     'Location': 'NM1 - Data Center'
  //   },
  //   {
  //     'Asset ID': 'YSNM1CVBKP1',
  //     'Serial Number': '55642',
  //     'Type': 'Logical',
  //     'Category': 'End Point Backup',
  //     'Brand': 'Dell',
  //     'Location': 'Mumbai - HO'
  //   },
  // ];
  String selectedTypeFilter = "All";
  String selectedCategoryFilter = "All";
  String _searchText = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    selectedTypeFilter = widget.selectedTypeFilter ?? 'ALL';
    _loadCachedAssets();
  }

  void _loadCachedAssets() {
    final cachedData = AssetDataManager().getAssetData();
    if (cachedData != null && cachedData['result'] != null) {
      _loadAssetsFromCache(cachedData['result']);
      setState(() => isLoading = false);
    } else {
      fetchAssetsFromApi();
    }
  }

  void _loadAssetsFromCache(List<dynamic> assetList) {
    assetsData =
        assetList.map<Map<String, String>>((item) {
          final basic = item['basicdetails'] ?? {};
          final location = item['locationdata'] ?? {};
          final assetDetail = item['assetdetails'] ?? {};
          final sofDetails = item['sofdetails'] ?? {};
          return {
            //assetDetail
            'Asset Name': (basic['displayname']?.toString().trim().isNotEmpty ?? false)? basic['displayname'] : 'NA',
            'Asset ID': (item['id']?.toString().trim().isNotEmpty ?? false)?item['id'] : 'NA',
            'Type': (basic['assettype']?.toString().trim().isNotEmpty ?? false)?basic['assettype'] : 'NA',
            'Subtype': (basic['assetsubtype']?.toString().trim().isNotEmpty ?? false)?basic['assetsubtype'] : 'NA',
            'Make': (basic['make']?.toString().trim().isNotEmpty ?? false)? basic['make']: 'NA',
            'Model': (basic['model']?.toString().trim().isNotEmpty ?? false)? basic['model']: 'NA',
            'Category': (basic['assetcategory']?.toString().trim().isNotEmpty ?? false)?basic['assetcategory'] : 'NA',

            //Basic detail
            'Serial Number':(assetDetail['serial number']?.toString().trim().isNotEmpty ?? false)? assetDetail['serial number'] : 'NA',
            'UAN': (basic['uan']?.toString().trim().isNotEmpty ?? false)? basic['uan'] : 'NA',
            "Manufacture Sr No": (basic['manufacturersrno']?.toString().trim().isNotEmpty ?? false)?basic['manufacturersrno'] : 'NA',
            'Supplier': (assetDetail['supplier']?.toString().trim().isNotEmpty ?? false)?assetDetail['supplier'] : 'NA',
            'Quantity': (basic['quantity']?.toString().trim().isNotEmpty ?? false)?basic['quantity'] : 'NA',
            "AMC Vendor": (assetDetail['amc vendor']?.toString().trim().isNotEmpty ?? false)?assetDetail['amc vendor'] : 'NA',
            "AMC Type": (assetDetail['amc type']?.toString().trim().isNotEmpty ?? false)?assetDetail['amc type'] : 'NA',
            "AMC Start Date": (basic['amcstartdate']?.toString().trim().isNotEmpty ?? false)?basic['amcstartdate'] : 'NA',
            "AMC Expire Date": (basic['amcenddate']?.toString().trim().isNotEmpty ?? false)?basic['amcenddate'] : 'NA',
            "Commission Date":(assetDetail['commissioning date']?.toString().trim().isNotEmpty ?? false)? assetDetail['commissioning date'] : 'NA',
            "Warranty Start Date": (basic['warrantystartdate']?.toString().trim().isNotEmpty ?? false)?basic['warrantystartdate'] : 'NA',
            "Warranty Expire Date": (basic['warrantyenddate']?.toString().trim().isNotEmpty ?? false)?basic['warrantyenddate'] : 'NA',
            "Asset Status": (basic['assetstatus']?.toString().trim().isNotEmpty ?? false)?basic['assetstatus'] : 'NA',

            //Technical Detail
            "Technical Detail": jsonEncode(assetDetail ?? {}),

            //Location Detail
            'Location': (location['plant']?.toString().trim().isNotEmpty ?? false)?location['plant'] : 'NA',
            "Floor": (location['floor']?.toString().trim().isNotEmpty ?? false)?location['floor'] : 'NA',
            "Functional Location": (location['functionallocation']?.toString().trim().isNotEmpty ?? false)?location['functionallocation'] : 'NA',

            //SOF details
            "SOF details": jsonEncode(sofDetails ?? []),
          };
        }).toList();
  }

  Future<void> fetchAssetsFromApi() async {
    setState(() => isLoading = true);
    try {
      final token = await _authService.getAccessToken();
      final sessionData = SessionManager().getSessionData();
      final bto = sessionData?['bto'];
      final sto = sessionData?['sto'];

      if (token == null) {
        throw Exception('Access token not found.');
      }
      final response = await http.post(
        Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_asset/api/get_asset_details',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "bill_to_customerid": bto,
          "support_to_customerid": sto,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AssetDataManager().setAssetData(data); // cache if needed

        final List<dynamic> result = data['result'] ?? [];
        assetsData =
            result.map<Map<String, String>>((item) {
              final basic = item['basicdetails'] ?? {};
              final location = item['locationdata'] ?? {};
              final assetDetail = item['assetdetails'] ?? {};
              final sofDetails = item['sofdetails'] ?? {};
              return {
                //assetDetail
                'Asset Name': basic['displayname'] ?? '',
                'Asset ID': item['id'] ?? '',
                'Type': basic['assettype'] ?? '',
                'Subtype': basic['assetsubtype'] ?? '',
                'Make': basic['make'] ?? '',
                'Model': basic['model'] ?? '',
                'Category': basic['assetcategory'] ?? '',

                //Basic detail
                'Serial Number': assetDetail['serial number'] ?? '',
                'UAN': basic['uan'] ?? '',
                "Manufacture Sr No": basic['manufacturersrno'] ?? '',
                'Supplier': assetDetail['supplier'] ?? '',
                'Quantity': basic['quantity'] ?? '',
                "AMC Vendor": assetDetail['amc vendor'] ?? '',
                "AMC Type": assetDetail['amc type'] ?? '',
                "AMC Start Date": basic['amcstartdate'] ?? '',
                "AMC Expire Date": basic['amcenddate'] ?? '',
                "Commission Date": assetDetail['commissioning date'] ?? '',
                "Warranty Start Date": basic['warrantystartdate'] ?? '',
                "Warranty Expire Date": basic['warrantyenddate'] ?? '',
                "Asset Status": basic['assetstatus'] ?? '',

                //Technical Detail
                "Technical Detail": jsonEncode(assetDetail ?? {}),

                //Location Detail
                'Location': location['plant'] ?? '',
                "Floor": location['floor'] ?? '',
                "Functional Location": location['functionallocation'] ?? '',

                //SOF details
                "SOF details": jsonEncode(sofDetails ?? []),
              };
            }).toList();
      }
    } catch (e) {
      print('Error fetching assets: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    List<String> selectedTypes =
        selectedTypeFilter == "All" || selectedTypeFilter.trim().isEmpty
            ? []
            : selectedTypeFilter.split(',').map((e) => e.trim()).toList();
    List<String> selectedCategories =
        selectedCategoryFilter == "All" || selectedCategoryFilter.trim().isEmpty
            ? []
            : selectedCategoryFilter.split(',').map((e) => e.trim()).toList();
    List<Map<String, String>> filteredAssets =
        assetsData.where((asset) {
          bool matchesType =
              selectedTypes.isEmpty || selectedTypes.contains(asset['Type']);
          bool matchesCategory =
              selectedCategories.isEmpty ||
              selectedCategories.contains(asset['Category']);
bool matchesSearch = _searchText.isEmpty ||
    asset['Asset Name']!.toLowerCase().contains(_searchText.toLowerCase()) ||
    asset['Subtype']!.toLowerCase().contains(_searchText.toLowerCase());

return matchesType && matchesCategory && matchesSearch;
        }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: 'Assets List',
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
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () async {
              final filters = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FilterPage(
                        selectedType: selectedTypeFilter,
                        selectedCategory: selectedCategoryFilter,
                        assetsData: assetsData,
                      ),
                ),
              );
              if (filters != null) {
                setState(() {
                  selectedTypeFilter = filters['type'];
                  selectedCategoryFilter = filters['category'];
                });
              }
            },
          ),
        ],
      ),
     body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search assets...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                border: Border.all(
                  width: 1.0,
                  color: GlobalColors.borderColor,
                ),
              ),
              child: filteredAssets.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredAssets.length,
                      itemBuilder: (context, index) {
                        final asset = filteredAssets[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              width: 1.0,
                              color: GlobalColors.borderColor,
                            ),
                            color: Colors.white,
                          ),
                          child: ListTile(
                            title: Text(
                              asset['Subtype']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "Asset Name: ${asset['Asset Name']!}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blueAccent,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AssetsDetailsView(asset: asset),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : const Center(child: Text("No assets found",style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey,
                              ),)),
            ),
          ),
        ],
      ));

  }
}

class FilterPage extends StatefulWidget {
  final String selectedType;
  final String selectedCategory;
  final List<Map<String, String>> assetsData;

  const FilterPage({
    super.key,
    required this.selectedType,
    required this.selectedCategory,
    required this.assetsData,
  });

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late String selectedCategory;
  late List<String> selectedTypes;
  late List<String> selectedCategories;

  late List<String> typeOptions;
  late List<String> categoryOptions;

  @override
  void initState() {
    super.initState();
    print('assestTypes');
    print(widget.assetsData);
    // typeOptions = widget.assetsData.map((e) => e['Type']!).toSet().toList();
    typeOptions = widget.assetsData
    .map((e) => e['Type'] as String? ?? '')   // get value safely
    .where((type) => type.trim().isNotEmpty)  // keep only non-empty
    .toSet()
    .toList();
    // categoryOptions =
    //     widget.assetsData.map((e) => e['Category']!).toSet().toList();

categoryOptions=widget.assetsData
    .map((e) => e['Category'] as String? ?? '')   // get value safely
    .where((type) => type.trim().isNotEmpty)  // keep only non-empty
    .toSet()
    .toList();
    selectedCategory = "Type";
    selectedTypes =
        widget.selectedType == "All"
            ? []
            : widget.selectedType.split(',').map((e) => e.trim()).toList();
    selectedCategories =
        widget.selectedCategory == "All"
            ? []
            : widget.selectedCategory.split(',').map((e) => e.trim()).toList();
  }

  void toggleSelection(String value, List<String> selectedList) {
    setState(() {
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
      appBar: const CommonAppBar(title: 'Filter Assets'),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 150,
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text("Type"),
                    selected: selectedCategory == "Type",
                    onTap: () => setState(() => selectedCategory = "Type"),
                  ),
                  ListTile(
                    title: const Text("Category"),
                    selected: selectedCategory == "Category",
                    onTap: () => setState(() => selectedCategory = "Category"),
                  ),
                ],
              ),
            ),
            
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
                            (selectedCategory == "Type"
                                    ? typeOptions
                                    : categoryOptions)
                                .map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: (selectedCategory == "Type"
                                                  ? selectedTypes
                                                  : selectedCategories)
                                              .contains(item),
                                          onChanged: (bool? value) {
                                            toggleSelection(
                                              item,
                                              selectedCategory == "Type"
                                                  ? selectedTypes
                                                  : selectedCategories,
                                            );
                                          },
                                        ),
                                        Text(
                                          item,
                                          style: const TextStyle(fontSize: 16),
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
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: resetFilters, child: const Text("Reset")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'type':
                      selectedTypes.isEmpty ? "All" : selectedTypes.join(", "),
                  'category':
                      selectedCategories.isEmpty
                          ? "All"
                          : selectedCategories.join(", "),
                });
              },
              child: const Text("Apply Filters"),
            ),
          ],
        ),
      ),
    );
  }
}
