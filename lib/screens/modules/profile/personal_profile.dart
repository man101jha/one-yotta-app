import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:myaccount/services/app_services/starter_service.dart';

class PersonalProfileView extends StatefulWidget {
  const PersonalProfileView({super.key});

  @override
  State<PersonalProfileView> createState() => _PersonalProfileViewState();
}

class _PersonalProfileViewState extends State<PersonalProfileView> {
  Map<String, String> companyData = {};
  final ApiClient _apiClient = ApiClient();
  final AccountDataService _accountDataClient = AccountDataService();

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    fetchSessionData();
  }

  Future<void> fetchSessionData() async {
    try {
      await _apiClient.getSessionStarter();
    } catch (e) {
      print("Session Load Error: $e");
    }
  }

  // ----------------------------------------------------------
  // LOAD SESSION DATA → POPULATE UI
  // ----------------------------------------------------------
  void _loadSessionData() {
    final session = SessionManager().getSessionData();

    if (session != null) {
      String mobile = session["mobileNo"] ?? "";
      String countryCode = "91";
      String mobileOnly = mobile;

      if (mobile.contains("-")) {
        final parts = mobile.split("-");
        if (parts.length == 2) {
          countryCode = parts[0];
          mobileOnly = parts[1];
        }
      } else if (mobile.length == 10) {
        countryCode = "91";
        mobileOnly = mobile;
      }

      setState(() {
        companyData = {
          "Full Name":
              "${session["firstName"] ?? ""} ${session["lastName"] ?? ""}".trim(),
          "Email": session["email"] ?? "",
          "Country Code": countryCode,
          "Mobile": mobileOnly,
          "Role": (session["userRoles"] is List &&
                  session["userRoles"].isNotEmpty)
              ? session["userRoles"][0]
              : "N/A",
        };
      });
    }
  }

  // ----------------------------------------------------------
  // VALIDATION FUNCTIONS
  // ----------------------------------------------------------
  String? fullNameValidator(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Full name is required";
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(v)) return "Only alphabets allowed";
    if (v.length < 2 || v.length > 25) return "Name must be 2–25 characters";
    return null;
  }

  String? mobileValidator(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return "Mobile number is required";
    if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return "Enter 10 digit number only";
    return null;
  }

  // ----------------------------------------------------------
  // EDIT PROFILE – BOTTOM SHEET
  // ----------------------------------------------------------
  void _editAllFields() {
    final controllers = {
      for (var key in companyData.keys)
        key: TextEditingController(text: companyData[key])
    };

    final formKey = GlobalKey<FormState>();
    bool formValid = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            void validateForm() {
              formValid = formKey.currentState?.validate() ?? false;
              sheetSetState(() {});
            }

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.88,
                builder: (_, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            const Text(
                              "Edit Profile Details",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),

                            // FULL NAME
                            TextFormField(
                              controller: controllers["Full Name"],
                              decoration: const InputDecoration(
                                  labelText: "Full Name",
                                  border: OutlineInputBorder()),
                              validator: fullNameValidator,
                              onChanged: (_) => validateForm(),
                            ),
                            const SizedBox(height: 12),

                            // EMAIL (READ ONLY)
                            TextFormField(
                              controller: controllers["Email"],
                              enabled: false,
                              decoration: const InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),

                            // COUNTRY CODE + MOBILE ROW
                            Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: DropdownButtonFormField<String>(
                                    value: controllers["Country Code"]!.text,
                                    items: ["91", "1", "44", "61", "971"]
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      controllers["Country Code"]!.text = v!;
                                      validateForm();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: "Code",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: TextFormField(
                                    controller: controllers["Mobile"],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Mobile Number",
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: mobileValidator,
                                    onChanged: (_) => validateForm(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ROLE (READ ONLY)
                            TextFormField(
                              controller: controllers["Role"],
                              enabled: false,
                              decoration: const InputDecoration(
                                  labelText: "Role",
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 25),

                            // BUTTONS
                            Row(
                              children: [
                                Expanded(child: 
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: GlobalColors.backgroundColor,),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: GlobalColors.mainColor
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: 
                                  ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: formValid
                                        ? GlobalColors.mainColor
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: formValid
                                      ? () async {
                                          final session =
                                              SessionManager().getSessionData();

                                          final fullName =
                                              controllers["Full Name"]!.text.trim();
                                          final parts = fullName.split(" ");
                                          final firstName = parts.first;
                                          final lastName = parts.length > 1
                                              ? parts.sublist(1).join(" ")
                                              : "";

                                          final country =
                                              controllers["Country Code"]!.text;
                                          final mobile =
                                              controllers["Mobile"]!.text.trim();

                                          final finalMobile =
                                              "$country-$mobile";

                                          final payload = {
                                            "accountUUID": session?["acctUUID"],
                                            "userUUID": session?["userUUID"],
                                            "firstName": firstName,
                                            "lastName": lastName,
                                            "email":
                                                controllers["Email"]!.text.trim(),
                                            "mobileNo": finalMobile,
                                            "userType":
                                                controllers["Role"]!.text.trim(),
                                          };

                                          try {
                                            final res = await _accountDataClient
                                                .updateProfileData(payload);

                                            if (res.statusCode == 200 ||
                                                res.statusCode == 204) {
                                              if (!mounted) return;

                                              final sessionRes =
                                                  await _apiClient.getSessionStarter();
                                              if (sessionRes.statusCode == 200) {
                                                SessionManager().setSessionData(
                                                    jsonDecode(sessionRes.body));
                                              }

                                              setState(() {
                                                companyData["Full Name"] = fullName;
                                                companyData["Country Code"] = country;
                                                companyData["Mobile"] = mobile;
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          "Profile updated successfully")));

                                              Navigator.pop(context);
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                    SnackBar(content: Text("$e")));
                                          }
                                        }
                                      : null,
                                  child:  Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // UI SECTION
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;

    final entries = companyData.entries.toList(); // ensures correct indexing

    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: CommonAppBar(
        title: 'Profile Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _editAllFields,
          ),
        ],
      ),
      body: Container(
        height: screenHeight - appBarHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          border: Border.all(color: GlobalColors.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border.all(color: GlobalColors.borderColor, width: 1.0),
              borderRadius: BorderRadius.circular(10),
            ),

            // LEFT ALIGNMENT FIX APPLIED
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                int index = entry.key;
                var e = entry.value;
                bool isLast = index == entries.length - 1;

                return _buildDetailRow(e.key, e.value, !isLast);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// DETAIL ROW (LEFT-ALIGNED)
// ----------------------------------------------------------
Widget _buildDetailRow(String title, String value, bool showDivider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // LEFT ALIGN
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: GlobalColors.textcolor,
          fontSize: 16,
        ),
      ),
      Text(
        value.isNotEmpty ? value : "N/A",
        style: const TextStyle(fontSize: 15),
      ),
      const SizedBox(height: 8),
      if (showDivider) Divider(color: GlobalColors.borderColor),
      const SizedBox(height: 12),
    ],
  );
}
