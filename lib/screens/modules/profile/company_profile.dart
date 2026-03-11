import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/financials/add_money.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/starter_service.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/auth_service.dart';

class CompanyProfileView extends StatefulWidget {
  const CompanyProfileView({super.key});

  @override
  State<CompanyProfileView> createState() => _CompanyProfileViewState();
}

class _CompanyProfileViewState extends State<CompanyProfileView> {
  Map<String, String> companyData = {};
  bool isLoading = true;
  final AccountDataService _accountDataService = AccountDataService();
  final ApiClient _apiClient = ApiClient();
  int mfaStatus = 0;
  final AuthService _authService = AuthService();
  String displayMessage = '';

  static List<String> companyTypes = [
    'Private Limited',
    'Public Limited',
    'Govt Company',
    'Limited Liability Partnership',
    'NBFC',
    'Proprietorship/Individual',
    'Trust/NGO/Society/HUF',
  ];

  static List<Map<String, String>> verticalIndustry = [
    {"vertical": "Manufacturing", "industry": "Apparel & Fashion"},
    {"vertical": "Manufacturing", "industry": "Automotive"},
    {"vertical": "Manufacturing", "industry": "Chemicals"},
    {"vertical": "Manufacturing", "industry": "Consumer Products"},
    {"vertical": "Manufacturing", "industry": "Engineering and Construction"},
    {"vertical": "Manufacturing", "industry": "Hi-tech and electronic"},
    {"vertical": "Manufacturing", "industry": "Pharma"},
    {"vertical": "Services", "industry": "Cargo & Logistics"},
    {"vertical": "Services", "industry": "Education"},
    {"vertical": "Services", "industry": "Electricity"},
    {"vertical": "Services", "industry": "Healthcare"},
    {"vertical": "Services", "industry": "Hospitality"},
    {"vertical": "Services", "industry": "NGO"},
    {"vertical": "Services", "industry": "Research and consultancy"},
    {"vertical": "Services", "industry": "Retail & Distribution (physical)"},
    {"vertical": "Services", "industry": "Retail Services"},
    {"vertical": "Services", "industry": "Transport"},
    {"vertical": "Services", "industry": "Travel and Tourism"},
    {"vertical": "BFSI", "industry": "Fintech"},
    {"vertical": "BFSI", "industry": "Global BFSI centers"},
    {"vertical": "BFSI", "industry": "Insurance"},
    {"vertical": "BFSI", "industry": "Mobile Banking"},
    {"vertical": "BFSI", "industry": "Other Financial Services"},
    {"vertical": "BFSI", "industry": "Payment Gateways"},
    {"vertical": "BFSI", "industry": "Security stock trader / Broker"},
    {"vertical": "BFSI", "industry": "Stock Exchanges"},
    {"vertical": "IT&ITES", "industry": "E-Commerce"},
    {"vertical": "IT&ITES", "industry": "Global CDN Players"},
    {"vertical": "IT&ITES", "industry": "Global DC Players"},
    {"vertical": "IT&ITES", "industry": "Global Internet Exchanges"},
    {"vertical": "IT&ITES", "industry": "Global ISP"},
    {"vertical": "IT&ITES", "industry": "Global TSP"},
    {"vertical": "IT&ITES", "industry": "Hoster & Local DC Players"},
    {"vertical": "IT&ITES", "industry": "Hyperscalers"},
    {"vertical": "IT&ITES", "industry": "Independent Software Vendor (ISV)"},
    {"vertical": "IT&ITES", "industry": "Info Tech Services"},
    {"vertical": "IT&ITES", "industry": "ITES/BPO/KPO"},
    {"vertical": "IT&ITES", "industry": "Local Internet Exchange/ CDN"},
    {"vertical": "IT&ITES", "industry": "Local ISP"},
    {"vertical": "IT&ITES", "industry": "Local TSP"},
    {"vertical": "IT&ITES", "industry": "Mobile OEM"},
    {"vertical": "IT&ITES", "industry": "Online Portals"},
    {
      "vertical": "Media and entertainment",
      "industry": "Broadcast (TV, Radio, etc)",
    },
    {"vertical": "Media and entertainment", "industry": "Content Creation"},
    {"vertical": "Media and entertainment", "industry": "Content Distribution"},
    {"vertical": "Media and entertainment", "industry": "Content Processing"},
    {"vertical": "Media and entertainment", "industry": "Print"},
    {"vertical": "Govt & PSU", "industry": "Central Government"},
    {"vertical": "Govt & PSU", "industry": "Public Sector Units"},
    {"vertical": "Govt & PSU", "industry": "State Government"},
    {"vertical": "Hyperscalers", "industry": "Global BFSI centers"},
    {"vertical": "Hyperscalers", "industry": "Global CDN Players"},
    {"vertical": "Hyperscalers", "industry": "Global Cloud Players"},
    {"vertical": "Hyperscalers", "industry": "Global DC Players"},
    {"vertical": "Hyperscalers", "industry": "Global Internet Exchanges"},
    {"vertical": "Hyperscalers", "industry": "Global ISP"},
    {"vertical": "Hyperscalers", "industry": "Global TSP"},
    {"vertical": "Hyperscalers", "industry": "OTT"},
  ];

  String? selectedCompanyType;
  String? selectedVertical;
  String? selectedIndustry;

  List<String> verticals =
      verticalIndustry.map((e) => e['vertical']!).toSet().toList()..sort();

  List<String> industriesForSelectedVertical = [];

  late Map<String, TextEditingController> _controllers;

bool isMfaEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
    fetchSessionData();
    checkMFAStatus();
  }

  Future<void> fetchSessionData() async {
    try {
      final response = await _apiClient.getSessionStarter();
      if (response.statusCode == 200) {
        final sessionData = jsonDecode(response.body);
      }
    } catch (e) {
      print('Exception fetching session: $e');
    }
  }

  Future<void> _loadCompanyData() async {
    setState(() => isLoading = true);

    var cachedData = AccountDataManager().getAccountData();
    if (cachedData != null && cachedData.isNotEmpty) {
      _setCompanyDataFromMap(cachedData);
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await _accountDataService.getAccountData();
      if (response.statusCode == 200) {
        var freshData = AccountDataManager().getAccountData();
        if (freshData != null) _setCompanyDataFromMap(freshData);
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void _setCompanyDataFromMap(Map<String, dynamic> data) {
    companyData = {
      'Company Name': data['accountName'] ?? 'N/A',
      'Company Type': data['accountCompanyType'] ?? 'N/A',
      'CRM ID': data['accountCRMNo']?.toString() ?? 'N/A',
      'Account Status': data['accountStatus'] ?? 'N/A',
      'Vertical-Industry':
          '${data['accountVertical'] ?? ''} - ${data['accountIndustry'] ?? ''}'
                  .trim()
                  .replaceAll(RegExp(r'^-|-$'), '')
                  .isNotEmpty
              ? '${data['accountVertical']} - ${data['accountIndustry']}'
              : 'N/A',
      'PAN': data['accountPAN'] ?? '',
      'TAN': data['accountTAN'] ?? '',
      'DUNS': data['accountDUNS'] ?? '',
      'KYC': data['accountKYCApprovalStatus'] ?? 'N/A',
      'Website': data['accountWebsite'] ?? '',

      /// FIX: Wallet consent readable + always left aligned
      'Wallet Payment Consent':
          (data['accountWalletConsent'] == 1) ? 'Enabled' : 'Disabled',
      'Multi-Factor-Authentication': data['isMFAEnabled'] == 1 ? 'Enable' : 'Disable',
    };
    mfaStatus = data['isMFAEnabled'] ;
  }

  Future<void> checkMFAStatus() async {
    final session = SessionManager().getSessionData();
    try {
      final token = await _authService.getAccessToken();
      final acctUUID = session?['acctUUID'];
      final url = Uri.parse('https://uatmyaccountapi.yotta.com/my_account/api/v1/accounts/$acctUUID',);
      final response = await http.get(url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          mfaStatus = data['isMFAEnabled'];
        });
      } else {
        debugPrint('Failed to fetch MFA status: ${response.statusCode}',
      );
      }
    } catch (e) {
    debugPrint('Error while checking MFA status: $e');
    }
  }


Future<void> onMfaToggle(bool isChecked) async {
  final session = SessionManager().getSessionData();

  setState(() {
    isLoading = true;
  });

  int mfaEnable = isChecked ? 1 : 0;

  String displayMessage = isChecked ? 'Do you want to enable secure Multi-Factor Authentication?' : 'Do you want to disable secure Multi-Factor Authentication?';

  bool? confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Confirmation'),
      content: Text(displayMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirm != true) {
    setState(() {
      isLoading = false;
    });
    return;
  }

  try {
    final url = Uri.parse(
      'https://uatmyaccountapi.yotta.com/my_account/api/v1/auth/advanced',
    ).replace(
      queryParameters: {
        'acc': session?['acctUUID'],
        'u_uuid': session?['userUUID'],
        'on': mfaEnable.toString(),
      },
    );

    final token = await _authService.getAccessToken();

    final response = await http.post( url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final res = jsonDecode(response.body);

    setState(() {
      isLoading = false;
    });

    if (res['success'] == true) {
      await checkMFAStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Multi Factor Authentication '
            '${res['request_type'] == 'enabled' ? 'Enabled' : 'Disabled'}',
          ),
        ),
      );
    } else {
      await checkMFAStatus();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(res['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });

    await checkMFAStatus();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

  void _editAllFields() {
  // ---------- Initialize controllers ONCE ----------
  _controllers = {
    for (var key in companyData.keys)
      key: TextEditingController(
        text: companyData[key]?.toString() ?? '',
      ),
  };

  // ---------- Initialize dropdown values ----------
  selectedCompanyType =
      companyData['Company Type'] != 'N/A' ? companyData['Company Type'] : null;

  final vi = companyData['Vertical-Industry'] ?? '';
  final parts = vi.split('-');
  selectedVertical = parts.isNotEmpty ? parts[0].trim() : null;
  selectedIndustry = parts.length > 1 ? parts[1].trim() : null;

  industriesForSelectedVertical = verticalIndustry
      .where((e) => e['vertical'] == selectedVertical)
      .map((e) => e['industry']!)
      .toList()
    ..sort();

  isMfaEnabled = mfaStatus == 1;

  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          const Text(
                            "Edit Company Profile",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ---------- FORM FIELDS ----------
                          ...companyData.keys.map((key) {
                            // ----- Company Type -----
                            if (key == "Company Type") {
                              bool isEnabled = companyData['KYC'] != 'Approved';
                              return DropdownButtonFormField<String>(
                                value: selectedCompanyType,
                                items: isEnabled
                                    ? companyTypes
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList()
                                    : [
                                        DropdownMenuItem(
                                            value: selectedCompanyType,
                                            child: Text(selectedCompanyType ?? ''))
                                      ],
                                onChanged: isEnabled
                                    ? (value) {
                                        setModalState(() {
                                          selectedCompanyType = value;
                                        });
                                        _controllers[key]!.text = value ?? '';
                                      }
                                    : null,
                                decoration: InputDecoration(
                                  labelText: key,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? "Company Type required" : null,
                              );
                            }

                            // ----- Vertical - Industry -----
                            if (key == "Vertical-Industry") {
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: selectedVertical,
                                    items: verticals
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(v),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedVertical = value;
                                        industriesForSelectedVertical =
                                            verticalIndustry
                                                .where((e) =>
                                                    e['vertical'] == value)
                                                .map((e) => e['industry']!)
                                                .toList()
                                              ..sort();
                                        selectedIndustry = null;
                                      });
                                      _controllers[key]!.text =
                                          "${selectedVertical ?? ''} - ";
                                    },
                                    decoration: const InputDecoration(
                                      labelText: "Vertical",
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        v == null ? "Vertical required" : null,
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: selectedIndustry,
                                    items: industriesForSelectedVertical
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedIndustry = value;
                                      });
                                      _controllers[key]!.text =
                                          "${selectedVertical ?? ''} - ${selectedIndustry ?? ''}";
                                    },
                                    decoration: const InputDecoration(
                                      labelText: "Industry",
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        v == null ? "Industry required" : null,
                                  ),
                                ],
                              );
                            }

                            // ----- Wallet Consent -----
                            if (key == "Wallet Payment Consent") {
                              return DropdownButtonFormField<String>(
                                value: _controllers[key]!.text.toLowerCase() ==
                                        "enabled"
                                    ? "enabled"
                                    : "disabled",
                                items: const [
                                  DropdownMenuItem(
                                      value: "enabled",
                                      child: Text("Enabled")),
                                  DropdownMenuItem(
                                      value: "disabled",
                                      child: Text("Disabled")),
                                ],
                                onChanged: (value) {
                                  _controllers[key]!.text =
                                      value == "enabled"
                                          ? "Enabled"
                                          : "Disabled";
                                },
                                decoration: InputDecoration(
                                  labelText: key,
                                  border: const OutlineInputBorder(),
                                ),
                              );
                            }

                            // ----- MFA Toggle -----
                            if (key == "Multi-Factor-Authentication") {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(key,
                                        style:
                                            const TextStyle(fontSize: 16)),
                                    Switch(
                                      value: isMfaEnabled,
                                      onChanged: (value) async {
                                        await onMfaToggle(value);
                                        setModalState(() {
                                          isMfaEnabled = value;
                                        });
                                        _controllers[key]!.text =
                                            value.toString();
                                      },
                                    ),
                                    Text(
                                      isMfaEnabled
                                          ? "Enabled"
                                          : "Disabled",
                                      style: TextStyle(
                                        color: isMfaEnabled
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // ----- Default Text Field -----
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: TextFormField(
                                controller: _controllers[key],
                                decoration: InputDecoration(
                                  labelText: key,
                                  border: const OutlineInputBorder(),
                                ),
                                enabled: key == "Company Name" 
                                    ? companyData['KYC'] != 'Approved'
                                    : !["CRM ID", "Account Status", "KYC"].contains(key),
                                validator: (value) {
                                  if (value == null) return null;
                                  
                                  if (key == "Company Name") {
                                    if (value.trim().isEmpty) return "Enter Company Name";
                                    if (value.length > 255) return "Company Name must contain only 255 alphabets.";
                                  }
                                  
                                  if (_containsHtmlTags(value)) {
                                    return "HTML tags are not allowed";
                                  }
                                  
                                  if (key == "PAN" && value.isNotEmpty) {
                                    if (!RegExp(r"^([a-zA-Z]){5}[0-9]{4}([a-zA-Z]){1}$").hasMatch(value)) {
                                      return "PAN must be in (5 Alphabets, 4 Digit, 1 Alphabet) format";
                                    }
                                  }
                                  if (key == "TAN" && value.isNotEmpty) {
                                    if (!RegExp(r"^([a-zA-Z]){4}[0-9]{5}([a-zA-Z]){1}$").hasMatch(value)) {
                                      return "TAN must be in (4 Alphabets, 5 Digit, 1 Alphabet) format";
                                    }
                                  }
                                  return null;
                                },
                                onChanged: (val) {
                                  if (key == "PAN" || key == "TAN") {
                                    final upper = val.toUpperCase();
                                    if (val != upper) {
                                      _controllers[key]!.value = _controllers[key]!.value.copyWith(
                                        text: upper,
                                        selection: TextSelection.collapsed(offset: upper.length),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 20),

                          // ---------- BUTTONS ----------
                          Row(
                            children: [
                              Expanded(child: 
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: GlobalColors.backgroundColor,
                                      foregroundColor: GlobalColors.mainColor),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: 
                                ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: GlobalColors.mainColor, foregroundColor: Colors.white),
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    setState(() {
                                      companyData.updateAll(
                                          (k, v) => _controllers[k]!.text);
                                    });

                                    final session = SessionManager().getSessionData();

                                    final payload = {
                                      "accountUUID": session?["acctUUID"],
                                      "accountName": session?["userUUID"],
                                      "accountPAN": _controllers["PAN"]?.text ?? "",
                                      "accountTAN": _controllers["TAN"]?.text ?? "",
                                      "accountWebsite": _controllers["Website"]?.text ?? "",
                                      "accountDUNS": _controllers["DUNS"]?.text ?? "",
                                      "accountCompanyType": selectedCompanyType,
                                      "accountIndustry": selectedIndustry ?? "",
                                      "accountVertical": selectedVertical ?? "",
                                    };

                                    try {
                                      final response = await _accountDataService
                                          .updateCompanyData(payload);

                                      if (response.statusCode == 200 ||
                                          response.statusCode == 204) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text("Company Details updated successfully")),
                                        );

                                        final sessionResponse =
                                            await _apiClient.getSessionStarter();

                                        if (sessionResponse.statusCode == 200) {
                                          SessionManager()
                                              .setSessionData(jsonDecode(sessionResponse.body));
                                          await _accountDataService.getAccountData();
                                          _loadCompanyData();
                                        }

                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: ${response.statusCode}")),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Exception: $e")),
                                      );
                                    }
                                  }
                                },
                                child: const Text("Save"),
                              )
                              )
                                                          ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: CommonAppBar(
        title: 'Company Profile',
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: _editAllFields,
            )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: screenWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                border: Border.all(color: GlobalColors.borderColor, width: 1),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: GlobalColors.borderColor, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: companyData.entries.map((e) {
                        bool isLast = e.key == companyData.keys.last;
                        return _buildDetailRow(e.key, e.value, !isLast);
                      }).toList(),
                    ),
                  )
                ]),
              ),
            ),
    );
  }
  bool _containsHtmlTags(String input) {
    if (input.isEmpty) return false;
    final htmlTagRegex = RegExp(r'<[^>]*>');
    return htmlTagRegex.hasMatch(input);
  }
}

Widget _buildDetailRow(String title, String value, bool showDivider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: GlobalColors.textcolor,
          fontSize: 16,
        ),
      ),

      // FIX: force left alignment everywhere
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value.isNotEmpty ? value : "N/A",
          style: const TextStyle(fontSize: 15),
          textAlign: TextAlign.left,
        ),
      ),

      const SizedBox(height: 8),
      if (showDivider) Divider(color: GlobalColors.borderColor),
      const SizedBox(height: 12),
    ],
  );
}
