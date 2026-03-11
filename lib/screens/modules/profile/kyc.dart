import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/profile/address.dart' show AddressView;
import 'package:myaccount/screens/modules/profile/ekyc.dart';
import 'package:myaccount/screens/modules/profile/profile.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html; // For web
import 'package:flutter/foundation.dart'; // To check if it's web
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/screens/modules/profile/offline_kyc.dart';
import 'package:myaccount/services/app_services/kyc_service/kyc_service.dart';

class KycView extends StatefulWidget {
  const KycView({super.key});

  @override
  State<KycView> createState() => _KycViewState();
}

class _KycViewState extends State<KycView>  with WidgetsBindingObserver {
  String? kycStatus;
  int? kycStatusNo;
  bool isLoading = true;
  List<dynamic> kycDocuments = [];
  final AccountDataService _accountDataService = AccountDataService();
  final KycService _kycService = KycService();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String? selectedFileName;
  PlatformFile? selectedFile;
  String? documentName;
  String? selectedCategory;
  String? selectedDocumentType;
  String? attachedFileBase64;
  String? base64File;
  bool verifyDocs = false;
  TextEditingController documentNameController = TextEditingController();
  dynamic kycDocsApiResponse; 
  Map<String, dynamic>? _accountData;
  bool isStatusLoading = true; 
  bool noLutDoc = false ;
  List<Map<String, dynamic>> ekycTableData = [
    {
      'category': 'ID',
      'documentType': '',
      'documentNumber': '',
      'status': 'pending',
    },
    {
      'category': 'Address',
      'documentType': '',
      'documentNumber': '',
      'status': 'pending',
    },
  ];
  bool showEkycTable = false;
  List<String> ekycSuccessType = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeKycData();
    _kycService.getAddressData();
    _checkV2Verification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkV2Verification();
    }
  }

  Future<void> _checkV2Verification() async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('kyc_clientId');

    if (clientId != null && clientId.isNotEmpty) {
      if (mounted) {
        setState(() => isStatusLoading = true);
      }

      final request = {
        "client_id": clientId,
        "doc_name": "aadhaar"
      };

      try {
        final response = await _kycService.kycV2Verify(request);
        await prefs.remove('kyc_clientId');

        final body = jsonDecode(response.body);
        if (body['status'] != "failure") {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(body['message']?['message'] ?? 'Verification successful')),
             );
           }
           await refreshKycData();
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(body['message']?['message'] ?? 'Verification failed')),
             );
             setState(() => isStatusLoading = false);
           }
        }
      } catch (e) {
        await prefs.remove('kyc_clientId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('V2 Verification Error: $e')),
          );
          setState(() => isStatusLoading = false);
        }
      }
    }
  }

Future<void> _initializeKycData() async {
  try {
    final response = await _accountDataService.getAccountData();
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accountData = data;

      final status = data['accountKYCApprovalStatus'];
      final statusNo = data['accountKYCStatus'];

      setState(() {
        kycStatus = status;
        kycStatusNo = statusNo;
        isStatusLoading = false; 
      });

      await _loadRemainingData();
    } else {
      throw Exception("Failed to fetch KYC status");
    }
  } catch (e) {
    print("Error: $e");
    setState(() {
      isStatusLoading = false;
      isLoading = false;
    });
  }
}

Future<void> _loadRemainingData() async {
  try {
    await Future.wait([
      _kycService.getAddressData(),
      _kycService.getKycDetails(),
      fetchEkycStatus(),
    ]);

    final docsResponse = await _kycService.getKycDocs({});
    kycDocsApiResponse = docsResponse;
    await fetchKycDocsData();
  } catch (e) {
    print("Error fetching remaining data: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> fetchKycDocsData() async {
    try {
    final response = kycDocsApiResponse ?? await _kycService.getKycDocs({});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documents = data['documentWrapperList'] ?? [];

        bool hasIdentity = documents.any(
          (doc) =>
              (doc['Category'] as String?)?.toLowerCase().contains(
                'identity',
              ) ??
              false,
        );

        bool hasAddress = documents.any(
          (doc) =>
              (doc['Category'] as String?)?.toLowerCase().contains('address') ??
              false,
        );

        setState(() {
          kycDocuments = documents;
          isLoading = false;

          // Enable verifyDocs if conditions match
          if ((kycStatus == 'Rejected' ||
                  kycStatus == 'Not-Submitted' ||
                  kycStatus == null) &&
              hasAddress &&
              hasIdentity) {
            verifyDocs = true;
          } else {
            verifyDocs = false;
          }
        });
      } else {
        print("Failed to fetch docs: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

Future<void> fetchEkycStatus() async {
  try {
    final response = await _kycService.getKycDetails();
    if (response.statusCode == 200) {
      final List<dynamic> ekycStatusData = jsonDecode(response.body);

      for (final item in ekycStatusData) {
        for (final row in ekycTableData) {
          if ((row['category'] as String).toLowerCase().contains(
                item['yet_kyc_for'].toString().toLowerCase(),
              ) &&
              item['yet_transaction_status'] == 'success') {
            row['category'] = item['yet_kyc_for'];
            row['documentType'] = item['yet_document_name'];
            row['status'] = item['yet_transaction_status'];
            ekycSuccessType.add(item['yet_document_name'].toLowerCase());
          }
        }
      }

      setState(() {
        showEkycTable = ekycSuccessType.isNotEmpty;
      });
    }
  } catch (e) {
    print('Error fetching eKYC status: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = AppBar().preferredSize.height;
    double containerHeight = screenHeight - appBarHeight;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text(
          'KYC',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF283e81)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF283e81),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isStatusLoading
    ? const Center(child: CircularProgressIndicator())
    : Container(
        width: screenWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: GlobalColors.borderColor,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildKycStatusWidget(),
                ),
                const SizedBox(height: 24),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (kycStatus == 'Pending' ||
                      kycStatus == 'Not-Submitted' ||
                      kycStatus == "Rejected") ...[
                    _buildUploadOptions(),
                    const SizedBox(height: 24),
                  ],
                  if (kycDocuments.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'KYC Documents',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF283e81),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (verifyDocs && kycStatusNo != 3)
                          Center(
                            child: ElevatedButton(
                              onPressed: _submitForVerification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 246, 138, 55),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Submit for Verification'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        ...kycDocuments.map((doc) => _buildDocCard(doc)).toList(),
                      ],
                    ),
                  if (showEkycTable && kycStatusNo == 3) buildEkycTable(),
                ],
              ],
            ),
          ),
        ),
      ),

      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  void showOfflineKycBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const OfflineKycBottomSheet(),
    );

    if (result is Map) {
      setState(() => isLoading = true);
      try {
        final response = await _accountDataService.getAccountData();
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final acctUUID = data['accountCRMUUID'];
          final sessionData = SessionManager().getSessionData();
          final bto = sessionData?['bto'];

          if (acctUUID != null && bto != null) {
            final payload = {
              "IsDeleted": false,
              "Name": result['Name'],
              "Account": acctUUID,
              "AccountNumber": bto,
              "DocumentCategory": result['DocumentCategory'],
              "Document": result['Document'],
              "ObjectName": "Account",
              "attachment": result['attachment'],
            };

            final res = await _kycService.uploadKycDoc(payload);

            if (res.statusCode == 200 || res.statusCode == 204) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('KYC Document uploaded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload failed: ${res.statusCode}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading document: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      
      setState(() => isLoading = false);
      await refreshKycData(); 
    } else {
      fetchKycDocsData();
      _kycService.getAddressData();
      _kycService.getKycDetails();
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter ${label.toLowerCase()}",
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildKycStatusWidget() {
    Widget buildStatusBox(
      Color bgColor,
      IconData icon,
      Color iconColor,
      String message,
    ) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      softWrap: true,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: iconColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    switch (kycStatus) {
      case "Approved":
        return buildStatusBox(
          const Color.fromARGB(255, 209, 249, 224),
          Icons.check_circle,
          const Color.fromARGB(255, 8, 169, 43),
          'KYC is done.',
        );

      case "In-Process":
        return buildStatusBox(
          const Color.fromARGB(255, 225, 245, 234),
          Icons.sync,
          const Color.fromARGB(255, 76, 175, 80),
          'KYC is in-process.',
        );

      case "Rejected":
        return buildStatusBox(
          const Color.fromARGB(255, 239, 222, 255),
          Icons.cancel_outlined,
          const Color.fromARGB(255, 123, 31, 162),
          'KYC is rejected. Please refer to the remark in company profile.',
        );

      case "Pending":
        return buildStatusBox(
          const Color.fromARGB(255, 255, 243, 224),
          Icons.pending_actions,
          const Color.fromARGB(255, 255, 143, 0),
          'KYC is pending. Please verify your documents.',
        );

      case "Not-Submitted":
        return buildStatusBox(
          const Color.fromARGB(255, 255, 204, 204),
          Icons.priority_high,
          const Color(0xFFB00020),
          'Please click on any option to complete KYC.',
        );

      default:
        return const Text(
          'KYC status not available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.grey,
          ),
        );
    }
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final List<dynamic> documentLinks = doc['ListofDocumentlink'] ?? [];
    final bool hasDownloadLink =
        documentLinks.isNotEmpty &&
        documentLinks.first != null &&
        documentLinks.first.toString().isNotEmpty;

    final String? downloadUrl =
        hasDownloadLink ? documentLinks.first.toString() : null;

    return Card(
      color: const Color(0xFFE8F0FE),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.description, color: Color(0xFF283e81)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['Name'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc['Category'] ?? '-',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.download,
                color: hasDownloadLink ? Colors.blue : Colors.grey,
              ),
              onPressed:
                  hasDownloadLink
                      ? () {
                          _launchURL(downloadUrl!);
                        }
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEkycTable() {
    if (!showEkycTable && kycStatus != 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'eKYC Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF283e81),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ekycTableData.length,
            itemBuilder: (context, index) {
              final row = ekycTableData[index];
              final isSuccess = row['status'] == 'success';

              return Card(
                color: const Color(0xFFE8F0FE),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                    color: Color(0xFF283e81),
                  ),
                  title: Text(
                    row['documentType']?.toString().isNotEmpty == true
                        ? row['documentType']
                        : '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${row['category'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Document Number: ${row['documentNumber'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  trailing:
                      isSuccess
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton.icon(
                            onPressed: () {
                              // handle pending verification logic
                            },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Verify'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      print("Could not launch $url");
    }
  }

  Widget _buildUploadOptions() {
    return Column(
      children: [
        if (!showEkycTable)
          _buildUploadCard(Icons.upload_file, "Upload Documents to complete KYC"),
        if (!showEkycTable && kycDocuments.isEmpty) const SizedBox(height: 16),
        if (kycDocuments.isEmpty)
          _buildUploadCard(Icons.fingerprint, "eKYC Option"),
      ],
    );
  }

  Widget _buildUploadCard(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == "Upload Documents to complete KYC") {
          showOfflineKycBottomSheet(context);
        }
        if (label == "eKYC Option") {
          showEKycBottomSheet(context);
        }
      },
      child: Center(
        child: SizedBox(
          height: 160,
          width: 280,
          child: Card(
            color: const Color(0xFFE8F0FE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: const Color(0xFF283e81)),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF283e81),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForVerification() async {
    final response = await _kycService.getAddressData();
    final List<dynamic> data = jsonDecode(response.body);
    final Map<String, dynamic> address = data[0];
    if(address['addressCountry'] == 'India' && ( address['addressIsSEZ'] == '1' && address['addressDocumentRefID'] == null)){
      noLutDoc = true;
    }
  if(noLutDoc){
      showDialog( 
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("Document Required"),
            content: const Text("Please provide LUT Certificate to begin KYC.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); 
                  Future.delayed(const Duration(seconds: 0), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressView(),
                      ),
                    );
                  });
                },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    }else{
    try {
      setState(() => isLoading = true);

    final acctUUID = _accountData?['accountCRMUUID'];
      if (acctUUID == null) {
        throw Exception("accountCRMUUID is missing in response");
      }

      final response = await _kycService.verifyKycDetails(acctUUID);

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Success'),
                content: const Text('KYC documents sent for verification'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 234, 156, 39),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("OK", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
        );
        setState(() => verifyDocs = false);
         await refreshKycData();
      } else {
        throw Exception("Failed to submit KYC. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Verification error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
    }
  }
  Future<void> refreshKycData() async {
  setState(() {
    isLoading = true;
    isStatusLoading = true;
  });

  await _initializeKycData(); 
   }

}
