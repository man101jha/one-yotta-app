import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/address_service/address_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myaccount/screens/modules/profile/kyc.dart';

import 'package:url_launcher/url_launcher.dart';

class AddressView extends StatefulWidget {
  const AddressView({super.key});

  @override
  State<AddressView> createState() => _AddressViewState();
}

class _AddressViewState extends State<AddressView> {
  final AddressService _addressService = AddressService();
  List<Map<String, dynamic>> addresses = [];
  List<Map<String, String>> countryStates = [];
  List<Map<String, dynamic>> countryStateList = [];
  List<String> countries = [];
  Map<String, List<String>> statesByCountry = {};
  String? selectedCountry;
  String? selectedState;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredAddresses = [];
  TextEditingController lutNumberController = TextEditingController();
  TextEditingController lutExpiryController = TextEditingController();
  String? uploadedBase64File;
  String? selectedAddressCrmUid;
  DateTime? selectedLutExpiryDate;
  String? uploadedDocumentName;
  String? selectedDocumentCategory;
  String? selectedDocumentType;
  List<Map<String, dynamic>> availableDocumentTypes = [];
  bool isSezDropdownEnabled = true;
  final AuthService _authService = AuthService();
  bool kycInProcess = false;

  final Map<String, List<Map<String, dynamic>>> documentTypeMap = {
    "Address Proof": [
      {
        "id": 1,
        "type":
            "Current registered lease or license agreement along with utility bill",
      },
      {"id": 2, "type": "Electricity bill"},
      {"id": 3, "type": "GST registration certificate"},
      {"id": 4, "type": "MTNL-BSNL phone line bill"},
      {"id": 5, "type": "Property tax bill"},
      {"id": 6, "type": "Water bill"},
    ],
    "SEZ Address Proof": [
      {"id": 1, "type": "LOA Certificate Address Proof"},
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    fetchCountriesAndStates();
    _checkKYCInProcess();
  }

  Future<void> _checkKYCInProcess() async {
    final accountDataService = AccountDataService();
    final response = await accountDataService.getAccountData();

    final jsonData = json.decode(response.body);
    if (jsonData['accountKYCApprovalStatus'] == 'In-Process') {
      setState(() {
        kycInProcess = true;
      });
    } else {
      setState(() {
        kycInProcess = false;
      });
    }
  }

  Future<void> _fetchAddresses() async {
    try {
      final response = await _addressService.getAddressDetails();
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          addresses =
              data
                  .map(
                    (addr) => {
                      "id": addr["addressUUID"],
                      "address":
                          "${addr["addressLine1"] ?? ''}${addr["addressLine2"] != null ? ", ${addr["addressLine2"]}" : ''}",
                      "city": addr["addressCity"] ?? "",
                      "state": addr["addressState"] ?? "",
                      "country": addr["addressCountry"] ?? "",
                      "pincode": addr["addressPIN"] ?? "",
                      "type": addr["addressType"] ?? "Billing",
                      "GSTIN": addr["addressGSTIN"] ?? "-",
                      "SEZ/Foreign": addr["addressIsSEZ"] == "0" ? "No" : "Yes",
                      "addressCRMUID": addr["addressCRMUID"] ?? "",
                      "addressDocumentRefID":
                          addr["addressDocumentRefID"] ?? "",
                      "Address Status": addr["addressApprovalStatus"] ?? "",
                      "LOA Certificate Number": addr["addressLOANumber"] ?? "",
                      "LOA Expiry Date": addr["addressLOAExpiryDate"] ?? "",
                    },
                  )
                  .toList();

          // Initially, filtered addresses = all addresses
          filteredAddresses = List.from(addresses);
        });
      } else {
        print("Failed to load addresses: \${response.body}");
      }
    } catch (e) {
      print("Error fetching addresses: \$e");
    }
  }

  void filterAddresses(String query) {
    final filtered =
        addresses.where((addr) {
          final addressLower = addr["address"].toString().toLowerCase();
          final cityLower = addr["city"].toString().toLowerCase();
          final stateLower = addr["state"].toString().toLowerCase();
          final countryLower = addr["country"].toString().toLowerCase();
          final queryLower = query.toLowerCase();

          return addressLower.contains(queryLower) ||
              cityLower.contains(queryLower) ||
              stateLower.contains(queryLower) ||
              countryLower.contains(queryLower);
        }).toList();

    setState(() {
      filteredAddresses = filtered;
    });
  }

  void showWarning(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Warning"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> pickAndValidatePdf(
    BuildContext context,
    void Function(void Function()) setModalState,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.extension != 'pdf') {
      showWarning(context, "Please select pdf file for upload");
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      showWarning(
        context,
        "File too large, please select a file smaller than 5 Mb.",
      );
      return;
    }

    final base64File = base64Encode(file.bytes!);

    setModalState(() {
      uploadedDocumentName = file.name;
      uploadedBase64File = base64File;
    });
  }

  Future<void> uploadFile(BuildContext context) async {
    final accountDataService = AccountDataService();
    final response = await accountDataService.getAccountData();

    final jsonData = json.decode(response.body);
    final accountCrmUid = jsonData['accountCRMUUID'];

    try {
      setState(() {
        // isLoading = true;
      });

      final requestBody = {
        "IsDeleted": false,
        "Name": selectedDocumentType,
        "Address": selectedAddressCrmUid,
        "DocumentCategory": "Address Proof",
        "Document": selectedDocumentType,
        "ObjectName": "Address",
        "attachment": uploadedBase64File, // BASE64 PDF
        "Account": accountCrmUid,
      };

      final token = await _authService.getAccessToken();

      final response = await http.post(
        Uri.parse(
          "https://uatmyaccountapi.yotta.com/my_account/api/v1/address/document/upload",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      setState(() {
        // isLoading = false;
      });

      final responseBody = jsonDecode(response.body);

      if (responseBody["Status"] == "Failure") {
        _showAlert(context, "Document upload failed");
        Navigator.pop(context);
      } else {
        _showAlert(context, "Document uploaded successfully");
        Future.delayed(const Duration(seconds: 2), () {
          _fetchAddresses();
          Navigator.pop(context);
        });

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        // isLoading = false;
      });
      _showAlert(context, e.toString());
    }
  }

  void updateDocumentTypes({
    required String? country,
    required String sezValue,
    required void Function(void Function()) setModalState,
    required void Function(String) updateSezValue,
    required void Function(bool) updateSezEnabled,
  }) {
    setModalState(() {
      selectedDocumentType = null;
      availableDocumentTypes = [];

      if (country == null) return;

      if (country != "India") {
        updateSezValue("Yes");
        updateSezEnabled(false);
        availableDocumentTypes = documentTypeMap["Address Proof"]!;
      } else {
        updateSezEnabled(true);

        if (sezValue == "Yes") {
          availableDocumentTypes = documentTypeMap["SEZ Address Proof"]!;
        }
      }
    });
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Message"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> viewAddressDocument(
    BuildContext context,
    String addressCrmUid,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      final sessionData = SessionManager().getSessionData();
      final acctType = sessionData?['acctType'];
      final sto = sessionData?['sto'];
      final bto = sessionData?['bto'];

      final data = {
        "accountNumber": acctType == 'End User' ? sto : bto,
        "docType": "kyc",
      };

      final response = await http.post(
        Uri.parse(
          "https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/kyc/docs",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        _showAlert(context, "Failed to fetch document");
        return;
      }

      final responseBody = jsonDecode(response.body);

      String? documentUrl;

      for (final item in responseBody['documentWrapperList'] ?? []) {
        if (item['recordId'] == addressCrmUid &&
            item['ListofDocumentlink'] != null &&
            item['ListofDocumentlink'].isNotEmpty) {
          documentUrl = item['ListofDocumentlink'][0];
          break;
        }
      }

      if (documentUrl == null) {
        _showAlert(context, "Document not found");
        return;
      }

      final uri = Uri.parse(documentUrl);
      if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        _showAlert(context, "Unable to open document");
      }
    } catch (e) {
      _showAlert(context, e.toString());
    }
  }

  Future<void> fetchCountriesAndStates() async {
    final response = await http.get(
      Uri.parse(
        'https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/countrystates',
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);

      setState(() {
        countryStateList = List<Map<String, dynamic>>.from(jsonData);

        // Group states by country
        statesByCountry.clear();
        for (var item in countryStateList) {
          String country = item["countryName"];
          String state = item["stateName"];

          if (!statesByCountry.containsKey(country)) {
            statesByCountry[country] = [];
          }
          statesByCountry[country]!.add(state);
        }

        countries = statesByCountry.keys.toList();
      });
    } else {
      print('Failed to fetch data: ${response.statusCode}');
    }
  }

  void _editAddress(int index) {
    _showAddressModal(index: index);
  }

  Future<void> _addAddress() async {
    final accountDataService = AccountDataService();
    try {
      final response = await accountDataService.getAccountData();
      if (!mounted) return;
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final kycStatus = jsonData['accountKYCApprovalStatus'];

        if (kycStatus != 'Approved') {
          showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text("Restricted"),
                  content: const Text(
                    "Please complete your KYC to add a new address.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KycView(),
                          ),
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
          return;
        }
      }
    } catch (e) {
      print('Error checking KYC: $e');
    }
    _showAddressModal();
  }

  void _showAddressModal({int? index}) {
    if (index != null) {
      selectedAddressCrmUid = addresses[index]["addressCRMUID"];
    } else {
      selectedAddressCrmUid = null;
    }
    TextEditingController addressController = TextEditingController(
      text: index != null ? addresses[index]["address"] : "",
    );
    TextEditingController cityController = TextEditingController(
      text: index != null ? addresses[index]["city"] : "",
    );
    TextEditingController pincodeController = TextEditingController(
      text: index != null ? addresses[index]["pincode"] : "",
    );
    TextEditingController gstinController = TextEditingController(
      text: index != null ? addresses[index]["GSTIN"] : "",
    );
    TextEditingController lutNumberController = TextEditingController(
      text: index != null ? addresses[index]["LOA Certificate Number"] : "",
    );
    TextEditingController lutExpiryController = TextEditingController(
      text:
          index != null && addresses[index]["LOA Expiry Date"] != null
              ? addresses[index]["LOA Expiry Date"].toString().split(' ').first
              : "",
    );

    String selectedSezForeign =
        index != null ? addresses[index]["SEZ/Foreign"] ?? "No" : "No";

    selectedCountry =
        index != null ? addresses[index]["country"] ?? "India" : "India";

    if (index != null && addresses[index]["state"] != null) {
      final stateObj = countryStateList.firstWhere(
        (s) =>
            s["id"].toString() == addresses[index]["state"].toString() &&
            s["countryName"] == selectedCountry,
        orElse: () => {"stateName": null},
      );
      selectedState = stateObj["stateName"];
    } else {
      selectedState = null;
    }

    if (selectedCountry != null) {
      updateDocumentTypes(
        country: selectedCountry,
        sezValue: selectedSezForeign,
        setModalState: (fn) => fn(),
        updateSezValue: (value) => selectedSezForeign = value,
        updateSezEnabled: (enabled) => isSezDropdownEnabled = enabled,
      );
    }

    // List<String> addressTypes = ["Billing", "Registered", "Shipping", "Office"];
    // Address types list
    final List<String> addressTypes = [
      "Billing",
      "Registered",
      "Shipping",
      "Office",
    ];

    final items =
        addressTypes
            .map((type) => MultiSelectItem<String>(type, type))
            .toList();

    List<String> validInitialTypes = [];
    if (index != null && addresses[index]["type"] != null) {
      final typeValue = addresses[index]["type"];
      List<String> parsedTypes = [];
      if (typeValue is String) {
        parsedTypes =
            typeValue.split(RegExp(r'[;,]')).map((e) => e.trim()).toList();
      } else if (typeValue is List) {
        parsedTypes = typeValue.map((e) => e.toString().trim()).toList();
      }

      for (String t in parsedTypes) {
        if (addressTypes.contains(t)) {
          validInitialTypes.add(t);
        }
      }
    }

    if (validInitialTypes.isEmpty && index != null) {
      validInitialTypes = ["Billing"];
    }

    Set<String> selectedTypes = validInitialTypes.toSet();

    String? addressError;
    String? cityError;
    String? countryError;
    String? stateError;
    String? pincodeError;
    String? typeError;
    String? gstinError;
    String? lutNumberError;
    String? lutExpiryError;

    void validateAddress(String val, Function setModalState) {
      setModalState(() {
        if (val.trim().isEmpty)
          addressError = 'Enter Address';
        else if (val.trim().length > 60)
          addressError = 'Address must not exceeds 60 characters';
        else
          addressError = null;
      });
    }

    void validateCity(String val, Function setModalState) {
      setModalState(() {
        if (val.trim().isEmpty)
          cityError = 'Enter city';
        else if (val.trim().length > 40)
          cityError = 'City must not exceeds 40 characters';
        else if (!RegExp(r'^[A-Za-z ]{0,40}$').hasMatch(val.trim()))
          cityError = 'City must contain only alphabets';
        else
          cityError = null;
      });
    }

    void validatePincode(String val, Function setModalState, String? country) {
      setModalState(() {
        if (val.trim().isEmpty) {
          pincodeError =
              country == "India"
                  ? "Pincode can not be empty or 000000"
                  : "Enter Postal Code";
        } else if (RegExp(r'<[^>]*>|&[a-zA-Z]+;').hasMatch(val.trim())) {
          pincodeError = "HTML tags are not allowed";
        } else if (country == "India") {
          if (!RegExp(r'^[0-9]{6}$').hasMatch(val.trim()))
            pincodeError = "Postal Code must contain 6 digits";
          else if (val.trim() == '000000')
            pincodeError = "Pincode can not be empty or 000000";
          else
            pincodeError = null;
        } else {
          if (!RegExp(r'^[a-zA-Z0-9]{1,10}$').hasMatch(val.trim()))
            pincodeError =
                "Postal Code must contain 10 alpha numeric characters";
          else
            pincodeError = null;
        }
      });
    }

    void validateGstin(String val, Function setModalState) {
      setModalState(() {
        if (val.trim().isEmpty)
          gstinError = null;
        else if (RegExp(r'<[^>]*>|&[a-zA-Z]+;').hasMatch(val.trim()))
          gstinError = "HTML tags are not allowed";
        else if (!RegExp(
          r'^[0-9]{2}([a-zA-Z]){5}[0-9]{4}([a-zA-Z]){1}[0-9]{1}([a-zA-Z]){1}[0-9a-zA-Z]{1}$',
        ).hasMatch(val.trim().toUpperCase()))
          gstinError = "Please enter a valid GSTIN format";
        else
          gstinError = null;
      });
    }

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index != null ? 'Edit Address' : 'Add Address',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Address
                      TextField(
                        controller: addressController,
                        onChanged: (val) => validateAddress(val, setModalState),
                        decoration: InputDecoration(
                          labelText: "Address",
                          border: const OutlineInputBorder(),
                          errorText: addressError,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // City
                      TextField(
                        controller: cityController,
                        onChanged: (val) => validateCity(val, setModalState),
                        decoration: InputDecoration(
                          labelText: "City",
                          border: const OutlineInputBorder(),
                          errorText: cityError,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Country
                      DropdownButtonFormField<String>(
                        value: selectedCountry,
                        decoration: InputDecoration(
                          labelText: "Country",
                          border: const OutlineInputBorder(),
                          errorText: countryError,
                        ),
                        items:
                            (countries.toList()..sort())
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            index != null
                                ? null
                                : (value) {
                                  setModalState(() {
                                    selectedCountry = value;
                                    selectedState = null;
                                    countryError = null;
                                    if (pincodeController.text.isNotEmpty) {
                                      validatePincode(
                                        pincodeController.text,
                                        setModalState,
                                        selectedCountry,
                                      );
                                    }
                                  });
                                  updateDocumentTypes(
                                    country: selectedCountry,
                                    sezValue: selectedSezForeign,
                                    setModalState: setModalState,
                                    updateSezValue:
                                        (value) => selectedSezForeign = value,
                                    updateSezEnabled:
                                        (enabled) =>
                                            isSezDropdownEnabled = enabled,
                                  );
                                },
                      ),
                      const SizedBox(height: 10),

                      // State
                      DropdownButtonFormField<String>(
                        value: selectedState,
                        decoration: InputDecoration(
                          labelText: "State",
                          border: const OutlineInputBorder(),
                          errorText: stateError,
                        ),
                        items:
                            selectedCountry != null &&
                                    statesByCountry[selectedCountry] != null
                                ? (statesByCountry[selectedCountry]!.toList()
                                      ..sort())
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList()
                                : [],
                        onChanged:
                            index != null
                                ? null
                                : (value) => setModalState(() {
                                  selectedState = value;
                                  stateError = null;
                                }),
                      ),
                      const SizedBox(height: 10),

                      // Pincode
                      TextField(
                        controller: pincodeController,
                        onChanged:
                            (val) => validatePincode(
                              val,
                              setModalState,
                              selectedCountry,
                            ),
                        decoration: InputDecoration(
                          labelText: "Pincode",
                          border: const OutlineInputBorder(),
                          errorText: pincodeError,
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 10),

                      // Type
                      MultiSelectDialogField<String>(
                        items: items,
                        initialValue: validInitialTypes,
                        title: const Text("Select Address Type"),
                        buttonText: const Text("Type"),
                        listType: MultiSelectListType.LIST, // or .CHIP
                        onConfirm: (values) {
                          setModalState(() {
                            selectedTypes = values.toSet();
                            validInitialTypes = values;
                          });
                        },
                        chipDisplay: MultiSelectChipDisplay(
                          onTap: (value) {
                            setModalState(() {
                              selectedTypes.remove(value);
                              validInitialTypes.remove(value);
                            });
                          },
                        ),
                      ),
                      if (typeError != null) ...[
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            typeError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // GSTIN
                      TextField(
                        controller: gstinController,
                        onChanged: (val) => validateGstin(val, setModalState),
                        decoration: InputDecoration(
                          labelText: "GSTIN",
                          border: const OutlineInputBorder(),
                          errorText: gstinError,
                        ),
                        enabled: index == null,
                      ),
                      const SizedBox(height: 10),

                      // SEZ/Foreign
                      DropdownButtonFormField<String>(
                        value: selectedSezForeign,
                        decoration: const InputDecoration(
                          labelText: "SEZ/Foreign",
                          border: OutlineInputBorder(),
                        ),
                        items:
                            ["Yes", "No"]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedSezForeign = value!;
                            if (value == "No") {
                              lutNumberController.clear();
                              lutExpiryController.clear();
                              selectedLutExpiryDate = null;
                              uploadedDocumentName = null;
                            }
                            updateDocumentTypes(
                              country: selectedCountry,
                              sezValue: selectedSezForeign,
                              setModalState: setModalState,
                              updateSezValue:
                                  (newValue) => selectedSezForeign = newValue,
                              updateSezEnabled:
                                  (enabled) => isSezDropdownEnabled = enabled,
                            );
                          });
                        },
                      ),
                      if ((selectedSezForeign == "Yes" &&
                          selectedCountry == "India")) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: lutNumberController,
                          onChanged: (val) {
                            setModalState(() {
                              if (val.trim().isEmpty) {
                                lutNumberError =
                                    "Please enter a valid LOA Certificate Number.";
                              } else if (val.trim().length > 50) {
                                lutNumberError =
                                    "LOA Certificate Number must not exceed 50 alphanumeric characters.";
                              } else {
                                lutNumberError = null;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: "LOA Certificate Number",
                            border: const OutlineInputBorder(),
                            errorText: lutNumberError,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: lutExpiryController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "LOA Expiry Date",
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            errorText: lutExpiryError,
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setModalState(() {
                                selectedLutExpiryDate = pickedDate;
                                lutExpiryController.text =
                                    "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                DateTime today = DateTime.now();
                                today = DateTime(
                                  today.year,
                                  today.month,
                                  today.day,
                                );
                                if (pickedDate.isBefore(today)) {
                                  lutExpiryError =
                                      "LOA Expiry Date cannot be in the past.";
                                } else {
                                  lutExpiryError = null;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 170,
                              height: 40,

                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlobalColors.mainColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  // Force re-validation for all fields upon submit click to ensure errors display if they bypassed editing
                                  validateAddress(
                                    addressController.text,
                                    setModalState,
                                  );
                                  validateCity(
                                    cityController.text,
                                    setModalState,
                                  );
                                  validatePincode(
                                    pincodeController.text,
                                    setModalState,
                                    selectedCountry,
                                  );
                                  validateGstin(
                                    gstinController.text,
                                    setModalState,
                                  );

                                  bool hasErr = false;
                                  setModalState(() {
                                    if (selectedCountry == null ||
                                        selectedCountry!.isEmpty) {
                                      countryError = "Select Country";
                                      hasErr = true;
                                    }
                                    if (selectedState == null ||
                                        selectedState!.isEmpty) {
                                      stateError = "Select State";
                                      hasErr = true;
                                    }
                                    if (selectedTypes.isEmpty) {
                                      typeError = "Select Address Type";
                                      hasErr = true;
                                    }

                                    String sezValStr = "2";
                                    if (selectedCountry == "India") {
                                      sezValStr =
                                          selectedSezForeign == "Yes"
                                              ? "1"
                                              : "0";
                                      if (sezValStr == "1") {
                                        if (lutNumberController.text
                                            .trim()
                                            .isEmpty) {
                                          lutNumberError =
                                              "Please enter a valid LOA Certificate Number.";
                                          hasErr = true;
                                        } else if (lutNumberController.text
                                                .trim()
                                                .length >
                                            50) {
                                          lutNumberError =
                                              "LOA Certificate Number must not exceed 50 alphanumeric characters.";
                                          hasErr = true;
                                        } else {
                                          lutNumberError = null;
                                        }

                                        if (selectedLutExpiryDate == null) {
                                          lutExpiryError =
                                              "Please Select LOA Expiry Date";
                                          hasErr = true;
                                        } else {
                                          DateTime today = DateTime.now();
                                          today = DateTime(
                                            today.year,
                                            today.month,
                                            today.day,
                                          );
                                          if (selectedLutExpiryDate!.isBefore(
                                            today,
                                          )) {
                                            lutExpiryError =
                                                "LOA Expiry Date cannot be in the past.";
                                            hasErr = true;
                                          } else {
                                            lutExpiryError = null;
                                          }
                                        }
                                      } else {
                                        lutNumberError = null;
                                        lutExpiryError = null;
                                      }
                                    }
                                  });

                                  if (addressError != null ||
                                      cityError != null ||
                                      pincodeError != null ||
                                      gstinError != null ||
                                      hasErr) {
                                    return; // block form submission if any of the fields show error.
                                  }

                                  int stateId =
                                      selectedState != null
                                          ? countryStateList.firstWhere(
                                                (s) =>
                                                    s["stateName"] ==
                                                        selectedState &&
                                                    s["countryName"] ==
                                                        selectedCountry,
                                                orElse: () => {"id": 0},
                                              )["id"]
                                              as int
                                          : 0;

                                  final addressData = {
                                    "addressLine1": addressController.text,
                                    "addressLine2": "",
                                    "addressCity": cityController.text,
                                    "addressState": stateId.toString(),
                                    "addressCountry": selectedCountry ?? "",
                                    "addressPIN": pincodeController.text,
                                    "addressType": selectedTypes.toList(),
                                    "addressGSTApplicable": 0,
                                    "addressGSTIN":
                                        gstinController.text.isEmpty
                                            ? null
                                            : gstinController.text,
                                    "addressIsSEZ":
                                        selectedSezForeign == "Yes" ? "1" : "0",
                                    "addressLUTNumber":
                                        lutNumberController.text ?? "",
                                    "addressLUTExpiryDate":
                                        selectedLutExpiryDate != null
                                            ? "${selectedLutExpiryDate!.year.toString().padLeft(4, '0')}-"
                                                "${selectedLutExpiryDate!.month.toString().padLeft(2, '0')}-"
                                                "${selectedLutExpiryDate!.day.toString().padLeft(2, '0')}"
                                            : "",
                                    "addressName": "",
                                  };

                                  try {
                                    if (index != null) {
                                      http.Response response =
                                          await _addressService.editAddress(
                                            addressData,
                                            addressId:
                                                index != null
                                                    ? addresses[index]["id"]
                                                    : null,
                                          );
                                      if (response.statusCode == 200 ||
                                          response.statusCode == 201) {
                                        Navigator.pop(context);
                                        _fetchAddresses();
                                      }
                                    } else {
                                      http.Response response =
                                          await _addressService.saveAddress(
                                            addressData,
                                            addressId:
                                                index != null
                                                    ? addresses[index]["id"]
                                                    : null,
                                          );

                                      if (response.statusCode == 200 ||
                                          response.statusCode == 201) {
                                        Navigator.pop(context);
                                        _fetchAddresses();
                                      } else {
                                        print(
                                          "Failed to save address: ${response.body}",
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    print("Error saving address: $e");
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: CommonAppBar(
        title: 'Address',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addAddress,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search Address",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterAddresses,
            ),
            const SizedBox(height: 10),

            // List of Addresses
            Expanded(
              child: ListView.builder(
                itemCount: filteredAddresses.length,
                itemBuilder: (context, index) {
                  final addr = filteredAddresses[index];
                  final bool isEditDisabled =
                      addr["Address Status"] == "Approved" ||
                      addr["Address Status"] == "Submitted for Approval" ||
                      kycInProcess == true;
                  final bool isUploadDisabled =
                      addr["Address Status"] == "Approved" ||
                      addr["Address Status"] == "Submitted for Approval" ||
                      addr["addressCRMUID"] == null ||
                      ((addr["addressDocumentRefID"] ?? "").isNotEmpty &&
                          addr["Address Status"] != "Rejected") ||
                      (addr["Address Status"] == "Approval Required" &&
                          addr["SEZ/Foreign"] == "No") ||
                      (addr["Address Status"] == "Approval Required" &&
                          addr["country"] != "India");
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(addr["address"] ?? ""),
                      subtitle: Text(
                        "${addr["city"]}, ${addr["state"]}, ${addr["country"]} - ${addr["pincode"]}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((addr["addressDocumentRefID"] ?? "").isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Colors.green,
                              ),
                              tooltip: "View Document",
                              onPressed: () {
                                viewAddressDocument(
                                  context,
                                  addr["addressCRMUID"],
                                );
                              },
                            ),
                          if (!isUploadDisabled)
                            IconButton(
                              icon: const Icon(Icons.upload, color: Colors.red),
                              tooltip: "Upload Document",
                              onPressed: () {
                                _showUploadDocumentModal(
                                  addr["addressCRMUID"],
                                  addr["country"],
                                  addr["SEZ/Foreign"],
                                );
                              },
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: isEditDisabled ? Colors.grey : Colors.blue,
                            ),
                            tooltip:
                                isEditDisabled
                                    ? "Editing disabled"
                                    : "Edit Address",
                            onPressed:
                                isEditDisabled
                                    ? null
                                    : () {
                                      final originalIndex = addresses
                                          .indexWhere(
                                            (a) => a["id"] == addr["id"],
                                          );
                                      _editAddress(originalIndex);
                                    },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDocumentModal(
    String addressCrmUid,
    String? country,
    String? sezValue,
  ) {
    uploadedDocumentName = null;
    uploadedBase64File = null;
    selectedDocumentType = null;

    selectedAddressCrmUid = addressCrmUid;
    selectedCountry = country;
    String selectedSezForeignLocal = sezValue ?? "No";

    availableDocumentTypes = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.45,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (availableDocumentTypes.isEmpty) {
                      updateDocumentTypes(
                        country: selectedCountry,
                        sezValue: selectedSezForeignLocal,
                        setModalState: setModalState,
                        updateSezValue: (value) {
                          selectedSezForeignLocal = value;
                        },
                        updateSezEnabled: (enabled) {},
                      );

                      if (availableDocumentTypes.isNotEmpty &&
                          selectedDocumentType == null) {
                        selectedDocumentType =
                            availableDocumentTypes.first["type"];
                      }
                    }
                  });

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Upload Document",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value:
                            availableDocumentTypes.any(
                                  (doc) => doc["type"] == selectedDocumentType,
                                )
                                ? selectedDocumentType
                                : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Document Type",
                          border: OutlineInputBorder(),
                        ),
                        selectedItemBuilder:
                            (context) =>
                                availableDocumentTypes
                                    .map(
                                      (doc) => Text(
                                        doc["type"].toString(),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    )
                                    .toList(),
                        items:
                            availableDocumentTypes
                                .map(
                                  (doc) => DropdownMenuItem<String>(
                                    value: doc["type"].toString(),
                                    child: Text(
                                      doc["type"].toString(),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedDocumentType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: () async {
                          await pickAndValidatePdf(context, setModalState);
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Select File"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),

                      if (uploadedDocumentName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            uploadedDocumentName!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GlobalColors.mainColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                await uploadFile(context);
                              },
                              child: const Text('OK'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
