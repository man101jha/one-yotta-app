import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myaccount/screens/modules/ticket/ticket_list.dart';
import 'package:myaccount/services/app_services/contact_service/contact_service.dart';
import 'package:myaccount/services/app_services/onboard_service.dart';
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/session/ticket_data_manager.dart';
import 'package:myaccount/services/app_services/ticket_service/ticket_list_service.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:myaccount/screens/modules/profile/contact.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:excel/excel.dart' as ex;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
// import 'dart:html' as html;

class CreateTicketView extends StatefulWidget {
  const CreateTicketView({super.key});

  @override
  State<CreateTicketView> createState() => _CreateTicketViewState();
}

class _CreateTicketViewState extends State<CreateTicketView> {
  final _formKey = GlobalKey<FormState>();
  final _onBehalfOfController = TextEditingController();
  final _onBehalfFocus = FocusNode();
  final _onbehalfKey = GlobalKey<FormFieldState>();
  final _subjectController = TextEditingController();
  final _subjectFocus = FocusNode();
  final _subjectKey = GlobalKey<FormFieldState>();
  final _descriptionController = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _descriptionKey = GlobalKey<FormFieldState>();
  final _categoryController = TextEditingController();
  final _categoryFocus = FocusNode();
  final _categoryKey = GlobalKey<FormFieldState>();
  String? selectedProject;
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedSeverity = 'Low';
  String? selectedDomain;
  List<String> selectedAdditionalContacts = [];
  bool isIncident = false;
  bool isLoading = true;
  bool isServiceRequest = true;
  bool _categoryTouched = false;
  bool isFormValid = false;
  final TicketListService _categoryListClient = TicketListService();
  final TicketListService _ticketDataClient = TicketListService();
  final ContactService _contactService = ContactService();
  final OnboardService _onboardService = OnboardService();
  PlatformFile? selectedFile;
  List<String> domainList = [];
  Map<String, List<String>> categoryList = {};
  Map<String, List<String>> subCategoryList = {};
  List<String> selectedCategoryList = [];
  List<String> selectedSubCategoryList = [];
  List<Map<String, dynamic>> projectList = [];
  List<dynamic> custList = [];
  List<String> projectNameList = [];
  List<String> customerList = [];
  List<String> selectedContactsList = [];
  Map<String, dynamic>? selectedCustomer;
  String? _selectedOnBehalfOf;
  Map<String,dynamic>? userData;
  Map<String,dynamic>? onboardData;
  // Data structures
  Map<String, dynamic> apiDataSR = {
    'category_list': {},
    'sub_category_list': {}
  };
  Map<String, dynamic> apiDataInc = {
    'category_list': {},
    'sub_category_list': {}
  };
  
  List<Map<String, dynamic>>? attachmentData;
  List<Map<String, dynamic>> attachmentArray = [];
  List<PlatformFile> selectedFiles = [];
  List<String> subOptions = ["Option A", "Option B", "Option C"];
  List<String> selectedSubs = [];
  List<Map<String,dynamic>> contactList = [];
  Map<String, String> contactMap = {};
  
  // Domain mapping
  Map<String, String> uiToApiDomainMap = {};
  Map<String, String> apiToUiDomainMap = {};
  List<String> uiDomainList = [];
  bool _isSubmitting = false;
  final quill.QuillController _quillController =
    quill.QuillController.basic();
    final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _subjectFocus.addListener(() {
      if (!_subjectFocus.hasFocus) {
        _subjectKey.currentState?.validate();
      }
    });
    _descriptionFocus.addListener(() {
      if (!_descriptionFocus.hasFocus) {
        _descriptionKey.currentState?.validate();
      }
    });
    _onBehalfFocus.addListener(() {
      if (!_onBehalfFocus.hasFocus) {
        _onbehalfKey.currentState?.validate();
      }
    });
    _categoryFocus.addListener(() {
      if (!_categoryFocus.hasFocus) {
        _categoryKey.currentState?.validate();
      }
    });
    fetchOnboardData();
    getDomainCategorySubCategoryListInc();
    getDomainCategorySubCategoryListServ();
    getProjectList();
    _loadCustomerList();
    // _loadContactList();
  }

  void _loadCustomerList() async {
    processCustomerList();
  }

  // void _loadContactList() async {
  //   final contactdata = await ContactService().getContactDetails();
  //   final List<dynamic> contactJson = json.decode(contactdata.body);
  //   setState(() {
  //     contactList = contactJson.map((c) => Contact.fromJson(c)).toList();
  //     contactList = contactList.where((c) =>
  //     c.contactStatus == 'Active' && onboardData?['email'] != c.email).toList();

  //   });

  //   contactMap = {
  //     for (var c in contactList) "${c.firstName} ${c.lastName}": c.email
  //   };
  // }

   Future<void> fetchOnboardData() async {
    try {
      final onboardResponse = await _onboardService.getOnboardingData();
      if(onboardResponse.statusCode==200){
       onboardData=jsonDecode(onboardResponse.body);
      //  print(onboardData);
      }
    } catch (_) {}
  }

  Future<void> getDomainCategorySubCategoryListInc() async {
    try {
      final response = await TicketDataManager().getCatSubcatData();
      setState(() {
        isLoading = false;
      });

      final result = response?['Result'];
      
      for (final item in result) {
        final domainMap = item['Domain'] as Map<String, dynamic>;
        for (final domain in domainMap.keys) {
          final uiDomain = _mapUiLabel(domain);
          
          // Store mapping
          uiToApiDomainMap[uiDomain] = domain;
          apiToUiDomainMap[domain] = uiDomain;
          
          if (!uiDomainList.contains(uiDomain)) {
            uiDomainList.add(uiDomain);
          }
          
          // Initialize category list for this domain in Incident data
          if (apiDataInc['category_list'][domain] == null) {
            apiDataInc['category_list'][domain] = <String>[];
          }
          
          final domainData = domainMap[domain];
          if (domainData != null) {
            final categoryMap = domainData['Category'] as Map<String, dynamic>;
            for (final category in categoryMap.keys) {
              if (!(apiDataInc['category_list'][domain] as List).contains(category)) {
                (apiDataInc['category_list'][domain] as List).add(category);
              }
              
              // Create key for subcategory
              final key = '$domain:$category';
              if (apiDataInc['sub_category_list'][key] == null) {
                apiDataInc['sub_category_list'][key] = <String>[];
              }
              
              final subCat = domainData['Category'][category]?['SubCategory']
                  ?.map<String>((sc) => sc['Name'] as String)
                  ?.toList();
              if (subCat != null) {
                apiDataInc['sub_category_list'][key] = subCat;
              }
            }
          }
        }
      }
      
      // Sort everything
      uiDomainList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      for (var domain in apiDataInc['category_list'].keys) {
        (apiDataInc['category_list'][domain] as List).sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }

      if (selectedDomain != null && mounted) {
        setState(() {
          final apiDomain = uiToApiDomainMap[selectedDomain];
          final currentData = getCurrentData();
          if (apiDomain != null) {
            selectedCategoryList = List<String>.from(
              currentData['category_list'][apiDomain] ?? [],
            );
          }
        });
      }
      if (mounted && custList.isNotEmpty) {
  _setDefaultCustomer();
}

    } catch (e) {
      print("Error loading Incident data: $e");
    }
  }

  Future<void> getDomainCategorySubCategoryListServ() async {
    try {
      final response = await TicketDataManager().getCatSubDataServRequest();
      setState(() {
        isLoading = false;
      });

      final result = response?['Result'];
      
      for (final item in result) {
        final domainMap = item['Domain'] as Map<String, dynamic>;
        for (final domain in domainMap.keys) {
          final uiDomain = _mapUiLabel(domain);
          
          // Store mapping
          uiToApiDomainMap[uiDomain] = domain;
          apiToUiDomainMap[domain] = uiDomain;
          
          if (!uiDomainList.contains(uiDomain)) {
            uiDomainList.add(uiDomain);
          }
          
          // Initialize category list for this domain in SR data
          if (apiDataSR['category_list'][domain] == null) {
            apiDataSR['category_list'][domain] = <String>[];
          }
          
          final domainData = domainMap[domain];
          if (domainData != null) {
            final categoryMap = domainData['Category'] as Map<String, dynamic>;
            for (final category in categoryMap.keys) {
              if (!(apiDataSR['category_list'][domain] as List).contains(category)) {
                (apiDataSR['category_list'][domain] as List).add(category);
              }
              
              // Create key for subcategory
              final key = '$domain:$category';
              if (apiDataSR['sub_category_list'][key] == null) {
                apiDataSR['sub_category_list'][key] = <String>[];
              }
              
              final subCat = domainData['Category'][category]?['SubCategory']
                  ?.map<String>((sc) => sc['Name'] as String)
                  ?.toList();
              if (subCat != null) {
                apiDataSR['sub_category_list'][key] = subCat;
              }
            }
          }
        }
      }
      
      // Sort everything
      uiDomainList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      for (var domain in apiDataSR['category_list'].keys) {
        (apiDataSR['category_list'][domain] as List).sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }
      
      // Initialize selected domain if not set
      if (selectedDomain == null && uiDomainList.isNotEmpty) {
        setState(() {
          if (uiDomainList.contains("OneYotta")) {
            selectedDomain = "OneYotta";
          } else if (uiDomainList.isNotEmpty) {
            selectedDomain = uiDomainList.first; // fallback
          }
          final apiDomain = uiToApiDomainMap[selectedDomain];
          final currentData = getCurrentData();
          if (apiDomain != null) {
            selectedCategoryList = List<String>.from(
              currentData['category_list'][apiDomain] ?? [],
            );
          }
        });
      }

      if (mounted && custList.isNotEmpty) {
  _setDefaultCustomer();
}

    } catch (e) {
      print("Error loading Service Request data: $e");
    }
  }

  String _mapUiLabel(String value) {
    value = value.trim().toLowerCase();
    if (value == "customer portal") return "OneYotta";
    if (value == "cloud portal") return "Yantraa Cloud";
    if (value == "renderfarm") return "Urja";
    if (value == "shakti cloud") return "Shakti Cloud";
    if (value == "shakti studio") return "Shakti Studio";
    return value;
  }

  // Helper method to get current data
  Map<String, dynamic> getCurrentData() {
    return isIncident ? apiDataInc : apiDataSR;
  }

  Future<void> getProjectList() async {
    try {
      final response = await TicketDataManager().getProjectListData();
      if (response != null &&
          response['Projects'] != null &&
          response['Projects'].isNotEmpty) {
        setState(() {
          projectList = List<Map<String, dynamic>>.from(response['Projects']);
           _categoryListClient.projectList =
              projectList;
          projectNameList = projectList.map((p) => p['Name'] as String).toList();
          final List<Map<String, dynamic>> associateContacts =
              List<Map<String, dynamic>>.from(
                response['Associate_Customer_Contacts'],
              );

          final List<Map<String, dynamic>> callingContacts =
              List<Map<String, dynamic>>.from(
                response['Calling_Customer_Contacts'],
              );

          final List<Map<String, dynamic>> mergedUnique =
              {
                for (final Map<String, dynamic> item in [
                  ...associateContacts,
                  ...callingContacts,
                ])
                  item['ID']: item,
              }.values.toList();

          setState(() {
            contactList =
                mergedUnique
                    .where(
                      (c) =>
                          c['dnd'] == 'No' &&
                          onboardData?['email'] != c['Contact'],
                    ).toList();});

          contactMap = {
            for (final c in contactList) c['Name'].toString(): c['Contact'],
          };

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting project list: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    // withData: true,
    type: FileType.custom,
    allowedExtensions: [
      'jpg',
      'jpeg',
      'png',
      'txt',
      'docx',
      'xlsx',
      'csv',
      'pdf',
      'msg',
    ],
  );

  if (result != null) {
    final file = result.files.single;

    if (file.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size must be less than 5MB')),
      );
      return;
    }

    final bytes = await File(file.path!).readAsBytes();
    // final bytes = file.bytes ??
    // await File(file.path!).readAsBytes();
    final ext = file.extension?.toLowerCase();

  Uint8List processedBytes = Uint8List.fromList(bytes);
    // 🔐 Apply protection only for CSV
    if (ext == 'csv') {
      processedBytes = sanitizeCsvContent(Uint8List.fromList(bytes));
    }
    // 🔐 Basic validation only for XLSX
    if (ext == 'xlsx') {
    processedBytes = sanitizeExcel(Uint8List.fromList(bytes));
    }


    // Other file types → bypass (no changes)
    final base64String = base64Encode(processedBytes);

    String contentType;
    if (ext == 'msg') {
      contentType = 'application/vnd.ms-outlook';
    } else if (ext == 'pdf') {
      contentType = 'application/pdf';
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'png') {
      contentType = 'image/png';
    } else if (ext == 'docx') {
      contentType =
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    } else if (ext == 'xlsx') {
      contentType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (ext == 'csv') {
      contentType = 'text/csv';
    } else if (ext == 'txt') {
      contentType = 'text/plain';
    } else {
      contentType = 'application/octet-stream';
    }

    final attach = {
      'contentType': contentType,
      'filename': file.name,
      'csize': file.size,
      'size': file.size > 1048576
          ? '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'
          : '${(file.size / 1024).toStringAsFixed(2)} KB',
      'content': base64String,
    };

    selectedFiles.add(file);
    attachmentArray.add(attach);

    setState(() {
      attachmentData = attachmentArray;
    });
  }
}



Uint8List sanitizeCsvContent(Uint8List bytes) {
  String content = utf8.decode(bytes, allowMalformed: true);

  // Formula injection protection
  final formulaRegex = RegExp(r'(?<=^|,)\s*"?\s*([=+\-@#])', multiLine: true);

  content = content.replaceAllMapped(formulaRegex, (match) {
    return "'${match.group(0)}";
  });

  // URL protection
  final urlRegex = RegExp(r'(?<=^|,)(\s*)(https?:\/\/|www\.)',
      caseSensitive: false,
      multiLine: true);

  content = content.replaceAllMapped(urlRegex, (match) {
    return "'${match.group(0)}";
  });

  return Uint8List.fromList(utf8.encode(content));
}

void validateExcelFile(List<int> bytes) {
  if (bytes.isEmpty) {
    throw Exception("Invalid Excel file");
  }

  // Optional: basic ZIP signature check for XLSX
  if (!(bytes[0] == 0x50 && bytes[1] == 0x4B)) {
    throw Exception("Corrupted Excel file");
  }
}


Uint8List sanitizeExcel(Uint8List bytes) {
  final oldExcel = ex.Excel.decodeBytes(bytes);
  final newExcel = ex.Excel.createExcel();

  for (var table in oldExcel.tables.keys) {
    final oldSheet = oldExcel.tables[table]!;
    final newSheet = newExcel[table];

    for (int rowIndex = 0; rowIndex < oldSheet.rows.length; rowIndex++) {
      for (int colIndex = 0;
          colIndex < oldSheet.rows[rowIndex].length;
          colIndex++) {

        final cell = oldSheet.rows[rowIndex][colIndex];
        if (cell == null || cell.value == null) continue;

        String value = cell.value.toString().trim();

        // Same logic as Angular
        if (value.isNotEmpty) {
          final dangerousChars = ['=', '+', '-', '@', '#'];

          if (dangerousChars.contains(value[0])) {
            value = "'$value";
          }

          final urlRegex = RegExp(r'^(https?:\/\/|www\.)',
              caseSensitive: false);

          if (urlRegex.hasMatch(value)) {
            value = "'$value";
          }
        }

        // ALWAYS write as plain string into new file
        newSheet
            .cell(ex.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex))
            .value = value.toString();
      }
    }
  }

  // Remove default empty sheet if exists
  if (newExcel.tables.keys.contains('Sheet1') &&
      !oldExcel.tables.keys.contains('Sheet1')) {
    newExcel.delete('Sheet1');
  }

  return Uint8List.fromList(newExcel.encode()!);
}




  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      attachmentData?.removeAt(index);
    });
  }

  void _showSelectedFilesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selected Files'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(file.name),
                    subtitle: Text("${(file.size / 1024).toStringAsFixed(2)} KB"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _removeFile(index);
                        });
                        Navigator.pop(context);
                        _showSelectedFilesDialog();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Create Ticket'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlobalColors.backgroundColor,
          border: Border(
            top: BorderSide(color: GlobalColors.borderColor, width: 1.0),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequestTypeToggle(),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        'On behalf of',
                        customerList,
                        selectedValue: _selectedOnBehalfOf,
                        controller: _onBehalfOfController,
                        focusNode: _onBehalfFocus,
                        fieldKey: _onbehalfKey,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter on behalf of';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedOnBehalfOf = value;
                            _onBehalfOfController.text = value!;
                            Map<String, dynamic>? match;
                            try {
                              match = custList.cast<Map<String, dynamic>>().firstWhere(
                                (item) =>
                                    'Support To: ${item['support_to_customername']} - Bill To: ${item['bill_to_name']}' ==
                                    value,
                              );
                            } catch (_) {
                              match = null;
                            }
                            selectedCustomer = match;
                            _onbehalfKey.currentState?.validate();
                          });
                        },
                      ),
                      _buildDropdown(
                        'Project',
                        projectNameList,
                        onChanged: (value) {
                          setState(() {
                            selectedProject = value;
                          });
                        },
                      ),
                      _buildDomainDropdown(),
                      _buildCategoryDropdown(),
                      _buildSubCategoryDropdown(),
                      _buildDropdownMulti(
                        'Additional Contacts',
                        contactMap.keys.toList(),
                        selectedValues: selectedSubs,
                        onChanged: (values) {
                          setState(() {
                            selectedSubs = values;
                          });
                        },
                      ),
                      _buildTextField(
                        label: 'Subject',
                        controller: _subjectController,
                        focusNode: _subjectFocus,
                        fieldKey: _subjectKey,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Subject is required';
                          } else if (value.trim().length > 70) {
                            return 'Subject must contain only 70 alphabets';
                          }
                          return null;
                        },
                      ),
                      // _buildTextField(
                      //   label: 'Description',
                      //   controller: _descriptionController,
                      //   focusNode: _descriptionFocus,
                      //   fieldKey: _descriptionKey,
                      //   maxLines: 3,
                      //   validator: (value) {
                      //     if (value == null || value.trim().isEmpty) {
                      //       return 'Please enter a description';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      _buildDescriptionEditor(),
                      _buildFilePicker(),
                      const SizedBox(height: 12),
                      if (isIncident)
                        _buildDropdown('Severity', [
                          'Low',
                          'Medium',
                          'High',
                        ], onChanged: (value) => selectedSeverity = value),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        menuMaxHeight: 300,
        value: selectedDomain,
        decoration: InputDecoration(
          labelText: 'Domain',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        items: uiDomainList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value == null) return;
          
          setState(() {
            selectedDomain = value;
            selectedCategory = null;
            selectedSubCategory = null;
            
            // Get API domain value
            final apiDomain = uiToApiDomainMap[value];
            
            // Get categories for selected domain
            final currentData = getCurrentData();
            if (apiDomain != null) {
              selectedCategoryList = List<String>.from(
                currentData['category_list'][apiDomain] ?? [],
              );
            } else {
              selectedCategoryList = [];
            }
            
            selectedSubCategoryList = [];
            _categoryKey.currentState?.validate();
          });
        },
        elevation: 4,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('category-${selectedDomain}-${selectedCategory}'),
        isExpanded: true,
        menuMaxHeight: 300,
        value: selectedCategory,
        focusNode: _categoryFocus,
        decoration: InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        items: selectedCategoryList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value == null) return;
          
          setState(() {
            selectedCategory = value;
            selectedSubCategory = null;
            
            // Get API domain value
            final apiDomain = uiToApiDomainMap[selectedDomain];
            
            // Get subcategories for selected category
            final currentData = getCurrentData();
            if (apiDomain != null && value.isNotEmpty) {
              final key = '$apiDomain:$value';
              selectedSubCategoryList = List<String>.from(
                currentData['sub_category_list'][key] ?? [],
              );
            } else {
              selectedSubCategoryList = [];
            }
            
            _categoryKey.currentState?.validate();
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select a category';
          }
          return null;
        },
        elevation: 4,
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('subcategory-${selectedDomain}-${selectedCategory}-${selectedSubCategory}'),
        isExpanded: true,
        menuMaxHeight: 300,
        value: selectedSubCategory,
        decoration: InputDecoration(
          labelText: 'Sub-category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        items: selectedSubCategoryList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),

        validator: (value) {
        if (value == null || value.trim().isEmpty) {
            return 'Please Select a SubCategory';
          }
          return null;
        },
        onChanged: (String? value) {
          setState(() {
            selectedSubCategory = value;
          });
        },
        elevation: 4,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required GlobalKey<FormFieldState> fieldKey,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options, {
    String? selectedValue,
    TextEditingController? controller,
    FocusNode? focusNode,
    GlobalKey<FormFieldState>? fieldKey,
    String? Function(String?)? validator,
    required Function(String?) onChanged,
  }) {
    final cleanedOptions = options
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    cleanedOptions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        isExpanded: true,
        menuMaxHeight: 300,
        value: cleanedOptions.contains(selectedValue) ? selectedValue : null,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        items: cleanedOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        elevation: 4,
      ),
    );
  }

  Widget _buildDropdownMulti(
    String label,
    List<String> options, {
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    final cleanedOptions = options
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: null,
        menuMaxHeight: 300,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        hint: Text(
          selectedValues.isEmpty ? "Select" : selectedValues.join(", "),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        items: cleanedOptions.map((option) {
          bool isSelected = selectedValues.contains(option);

          return DropdownMenuItem<String>(
            enabled: false,
            value: option,
            child: StatefulBuilder(
              builder: (context, setMenuState) {
                bool localSelected = selectedValues.contains(option);
                return InkWell(
                  onTap: () {
                    if (localSelected) {
                      selectedValues.remove(option);
                    } else {
                      selectedValues.add(option);
                    }

                    setMenuState(() {
                      localSelected = !localSelected;
                    });
                    onChanged(List.from(selectedValues));
                  },
                  child: Row(
                    children: [
                      Icon(
                        localSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(option)),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
        onChanged: (_) {},
      ),
    );
  }

  Widget _buildFilePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _pickFile,
            child: const Text('Select Attachment'),
          ),
          if (selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected files (${selectedFiles.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: _showSelectedFilesDialog,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [isIncident, !isIncident],
          onPressed: (index) {
            final newIsIncident = index == 0;
            
            setState(() {
              isIncident = newIsIncident;
              
              // Reset selections
              selectedCategory = null;
              selectedSubCategory = null;
              
              // If domain is selected, update categories for it
              if (selectedDomain != null) {
                final apiDomain = uiToApiDomainMap[selectedDomain];
                final currentData = getCurrentData();
                
                if (apiDomain != null) {
                  selectedCategoryList = List<String>.from(
                    currentData['category_list'][apiDomain] ?? [],
                  );
                } else {
                  selectedCategoryList = [];
                }
              } else {
                selectedCategoryList = [];
              }
              
              selectedSubCategoryList = [];
            });
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.white,
          fillColor: const Color(0xFF283e81),
          color: Colors.black,
          constraints: const BoxConstraints(minWidth: 150, minHeight: 40),
          children: const [
            Text(
              'Incident',
              style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
            ),
            Text(
              'Service Request',
              style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSubmitButton() {
  List<String> selectedEmails =
      selectedSubs.map((name) => contactMap[name]!).toList();

  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSubmitting
          ? null // disables button
          : () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _isSubmitting = true;
                });

                try {
                  final uuid = Uuid();
                  final id = uuid.v4();
                  final sessionData = SessionManager().getSessionData();
                  final email = sessionData?['email'];
                  final apiDomain = uiToApiDomainMap[selectedDomain];

                  String rawSubject = _subjectController.text.trim();
                  String plainSubject = html_parser
                      .parse(rawSubject)
                      .body
                      ?.text ?? '';

                  // Parse description/message
                  // String rawMessage = _descriptionController.text.trim();
                  // String plainTextMessage = html_parser
                  //     .parse(rawMessage)
                  //     .body
                  //     ?.text ?? '';
                  final delta = _quillController.document.toDelta();

                  final converter = QuillDeltaToHtmlConverter(
                    delta.toJson().cast<Map<String, dynamic>>(),
                    ConverterOptions(),
                  );

                  String htmlMessage = converter.convert();

                  // Validation
                  if (htmlMessage.trim().isEmpty ||
                      htmlMessage == "<p><br></p>") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a description")),
                    );
                    setState(() => _isSubmitting = false);
                    return;
                  }

                  final ticketJson = {
                    "externalSource": "One Yotta",
                    "tClass": "External",
                    "commChannel": "Internal",
                    "commID": "2",
                    "mimeType": "text/html",
                    "externalID": 'OY#$id',
                    "queue": "Service Desk",
                    "state": "Open",
                    "charset": "UTF8",
                    "user": email,
                    "callingCustID": selectedCustomer?['bill_to_sfid'],
                    "associateCustID": selectedCustomer?['support_to_custid'],
                    "billToCRMID": selectedCustomer?['bill_to_sfid'],
                    "supportToCRMID": selectedCustomer?['support_to_custid'],
                    "callingCustName": selectedCustomer?['bill_to_name'],
                    "associateCustName": selectedCustomer?['support_to_customername'],
                    "Additionalcontacts": selectedEmails.join(','),
                    "type": isIncident ? 'Incident' : 'Service Request',
                    "project": selectedProject,
                    "domain": apiDomain ?? '',
                    "category": selectedCategory,
                    "subCategory": selectedSubCategory,
                    "priority": selectedSeverity == 'Low'
                        ? 'S4'
                        : selectedSeverity == 'Medium'
                            ? 'S3'
                            : selectedSeverity == 'High'
                                ? 'S2'
                                : null,
                    "subject": plainSubject,
                    "message": htmlMessage,
                    "assetUAN": [],
                    "attachment": attachmentData ?? []
                  };

                  await createTicket(context, ticketJson);
                } finally {
                  setState(() {
                    _isSubmitting = false;
                  });
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF283e81),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    ),
  );
}

  Future<void> processCustomerList() async {
    await fetchAccounts();

    if (custList.isEmpty) {
    custList = [
      {
        "support_to_cust_sfid": "",
        "support_to_custid": userData?['bto'],
        "support_to_customername":
            onboardData?['accountName'] ?? '',
        "bill_to_name": '-'
      }
    ];
  }

    custList.sort(
      (a, b) => a['support_to_customername']
          .toString()
          .compareTo(b['support_to_customername'].toString()),
    );

    customerList = custList.map((item) {
      return 'Support To: ${item['support_to_customername']} - Bill To: ${item['bill_to_name']}';
    }).toList();
    if (customerList.isNotEmpty) {
    setState(() {
      final defaultCustomer = customerList.first;
      _onBehalfOfController.text = defaultCustomer;
      
      try {
        selectedCustomer = custList.cast<Map<String, dynamic>>().firstWhere(
          (item) =>
              'Support To: ${item['support_to_customername']} - Bill To: ${item['bill_to_name']}' ==
              defaultCustomer,
        );
      } catch (_) {
        selectedCustomer = null;
      }
    });
  }
  _setDefaultCustomer();
  
    setState(() {});
  }

  void _setDefaultCustomer() {
  final sessionData = SessionManager().getSessionData();
  final sto = sessionData?['sto']; // Support To ID
  
  if (sto != null && custList.isNotEmpty) {
    Map<String, dynamic>? matchedCustomer;
    try {
      matchedCustomer = custList.cast<Map<String, dynamic>>().firstWhere(
        (customer) => customer['support_to_custid']?.toString() == sto.toString(),
      );
    } catch (e) {
      matchedCustomer = custList.isNotEmpty ? custList.first : null;
    }
    
    if (matchedCustomer != null) {
      final displayValue = 'Support To: ${matchedCustomer['support_to_customername']} - Bill To: ${matchedCustomer['bill_to_name']}';
      
      setState(() {
        _selectedOnBehalfOf = displayValue; // 🟢 ADD THIS
        _onBehalfOfController.text = displayValue;
        selectedCustomer = matchedCustomer;
      });
    }
  } else if (custList.isNotEmpty) {
    final firstCustomer = custList.first;
    final displayValue = 'Support To: ${firstCustomer['support_to_customername']} - Bill To: ${firstCustomer['bill_to_name']}';
    
    setState(() {
      _selectedOnBehalfOf = displayValue; // 🟢 ADD THIS
      _onBehalfOfController.text = displayValue;
      selectedCustomer = firstCustomer;
    });
  }
}

  Future<void> fetchAccounts() async {
    try {
      final AuthService _authService = AuthService();
      final token = await _authService.getAccessToken();

      if (token == null) {
        throw Exception('Access token not found.');
      }
       final response=AccountDataManager().getAccountStoBtoData();
      if (response!.isNotEmpty) {
        if (response != null && response['support_to_customers'] != null) {
          custList = List<Map<String, dynamic>>.from(response['support_to_customers']);
        }
      }
    } catch (e) {
      print('Error fetching accounts: $e');
    }
  }

  Future<void> createTicket(
      BuildContext context, Map<String, dynamic> ticketData) async {
    try {
      final AuthService _authService = AuthService();
      final token = await _authService.getAccessToken();

      if (token == null) throw Exception('Access token not found.');

      final response = await http.post(
        Uri.parse(
            'https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/create_ticket'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(ticketData),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final resData = jsonDecode(response.body);

        if (resData['TicketID'] != null && resData['TicketNumber'] != null) {
          Future.delayed(const Duration(seconds: 1), () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket Added Successfully.')),
            );
          });

          await _ticketDataClient.getTicketData();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => TicketListView(
                    selectedSeverityFilter: 'all',
                    selectedStatusFilter: 'all')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Something went wrong, Please try again.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error creating ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }


Widget _buildDescriptionEditor() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

            Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        color: Colors.grey.shade100,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child:quill.QuillSimpleToolbar(
          // controller: _quillController, 
          configurations: quill.QuillSimpleToolbarConfigurations(
            controller: _quillController, 
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showAlignmentButtons: true,
            showListBullets: true,
            showListNumbers: true,
            showLink: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showSearchButton: false,
            showListCheck: false,
            showCodeBlock: false,
            multiRowsDisplay: true,
            toolbarSize: 38,
            showDividers: false,
            toolbarIconAlignment: WrapAlignment.start,
            toolbarSectionSpacing: 4, 
          ),
        ),),

        const SizedBox(height: 8),

        Container(
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: quill.QuillEditor(
            focusNode: _focusNode,
            scrollController: ScrollController(),
            configurations: quill.QuillEditorConfigurations(
              controller: _quillController,
              enableInteractiveSelection: true,
              readOnly: false,
              expands: false,
              padding: const EdgeInsets.all(8),
              placeholder: "Enter description here...",
            ),
          ),
        ),
      ],
    ),
  );
}
}