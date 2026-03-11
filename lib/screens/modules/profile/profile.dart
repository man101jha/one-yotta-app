import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:myaccount/screens/modules/profile/address.dart';
import 'package:myaccount/screens/modules/profile/company_profile.dart';
import 'package:myaccount/screens/modules/profile/contact.dart';
import 'package:myaccount/screens/modules/profile/kyc.dart';
import 'package:myaccount/screens/modules/profile/personal_profile.dart';
import 'package:myaccount/screens/view/login.view.dart';

import 'package:myaccount/services/app_services/starter_service.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';

class ApiConfig {
  static const String reportBaseUrl =
      "https://uatmyaccountapi.yotta.com/my_uploads/api/v1";
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  String? accountName;
  String? email;

  bool _isLoading = false;
  bool isKycApproved = true;

  @override
  void initState() {
    super.initState();
    getProfileHeader();
    checkKycStatus();
  }

  void checkKycStatus() async {
    final status = await AccountDataService().isKycApproved();
    setState(() {
      isKycApproved = status;
    });
  }

  /// ------------------------------------------------------------
  /// LOAD PROFILE HEADER
  /// ------------------------------------------------------------
  void getProfileHeader() async {
    final response = await _apiClient.getSessionStarter();
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accountName = data["accountName"];
        email = data["email"];
      });
    }
  }

  /// ------------------------------------------------------------
  /// RESET PASSWORD — Angular → Dart Conversion
  /// ------------------------------------------------------------
  Future<void> resetPassword() async {
    try {
      final session = SessionManager().getSessionData();
      final userUUID = session?["userUUID"];
      final token = await _authService.getAccessToken();
      final sessionData = SessionManager().getSessionData();
      if (userUUID == null) {
        _showMessage("Unable to find user UUID.");
        return;
      }

      final body = jsonEncode({"userUUID": userUUID});

      final url =
          "https://uatmyaccountapi.yotta.com/my_account/api/v1/user/reset-password"; // Angular equivalent

      final res = await http.post(
        Uri.parse(url),
        body: body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        _showSuccessDialog(
          "Email has been sent to registered Email ID to change password.",
        );
      } else {
        _showMessage('${res.statusCode} Failed to send reset email.');
      }
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  /// ------------------------------------------------------------
  /// HELP MANUAL (UUID download logic)
  /// ------------------------------------------------------------
  Future<void> fetchHelpManualList() async {
    setState(() => _isLoading = true);

    try {
      final session = await _apiClient.getSessionStarter();
      final sessionData = jsonDecode(session.body);

      final token = await _authService.getAccessToken();
      final userId = sessionData["userUUID"];

      final apiUrl =
          "${ApiConfig.reportBaseUrl}/report/show/6/$userId?fromDate=19-10-2025&toDate=18-11-2025";

      final res = await http.get(Uri.parse(apiUrl),
        
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final List<dynamic> data = jsonDecode(res.body);
      final filtered = data.where(
        (item) => item["report-display-name"] == "User_Guide_One_Yotta.pdf",
      );

      if (filtered.isEmpty) {
        _showMessage("No User Guide found.");
        return;
      }

      final fileData = filtered.first;
      final fileUUID = fileData["report-file-uuid"];
      final fileName = fileData["report-display-name"];

      await downloadManualByUUID(fileUUID, fileName);
    } catch (e) {
      _showMessage('Error loading user guide.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> downloadManualByUUID(String fileUUID, String fileName) async {
    final url = "${ApiConfig.reportBaseUrl}/report/cht/download/$fileUUID";

    final token = await _authService.getAccessToken();
    try {
      final response = await http.get(
        Uri.parse(url),
        
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(response.bodyBytes);

      await OpenFile.open(file.path);
    } catch (e) {
      _showMessage("Failed to download manual.");
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          alignment: Alignment.center,
          title: const Center(child: Text("Alert")),
          content: Text(msg, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// ------------------------------------------------------------
  /// UI
  /// ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isKycApproved, 
      onPopInvoked: (didPop) {
        if (!didPop) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please complete KYC to access other features."),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBackground(),
            _buildMainContent(context),
            if (_isLoading) _loader(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Profile',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 125, 151, 237), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _avatar(),
          const SizedBox(height: 16),
          _header(),
          const SizedBox(height: 30),
          _menuCard(context),
          const SizedBox(height: 40),
          _logoutButton(),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283e81).withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 50, color: Color(0xFF283e81)),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Text(
          accountName ?? "Loading...",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email ?? "Loading...",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _menuCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _item(
            Icons.person,
            "Personal Details",
            () => _open(context, const PersonalProfileView()),
          ),
          _divider(),

          _item(
            Icons.business,
            "Company Details",
            () => _open(context, const CompanyProfileView()),
          ),
          _divider(),

          _item(
            Icons.location_on,
            "Address",
            () => _open(context, const AddressView()),
          ),
          _divider(),

          _item(
            Icons.contacts,
            "Contacts",
            () => _open(context, const ContactView()),
          ),
          _divider(),

          _item(
              Icons.verified,
               !isKycApproved ? "KYC - Complete KYC" : "KYC", 
              () => _open(context, const KycView()),
               isWarning: !isKycApproved
               ),
          _divider(),

          // _item(Icons.verified, "Switch Account", () => _open(context, const KycView())),
          // _divider(),

          _item(Icons.password, "Reset Password", () => resetPassword()),
          _divider(),

          _item(Icons.help_outline, "Help", () => fetchHelpManualList()),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4)),
      ],
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap, {bool isWarning = false}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF283e81)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isWarning ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _divider() =>
      const Divider(height: 0, thickness: 1, color: Colors.black12);

  Widget _logoutButton() {
    return GestureDetector(
      onTap: () async {
        await _authService.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (_) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF283e81),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.exit_to_app, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loader() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF283e81),
                strokeWidth: 3,
              ),
              SizedBox(height: 12),
              Text(
                'Downloading manual...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  void _open(BuildContext ctx, Widget page) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
  }
}
