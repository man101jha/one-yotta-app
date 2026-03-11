import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myaccount/services/app_services/contact_service/contact_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:html/parser.dart' as html_parser;
// acctUUID
// : 
// "YSu0aE7el4W4XBKk"
// contactUUID
// : 
// "2V6GXBC3oJut6Sg4"
// email
// : 
// "rshakya590@yopmail.com"
// firstName
// : 
// "Testing"
// lastName
// : 
// "Childuser"
// mobileNo
// : 
// "91-7718044485"
// replacementContactUUID
// : 
// "HmAvAeCzSl2GuFrX"
class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class Contact {
  final String uuid; 
  String firstName;
  String lastName;
  String email;
  String countryCode;
  String mobileNumber;
  List<String> type;
  String status; 
  String isDeactivation;
  String? contactUUID; 
  String? acctUUID;    
  String? contactStatus;

  bool isUser;
  Map<String, dynamic>? userInfo;

  Contact({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.countryCode,
    required this.mobileNumber,
    required this.type,
    required this.status,
    required this.isDeactivation,
    this.contactUUID,
    this.acctUUID,
    this.contactStatus,
    this.isUser = false,
    this.userInfo,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    final fullMobile = json['contactMobileNo'] ?? "";
    final parts = fullMobile.split('-');

    // Robust parsing for isAUser
    bool parsedIsUser = false;
    final rawIsUser = json['isAUser'];
    if (rawIsUser is bool) {
      parsedIsUser = rawIsUser;
    } else if (rawIsUser is int) {
      parsedIsUser = rawIsUser == 1;
    } else if (rawIsUser is String) {
      parsedIsUser = rawIsUser == '1' || rawIsUser.toLowerCase() == 'true';
    }

    return Contact(
      uuid: json['contactUUID'] ?? '',
      firstName: json['contactFirstName'] ?? '',
      lastName: json['contactLastName'] ?? '',
      email: json['contactEmail'] ?? '',
      countryCode: parts.length == 2 ? parts[0] : '',
      mobileNumber: parts.length == 2 ? parts[1] : fullMobile,
      type: (json['contactType'] as String? ?? '')
          .split(',')
          .map((e) => e.trim())
          .toList(),
      status: json['contactStatus'] ?? '',
      isDeactivation: json['contactDeactivateStatus'] ?? '',
      contactUUID: json['contactUUID'] ?? '',
      acctUUID: json['accountUUID'] ?? '',
      contactStatus:json['contactStatus'] ??'',
      isUser: parsedIsUser,
      userInfo: json['userInfo'],
    );
  }

  Map<String, dynamic> toJson() => {
        "contactUUID": uuid,
        "contactFirstName": firstName,
        "contactLastName": lastName,
        "contactEmail": email,
        "contactMobileNo": "$countryCode-$mobileNumber",
        "contactType": type.join(','),
        "status": status,
        "isDeactivation": isDeactivation,
        "acctUUID": acctUUID,
        "contactStatus":contactStatus,
        "isAUser": isUser ? 1 : 0,
        "userInfo": userInfo,
      };

  String get portalUserStatus => userInfo != null ? userInfo!['status'] : '-';
  String get portalRole {
    if (userInfo == null || userInfo!['status'] == 'Deactive') return '-';
    final roles = userInfo!['userRoles'];
    if (roles == null) return '-';
    if (roles is List) return roles.join(', ');
    return roles.toString();
  }
}

class _ContactViewState extends State<ContactView> {
  final ContactService _contactService = ContactService();
  List<Contact> contacts = [];
  List<Map<String, dynamic>> contactTypes = [];
  List<String> countryCodeList = []; 
  
    bool isBlurring = false;
    bool isLoading = false;
    String loginUserEmail = '';
    
    TextEditingController _searchController = TextEditingController();
    String _searchQuery = "";

    List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return contacts;
    }
    return contacts.where((contact) {
      final query = _searchQuery.toLowerCase();
      final fullName = "${contact.firstName} ${contact.lastName}".toLowerCase();
      final email = contact.email.toLowerCase();
      final mobile = contact.mobileNumber.toLowerCase();
      
      // Also search in contact types
      final types = contact.type.join(' ').toLowerCase();

      return fullName.contains(query) ||
          email.contains(query) ||
          mobile.contains(query) ||
          types.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    fetchCountriesAndStates();
    final sessionData = SessionManager().getSessionData();
    loginUserEmail = (sessionData?['email'] ?? '').toString().toLowerCase();
  }

  Future<void> _loadData() async {
  setState(() {
    isLoading = true;
  });

  try {
    final contactResponse = await _contactService.getContactDetails();
    final typeResponse = await _contactService.getContactTypeList();

    final List<dynamic> contactList = jsonDecode(contactResponse.body);
    final List<dynamic> typeList = jsonDecode(typeResponse.body);

    setState(() {
      contacts = contactList.map((json) => Contact.fromJson(json)).toList();
      contactTypes = typeList.cast<Map<String, dynamic>>();
    });
  } catch (e) {
    print('Error fetching contact data: $e');
    _showToast('Error loading data');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  List<int> _getSelectedTypeIDs(List<String> selectedTypeNames) {
    return contactTypes
        .where((type) => selectedTypeNames.contains(type['contactTypeName']))
        .map<int>((type) => type['contactTypeID'] as int)
        .toList();
  }

  void _editContact(int index) {
    _showContactModal(index: index);
  }

  void _addContact() {
    _showContactModal();
  }
Future<void> fetchCountriesAndStates() async {
  final response = await http.get(
    Uri.parse('https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/callingcodes'),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = json.decode(response.body);

  setState(() {
  countryCodeList = jsonData
      .map((country) => country['countryCode'].toString())
      .toSet() 
      .toList();
});


    countryCodeList = countryCodeList.toSet().toList();

   
  } else {
    print('Failed to fetch data: ${response.statusCode}');
  }
}
   
  void _showContactModal({int? index}) {
    final isEditing = index != null;
    final contact = isEditing ? _filteredContacts[index] : null;

    final firstNameController = TextEditingController(text: contact?.firstName ?? "");
    final lastNameController = TextEditingController(text: contact?.lastName ?? "");
String selectedCountryCode = contact?.countryCode ?? '91';
final contactNumberController = TextEditingController(text: contact?.mobileNumber ?? "");
    final emailController = TextEditingController(text: contact?.email ?? "");
    List<String> selectedTypes = contact?.type.toList() ?? [];
 
    final _formKey = GlobalKey<FormState>();
 showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (modalContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'Edit Contact' : 'Add Contact',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                 TextFormField(
  controller: firstNameController,
  decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder()),
  validator: (value) {
    if (value == null || value.isEmpty) return "Please enter first name";
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return "Firstname must be alphabetic characters";
    if (_containsHtmlTags(value)) return "HTML tags are not allowed";
    if (value.length < 2 || value.length > 25) return "Firstname must be between 2–25 characters";
    return null;
  },
),
                  const SizedBox(height: 10),
                 TextFormField(
  controller: lastNameController,
  decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder()),
  validator: (value) {
    if (value == null || value.isEmpty) return "Please enter last name";
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return "Lastname must be alphabetic characters";
    if (_containsHtmlTags(value)) return "HTML tags are not allowed";
    if (value.length < 2 || value.length > 25) return "Lastname must be between 2–25 characters";
    return null;
  },
),
                  const SizedBox(height: 10),
              Row(
  children: [
    Expanded(
      flex: 2,
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "Code",
          border: OutlineInputBorder(),
        ),
        value: selectedCountryCode,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedCountryCode = value;
            });
          }
        },
        items: countryCodeList.map((code) {
          return DropdownMenuItem(
            value: code,
            child: Text("+$code"),
          );
        }).toList(),
        validator: (value) => value == null ? 'Select code' : null,
      ),
    ),
    const SizedBox(width: 10),

    // Mobile Number Input
    Expanded(
      flex: 5,
      child: TextFormField(
        controller: contactNumberController,
        decoration: const InputDecoration(
          labelText: "Mobile Number",
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Enter mobile number";
          }
          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
            return "Must be 10 digits";
          }
          return null;
        },
      ),
    ),
  ],
),

                  const SizedBox(height: 10),
                 TextFormField(
  controller: emailController,
  decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
  keyboardType: TextInputType.emailAddress,
  enabled: !isEditing,
  validator: (value) {
    if (value == null || value.isEmpty) return "Please enter email";
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) return "Please enter valid email";
    if (_containsHtmlTags(value)) return "HTML tags are not allowed";
    return null;
  },
),

                  const SizedBox(height: 10),
                  MultiSelectDialogField<String>(
                    items: contactTypes
                        .map((type) => MultiSelectItem<String>(
                            type['contactTypeName'], type['contactTypeName']))
                        .toList(),
                    title: const Text("Select Contact Types"),
                    selectedColor: GlobalColors.mainColor,
                    buttonIcon: const Icon(Icons.arrow_drop_down),
                    buttonText: const Text("Select Contact Types", style: TextStyle(fontSize: 16)),
                    initialValue: selectedTypes,
                    searchable: false,
                    dialogHeight: 300,
                    onConfirm: (values) {
                      selectedTypes = List<String>.from(values);
                    },
                    chipDisplay: MultiSelectChipDisplay(
                      items: selectedTypes.map((e) => MultiSelectItem(e, e)).toList(),
                      onTap: (value) {
                        setState(() {
                          selectedTypes.remove(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        onPressed: isSaving ? null : () => Navigator.pop(modalContext),
                        child: const Text('Cancel'),
                      ),
                     ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.mainColor, foregroundColor: Colors.white),
 onPressed: isSaving ? null : () async {
  if (selectedTypes.isEmpty) {
    ScaffoldMessenger.of(modalContext).showSnackBar(
      const SnackBar(content: Text("Please select contact type")),
    );
    return;
  }

  if (_formKey.currentState?.validate() ?? false) {
    final payload = {
      "firstName": sanitizeName(firstNameController.text),
      "lastName": sanitizeName(lastNameController.text),
      "email": emailController.text,
      "mobileNo": "$selectedCountryCode-${contactNumberController.text}",
      "contactTypes": _getSelectedTypeIDs(selectedTypes),
    };

    // Show loading spinner on Save button
    setModalState(() => isSaving = true);

    try {
      if (isEditing) {
        payload["contactUUID"] = contact!.uuid;
        await _contactService.sendJsonForEditContact(payload);
      } else {
        await _contactService.sendJsonForNewContact(payload);
      }

      // _loadData() re-fetches fresh list from server — no local setState needed
      await _loadData();

      if (modalContext.mounted) Navigator.pop(modalContext);
    } catch (e) {
      setModalState(() => isSaving = false);

      String errorMessage = "Something went wrong";
      try {
        String rawError = e.toString();
        rawError = rawError.replaceFirst(RegExp(r'^Exception:\s*Error:\s*'), '');
        final errorJson = jsonDecode(rawError);
        if (errorJson is Map && errorJson.containsKey("message")) {
          errorMessage = errorJson["message"];
        }
      } catch (_) {}

      if (modalContext.mounted) {
        showDialog(
          context: modalContext,
          builder: (dialogCtx) => AlertDialog(
            title: const Text("Error"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    }
  }
},
 child: isSaving
    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
    : const Text('Save'),
),

                    ],
                  ),
                ],
              ),
            ),
          ),
        );
          },  // closes StatefulBuilder builder
        );    // closes StatefulBuilder widget
      },      // closes showModalBottomSheet builder
    );        // closes showModalBottomSheet call
  }           // closes _showContactModal

  void _managePortalUser(Contact contact) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Manage Portal User",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (contact.isUser && contact.portalUserStatus != 'Deactive')
                 ListTile(
                  leading: const Icon(Icons.manage_accounts, color: Color(0xFF283e81)),
                  title: const Text("Change Portal Role"),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeRoleDialog(contact);
                  },
                ),
              if (contact.isUser && contact.portalUserStatus == 'Active')
                ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text("Revoke Portal User"),
                  onTap: () {
                    Navigator.pop(context);
                    _revokeUser(contact);
                  },
                ),
               if (!contact.isUser && contact.status == 'Active' && contact.portalUserStatus == 'Deactive')
                ListTile(
                  leading: const Icon(Icons.restart_alt, color: Color(0xFF283e81)),
                  title: const Text("Reactivate User"),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddUserDialog(contact, isReactivate: true);
                  },
                ),
                if (!contact.isUser && contact.portalUserStatus != 'Deactive')
                ListTile(
                  leading: const Icon(Icons.person_add, color: Color(0xFF283e81)),
                  title: const Text("Add as Portal User"),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddUserDialog(contact);
                  },
                ),

              if (contact.portalUserStatus == 'NonVerified' || contact.portalUserStatus == 'NonActive')
                ListTile(
                  leading: const Icon(Icons.mail, color: Color(0xFF283e81)),
                  title: const Text("Resend Verification Mail"),
                  onTap: () {
                    Navigator.pop(context);
                    _resendVerificationMail(contact);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddUserDialog(Contact contact, {bool isReactivate = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(isReactivate ? "Reactivate User As" : "Add User As"),
          children: ['Admin', 'Commercial', 'Technology']
              .map((role) => SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      _addUser(contact, role, isReactivate: isReactivate);
                    },
                    child: Text(role),
                  ))
              .toList(),
        );
      },
    );
  }

  void _showChangeRoleDialog(Contact contact) {
     showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Change Portal Role"),
          children: ['Admin', 'Commercial', 'Technology']
              .map((role) => SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      _changeUserRole(contact, role);
                    },
                    child: Text(role),
                  ))
              .toList(),
        );
      },
    );
  }


  Future<void> _addUser(Contact contact, String role, {bool isReactivate = false}) async {
    setState(() => isLoading = true);
    try {
      final payload = {
        "firstName": contact.firstName,
        "lastName": contact.lastName,
        "email": contact.email,
        "mobileNo": contact.mobileNumber,
        "userType": role,
        "accountUUID": contact.acctUUID,
        "from": 'c',
      };

      final response = isReactivate 
          ? await _contactService.reactivateUser(payload)
          : await _contactService.addUser(payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast("User ${isReactivate ? 'Reactivated' : 'Added'}.");
        _loadData();
      } else {
         final err = jsonDecode(response.body);
        _showToast("Error: ${err['message']}");
      }
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _changeUserRole(Contact contact, String role) async {
     setState(() => isLoading = true);
    try {
       final payload = {
      "firstName": contact.userInfo?['userFirstName'],
      "lastName": contact.userInfo?['userLastName'],
      "email": contact.userInfo?['userEmail'],
      "mobileNo": contact.userInfo?['userMobileNo'],
      "userType": role,
      "accountUUID": contact.userInfo?['accountUUID'],
      "userUUID": contact.userInfo?['userUUID']
    };

      final response = await _contactService.editUser(payload);
      if (response.statusCode == 200) {
        _showToast("User role updated.");
        _loadData();
      } else {
         final err = jsonDecode(response.body);
        _showToast("Error: ${err['message']}");
      }
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _revokeUser(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Revoke User"),
        content: const Text("Do you want to revoke all permissions from this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

     setState(() => isLoading = true);
    try {
      final response = await _contactService.revokeUser(contact.userInfo?['userUUID']);
      if (response.statusCode == 200) {
        _showToast("User access revoked.");
        _loadData();
      } else {
        final err = jsonDecode(response.body);
        _showToast("Error: ${err['message']}");
      }
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resendVerificationMail(Contact contact) async {
     setState(() => isLoading = true);
    try {
      final response = await _contactService.resendVerificationMail(contact.userInfo?['userUUID']);
      if (response.statusCode == 200) {
        _showToast("Verification email sent.");
      } else {
        _showToast("Failed to send email.");
      }
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

void _deleteContact(BuildContext context, Map<String, dynamic> contactData) async {
  // Step 1: Blur background (optional)
  setState(() {
     isBlurring = true; // create a bool and wrap your UI with Stack if needed
  });

  // Step 2: Filter the list to show only valid replacements
List<Map<String, dynamic>> filteredList = contacts
    .where((item) =>
        item.status != 'Deactive' &&
        item.status != 'Deactivation in Progress' &&
        item.isDeactivation != 'Deactivated' &&
        item.isDeactivation != 'Deactivation in Progress' &&
        item.uuid != contactData['contactUUID'])
    .map((item) => item.toJson(),
    ) // or toMap()
    .toList();


  // Step 3: Show a dialog for selecting replacement contact
  final selectedReplacement = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return ReplacementContactDialog(contactList: filteredList);
    },
  );

  if (selectedReplacement != null) {
    _confirmContactDelete(context, contactData, selectedReplacement);
  } else {
    setState(() {
      isBlurring = false;
    });
  }
}
void _confirmContactDelete(BuildContext context, Map<String, dynamic> oldContact, Map<String, dynamic> newContact) async {
  bool confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Replace Contact'),
      content: Text(
        'Do you want to replace contact ${oldContact['contactFirstName']} ${oldContact['contactLastName']} '
        'with ${newContact['contactFirstName']} ${newContact['contactLastName']}?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Yes'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() {
      isLoading = true;
    });

    final contactJson = {
      'firstName': oldContact['contactFirstName'],
      'lastName': oldContact['contactLastName'],
      'email': oldContact['contactEmail'],
      'mobileNo': oldContact['contactMobileNo'],
      'replacementContactUUID': newContact['contactUUID'],
      'contactUUID': oldContact['contactUUID'],
      'acctUUID': oldContact['acctUUID'],
    };

    try {
      final response = await _contactService.deactivateContact(contactJson);

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contact replace in progress."),
          ),
        );

      final contactResponse = await _contactService.getContactDetails();

if (contactResponse.statusCode == 200) {
  final decoded = jsonDecode(contactResponse.body);

  // If the API directly returns a list
  if (decoded is List) {
    contacts = decoded.map((json) => Contact.fromJson(json)).toList();
  }

  // OR if it returns a wrapped object like { "contacts": [...] }
  else if (decoded is Map && decoded['contacts'] is List) {
    contacts = (decoded['contacts'] as List)
        .map((json) => Contact.fromJson(json))
        .toList();
  }
}
 else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to refresh contact list")),
            );
          }
        }
      } else {
        final err = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${err['message']}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isBlurring = false;
        });
      }
    }
  } else {
    if (mounted) {
      setState(() {
        isBlurring = false;
      });
    }
  }
}

void _showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
  );
}


  String sanitizeName(String name) {
     name = name.trim();
    if (name.isEmpty) return "";

    // Remove HTML tags (convert to plain text)
    String plainText = html_parser.parse(name).body?.text ?? "";

    plainText = plainText.trim();
    if (plainText.isEmpty) return "";

    return plainText[0].toUpperCase() + plainText.substring(1).toLowerCase();
  }

bool _containsHtmlTags(String input) {
  final htmlTagRegex = RegExp(r'<[^>]*>');
  return htmlTagRegex.hasMatch(input);
}

  // Shimmer loading widget
  Widget _buildShimmerContactList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        border: Border.all(width: 1.0, color: GlobalColors.borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(width: 1.0, color: GlobalColors.borderColor),
                  ),
                  color: Colors.white,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListTile(
                      title: Container(
                        width: 150,
                        height: 16,
                        color: Colors.white,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 200,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 24, height: 24, color: Colors.white),
                          const SizedBox(width: 8),
                          Container(width: 24, height: 24, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: GlobalColors.backgroundColor,
    appBar: CommonAppBar(
      title: 'Contacts',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: _addContact,
        ),
      ],
    ),
   body: isLoading
    ? _buildShimmerContactList()
    : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Contacts',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: GlobalColors.borderColor),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(child: Text("No contacts found"))
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];

          final isInactive = contact.status.toLowerCase() == 'deactive';
          final isDeactivationInProgress = contact.isDeactivation.toLowerCase() == 'deactivation in progress';
          final isDisabled = isInactive || isDeactivationInProgress;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(width: 1.0, color: GlobalColors.borderColor),
            ),
            color: isInactive ? Colors.grey[300] : Colors.white,
            child: ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${contact.firstName} ${contact.lastName}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isInactive ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${contact.countryCode}-${contact.mobileNumber}",
                    style: TextStyle(color: isInactive ? Colors.grey : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Type: ${contact.type.join(', ')}",
                    style: TextStyle(color: isInactive ? Colors.grey : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Portal Role: ${contact.portalRole}",
                    style: TextStyle(color: isInactive ? Colors.grey : Colors.black),
                  ),
                ],
              ),
           trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Edit button
      IconButton(
        icon: Icon(
          Icons.edit,
          color: isDisabled ? Colors.grey : Colors.blue,
          size: 24,
        ),
        onPressed: isDisabled ? null : () => _editContact(index),
        tooltip: "Edit",
      ),

    // Info button for deactivation in progress
    if (isDeactivationInProgress)
      Tooltip(
        message: "Deactivation in progress",
        child: IconButton(
          icon: const Icon(Icons.info, color: Colors.red, size: 24),
          onPressed: null,
        ),
      ),

    // Deactivate button - hidden for logged-in user's own contact
    if (!isDisabled && contact.email.toLowerCase() != loginUserEmail)
      IconButton(
        icon: const Icon(Icons.person_off, color: Colors.red, size: 24),
        onPressed: () => _deleteContact(context, contacts[index].toJson()),
        tooltip: "Contact Deactive",
      ),

    // Add as Portal User - hidden for logged-in user's own contact
    if (!contact.isUser && contact.portalUserStatus != 'Deactive' && !isDisabled && contact.email.toLowerCase() != loginUserEmail)
      IconButton(
        icon: const Icon(Icons.person_add, color: Color(0xFF283e81), size: 24),
        onPressed: () => _showAddUserDialog(contact),
        tooltip: "Add as Portal User",
      ),

    // Reactivate User - hidden for logged-in user's own contact
    if (!contact.isUser && contact.status == 'Active' && contact.portalUserStatus == 'Deactive' && !isDisabled && contact.email.toLowerCase() != loginUserEmail)
      IconButton(
        icon: const Icon(Icons.restart_alt, color: Color(0xFF283e81), size: 24),
        onPressed: () => _showAddUserDialog(contact, isReactivate: true),
        tooltip: "Reactivate User",
      ),

    // Manage Portal User - hidden for logged-in user's own contact
    if (contact.isUser && !isDisabled && contact.email.toLowerCase() != loginUserEmail)
      IconButton(
        icon: const Icon(Icons.manage_accounts, color: Color(0xFF283e81), size: 24),
        onPressed: () => _managePortalUser(contact),
        tooltip: "Manage Portal User",
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
}
class ReplacementContactDialog extends StatefulWidget {
  final List<Map<String, dynamic>> contactList;

  const ReplacementContactDialog({Key? key, required this.contactList}) : super(key: key);

  @override
  _ReplacementContactDialogState createState() => _ReplacementContactDialogState();
}

class _ReplacementContactDialogState extends State<ReplacementContactDialog> {
  late List<Map<String, dynamic>> filteredList;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredList = widget.contactList;
  }



  void _filterContacts(String query) {
    setState(() {
      filteredList = widget.contactList.where((contact) {
        final name = (contact['contactFirstName'] ?? '') + (contact['contactLastName'] ?? '');
        return name.toLowerCase().contains(query.toLowerCase()) ||
               (contact['contactEmail'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
               (contact['contactMobileNo'] ?? '').toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }



  void _clearSearch() {
    searchController.clear();
    _filterContacts('');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Replacement Contact"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              onChanged: _filterContacts,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.close), onPressed: _clearSearch)
                    : null,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Use fixed height here instead of Expanded
            SizedBox(
              height: 250,
              child: filteredList.isEmpty
                  ? const Center(child: Text("No Data Available",style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey,
                              ),))
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final contact = filteredList[index];
                        final fullName = '${contact['contactFirstName']} ${contact['contactLastName']}';
                        return ListTile(
                          title: Text(fullName),
                          subtitle: Text(contact['contactEmail'] ?? ''),
                          trailing: Icon(Icons.published_with_changes, color: Colors.green),
                          onTap: () => Navigator.pop(context, contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
