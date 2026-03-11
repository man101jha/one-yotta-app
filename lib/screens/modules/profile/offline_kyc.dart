import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/kyc_service/kyc_service.dart';

class OfflineKycBottomSheet extends StatefulWidget {
  const OfflineKycBottomSheet({super.key});

  @override
  State<OfflineKycBottomSheet> createState() => _OfflineKycBottomSheetState();
}

class _OfflineKycBottomSheetState extends State<OfflineKycBottomSheet> {
  final TextEditingController documentNameController = TextEditingController();
  final AccountDataService _accountDataService = AccountDataService();
  final KycService _kycService = KycService();

  String? selectedCategory;
  String? selectedDocumentType;
  String? selectedFileName;
  PlatformFile? selectedFile;
  String? base64File;
  bool isSubmitting = false;

  final Map<String, List<Map<String, dynamic>>> documentTypes = {
    "Identity Proof": [
      {"id": 1, "type": "Aadhar"},
      {"id": 2, "type": "Business Commencement Certificate"},
      {"id": 3, "type": "Certificate of Registration"},
      {
        "id": 4,
        "type":
            "Declaration on the letter head enlisting all partners names with their inclusion date",
      },
      {
        "id": 5,
        "type":
            "Domicile certificate with address issued by municipal corporation",
      },
      {"id": 6, "type": "Driving license"},
      {
        "id": 7,
        "type":
            "Duly executed partnership deed (as amended and updated upto date)",
      },
      {"id": 8, "type": "GST registration certificate"},
      {"id": 9, "type": "MSME certificate (if registered)"},
      {"id": 10, "type": "PAN Card"},
      {"id": 11, "type": "Passport"},
      {"id": 12, "type": "Registered deed (as amended and updated upto date)"},
      {"id": 13, "type": "Registration Certificate"},
      {
        "id": 14,
        "type":
            "Registration Certificate/Notification/Circular/Gazette for institution formation",
      },
      {
        "id": 15,
        "type":
            "Registration Certificate (if any) under Banking Companies Act 1949",
      },
      {"id": 16, "type": "ROC issued CIN"},
      {"id": 17, "type": "SEBI registration certificate"},
      {"id": 18, "type": "Shops and establishment Certificate"},
      {
        "id": 19,
        "type": "Shops and establishment Certificate issued by local self Govt",
      },
      {"id": 20, "type": "Voter id"},
    ],
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
  };

  @override
  Widget build(BuildContext context) {
    final List<String> typeOptions =
        selectedCategory != null
            ? documentTypes[selectedCategory]!
                .map((e) => e['type'].toString())
                .toList()
            : [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        initialChildSize: 0.5,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Upload KYC Document',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Document Name
                  TextFormField(
                    controller: documentNameController,
                    decoration: const InputDecoration(
                      labelText: "Document Name",
                      hintText: "Enter document name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Document Category",
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ["Identity Proof", "Address Proof"]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        selectedDocumentType = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type Dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedDocumentType,
                    decoration: const InputDecoration(
                      labelText: "Document Type",
                      border: OutlineInputBorder(),
                    ),
                    items:
                        typeOptions
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDocumentType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // File Picker
                  Tooltip(
                    message: 'Select PDF file only. Max file size 5 Mb',
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );

                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;

                          if (file.size > 5 * 1024 * 1024) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'File size exceeds 5MB. Please select a smaller file.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            Uint8List? bytes = file.bytes;
                            if (bytes == null && file.path != null) {
                              bytes = await File(file.path!).readAsBytes();
                            }

                            if (bytes != null) {
                              final base64String = base64Encode(bytes);
                              setState(() {
                                selectedFile = file;
                                selectedFileName = file.name;
                                base64File = base64String;
                              });
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(selectedFileName ?? "Choose File"),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            (!isSubmitting &&
                                    selectedCategory != null &&
                                    selectedDocumentType != null &&
                                    selectedFile != null &&
                                    documentNameController.text
                                        .trim()
                                        .isNotEmpty &&
                                    base64File != null)
                                ? () {
                                    setState(() {
                                      isSubmitting = true;
                                    });
                                    final payloadFromForm = {
                                      "Name": documentNameController.text.trim(),
                                      "DocumentCategory": selectedCategory,
                                      "Document": selectedDocumentType,
                                      "attachment": base64File,
                                    };
                                    Navigator.of(context).pop(payloadFromForm);
                                  }
                                : null,

                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
