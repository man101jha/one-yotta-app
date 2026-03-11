import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myaccount/screens/pages/dashboard.view.dart';
import 'package:myaccount/screens/modules/profile/kyc.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/kyc_service/kyc_service.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/starter_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showEKycBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const EKycStepper(),
  );
}

class EKycStepper extends StatefulWidget {
  const EKycStepper({super.key});

  @override
  State<EKycStepper> createState() => _EKycStepperState();
}

class _EKycStepperState extends State<EKycStepper> {
  int _currentStep = 0;
  String _selectedOption = '';
  String _selectedProof = '';
  final TextEditingController _proofController = TextEditingController();
  final TextEditingController _docNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  final RegExp _panRegex = RegExp(r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]{1}$');
  final RegExp _gstinRegex = RegExp(
    r'^[0-9]{2}[A-Za-z]{5}[0-9]{4}[A-Za-z]{1}[0-9]{1}[A-Za-z]{1}[0-9A-Za-z]{1}$',
  );
  final RegExp _aadhaarRegex = RegExp(r'^[0-9]{12}$');
  final AccountDataService _accountDataService = AccountDataService();
  final KycService _kycService = KycService();
  final ApiClient _apiClient = ApiClient();
  String? acctUUID;
  String? userUUID;
  bool isLoading = false;
  bool otpSent = false;
  Map<String, dynamic>? kycInitData;
  int otpTimer = 120;
  Timer? countdownTimer;
  bool isCompanyAccount = false;
  bool _accountTypeFetched = false;
  Timer? _resendTimer;
  String? mobileNumber;
  Map<String, dynamic>? otpApiResponse;
  String otp = '';
  bool isDocValid = false;
  bool isAccIndian = true;
  bool isResendEnabled = false;
  @override
  void initState() {
    super.initState();
    fetchAccountData();
    checkIfCompanyAccount();
  }

  Future<void> fetchAccountData() async {
    try {
      final response = await _accountDataService.getAccountData();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        acctUUID = data['accountUUID'];

        final sessionData = await SessionManager().getSessionData();
        userUUID = sessionData?['userUUID'];
      }
    } catch (e) {
      debugPrint('Error fetching account data: $e');
    }
  }

  void checkIfCompanyAccount() async {
    final response = await _apiClient.getSessionStarter();

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      isCompanyAccount = data['accountIsCompany'] != 0;
      _accountTypeFetched = true;

      setState(() {});
    } else {
      print("Failed to fetch data: ${response.statusCode}");
    }
  }

  void checkIsAccIndian() async {
    final response = await _kycService.getAddressData();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List<dynamic> addressList = data is List ? data : [data];

      bool foundNonIndianBilling = false;

      for (var item in addressList) {
        final addressType = item['addressType']?.toString() ?? '';
        final addressCountry = item['addressCountry']?.toString() ?? '';

        if (addressType.contains('Billing') && addressCountry != 'India') {
          foundNonIndianBilling = true;
          break;
        }
      }

      setState(() {
        isAccIndian = !foundNonIndianBilling;
      });
    } else {
      setState(() {
        isAccIndian = true;
      });
      print('Failed to fetch address data: ${response.statusCode}');
    }
  }

  bool isOtpValid() {
    return (_selectedProof == 'gstin' && otp.length == 4) ||
        (_selectedProof != 'gstin' && otp.length == 6);
  }

  Future<void> proceedKycV2Init(Map<String, dynamic> request) async {
    setState(() => isLoading = true);

    try {
      final response = await _kycService.kycV2Init(request);
      setState(() => isLoading = false);

      debugPrint("KYC V2 Response: ${response.body}");

      Map<String, dynamic> body;
      try {
        body = json.decode(response.body);
      } catch (e) {
        showErrorDialog("Invalid response from server.");
        return;
      }

      final messageMap = body['message'];
      if (messageMap != null && messageMap['message'] != null) {
        final messageContent = messageMap['message'];
        
        final clientId = messageContent['client_id'];
        if (clientId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('kyc_clientId', clientId);
        }

        final urlStr = messageContent['url'];
        if (urlStr != null) {
          final url = Uri.parse(urlStr);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.inAppBrowserView);
          } else {
            debugPrint("Could not launch $urlStr");
          }
        }
      }

      if (body['status'] == 'pending') {
        final docName = request['doc_name'];
        if (docName == 'pan') {
          showSuccessDialog("PAN verification completed successfully.");
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const KycView()),
            );
          }
        } else {
          Navigator.pop(context, 'v2_init');
        }
      } else {
         showErrorDialog(getErrorMessage(body['message']));
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog("Something went wrong! Please try again later.");
    }
  }

  Future<void> proceedKycInit(Map<String, dynamic> request) async {
    setState(() => isLoading = true);

    try {
      final response = await _kycService.kycInit(request);
      setState(() => isLoading = false);

      debugPrint("KYC Response: ${response.body}");

      Map<String, dynamic> body;
      try {
        body = json.decode(response.body);
      } catch (e) {
        showErrorDialog("Invalid response from server.");
        return;
      }

      if (body['status'] == 'success') {
        final docName = request['doc_name'];
        final message = body['message'];
        kycInitData = message;

        if (docName == 'pan') {
          showSuccessDialog("PAN verification completed successfully.");
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardView()),
            );
          }
        } else if (docName == 'credit_card') {
          final encRequest = message['encRequest'];
          final accessCode = message['accessCode'];
          final merchantId = message['merchantId'];

          final url = Uri.parse(
            'https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction'
            '&merchant_id=$merchantId'
            '&access_code=$accessCode'
            '&encRequest=$encRequest',
          );

          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.inAppBrowserView);
          } else {
            showErrorDialog("Could not launch CCAvenue.");
          }
        } else if (docName == 'aadhaar' || docName == 'gstin') {
          setState(() {
            otpSent = true;
            _currentStep = 2;
            mobileNumber = message['mobileNo'];
          });
          startOtpCountdown();
        }
      } else {
        showErrorDialog(getErrorMessage(body['message']));
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog("Something went wrong! Please try again later.");
    }
  }

  void startCountdown() {
    otpTimer = 120;
    otpSent = true;

    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        otpTimer--;
        if (otpTimer <= 0) {
          timer.cancel();
          otpSent = false;
          otpTimer = 0;
        }
      });
    });
  }

  void _showInfoDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_accountTypeFetched) {
      return const Center(child: CircularProgressIndicator());
    }

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.9,
      minChildSize: 0.6,
      initialChildSize: 0.6,
      builder:
          (context, scrollController) => Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 32,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidateMode,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stepper(
                      physics: const NeverScrollableScrollPhysics(),
                      currentStep: _currentStep,
                      onStepContinue: _onStepContinue,
                      onStepCancel: _onStepCancel,
                      controlsBuilder: (context, details) {
                        if (_currentStep == 2) {
                          // On OTP step, hide Stepper's default buttons,
                          // because you already have Back & Verify OTP inside step content.
                          return const SizedBox.shrink();
                        }

                        final isStep1 = _currentStep == 1;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text("Back"),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  isStep1 && !isDocValid
                                      ? null
                                      : details.onStepContinue,
                              child: Text(
                                _currentStep == 2 ? "Finish" : "Next",
                              ),
                            ),
                          ],
                        );
                      },
                      steps: [
                        Step(
                          title: const Text("Select Option"),
                          isActive: _currentStep >= 0,
                          content: Column(
                            children: [
                              if (isAccIndian)
                                RadioListTile<String>(
                                  title: const Text("ID / Address Proof"),
                                  value: 'id_proof',
                                  groupValue: _selectedOption,
                                  onChanged:
                                      (value) => setState(() {
                                        _selectedOption = value!;
                                      }),
                                ),
                              RadioListTile<String>(
                                title: Row(
                                  children: [
                                    const Expanded(
                                      child: Text("Credit / Debit Card"),
                                    ),
                                    GestureDetector(
                                      onTap:
                                          () => _showInfoDialog(
                                            context,
                                            "To verify your KYC you will be charged 1 INR, which will be refunded in 2-3 business days.",
                                          ),
                                      child: const Icon(Icons.info_outline),
                                    ),
                                  ],
                                ),
                                value: 'card',
                                groupValue: _selectedOption,
                                onChanged:
                                    (value) => setState(() {
                                      _selectedOption = value!;
                                    }),
                              ),
                            ],
                          ),
                        ),
                        Step(
                          title: const Text("Select Proof"),
                          isActive: _currentStep >= 1,
                          content:
                              _selectedOption == 'card'
                                  ? const SizedBox.shrink()
                                  : Column(
                                    children: [
                                      if (_accountTypeFetched &&
                                          isCompanyAccount) ...[
                                        _buildProofRadio(
                                          title: "Company PAN",
                                          value: 'pan',
                                          info:
                                              "For the ID verification, kindly provide your company’s PAN number",
                                        ),
                                        _buildProofRadio(
                                          title: "GSTIN",
                                          value: 'gstin',
                                          info:
                                              "For address verification, kindly provide the Goods & Services Tax Identification Number (GSTIN)",
                                        ),
                                      ] else if (_accountTypeFetched &&
                                          !isCompanyAccount) ...[
                                        _buildProofRadio(
                                          title: "PAN",
                                          value: 'pan',
                                          info:
                                              "For the ID verification, kindly provide PAN number",
                                        ),
                                        _buildProofRadio(
                                          title: "Aadhaar",
                                          value: 'aadhaar',
                                          info:
                                              "For both address and ID verification, kindly provide the Aadhar number",
                                        ),
                                      ],
                                      if (_selectedProof == 'pan' ||
                                          _selectedProof == 'gstin' ||
                                          _selectedProof == 'aadhaar') ...[
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _docNumberController,
                                          decoration: const InputDecoration(
                                            labelText: 'Document Number',
                                            border: OutlineInputBorder(),
                                            errorMaxLines: 3,
                                          ),
                                          autovalidateMode: _autoValidateMode,
                                          onChanged: (value) {
                                            if (_autoValidateMode ==
                                                AutovalidateMode.disabled) {
                                              _autoValidateMode =
                                                  AutovalidateMode.always;
                                            }

                                            final isValid =
                                                (_selectedProof == 'pan' &&
                                                    _panRegex.hasMatch(
                                                      value,
                                                    )) ||
                                                (_selectedProof == 'gstin' &&
                                                    _gstinRegex.hasMatch(
                                                      value,
                                                    )) ||
                                                (_selectedProof == 'aadhaar' &&
                                                    _aadhaarRegex.hasMatch(
                                                      value,
                                                    ));

                                            setState(
                                              () => isDocValid = isValid,
                                            );
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'This field is required';
                                            }
                                            if (_selectedProof == 'pan' &&
                                                !_panRegex.hasMatch(value)) {
                                              return 'PAN must be in format: 5 alphabets, 4 digits, 1 alphabet';
                                            }
                                            if (_selectedProof == 'gstin' &&
                                                !_gstinRegex.hasMatch(value)) {
                                              return 'GSTIN must be in format: 2 digits, 5 alphabets, 4 digits, 1 alphabet, 1 digit, 1 alphabet, 1 alphanumeric';
                                            }
                                            if (_selectedProof == 'aadhaar' &&
                                                !_aadhaarRegex.hasMatch(
                                                  value,
                                                )) {
                                              return 'Aadhaar must be 12 digits';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                        ),
                        Step(
                          title: const Text("OTP Verification"),
                          isActive: _currentStep >= 2,
                          content:
                              otpSent
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enter the OTP sent on registered mobile number ${maskMobileNumber(mobileNumber)}.',
                                      ),
                                      const SizedBox(height: 16),
                                      OTPTextField(
                                        length:
                                            _selectedProof == 'gstin' ? 4 : 6,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        fieldWidth: 40,
                                        style: const TextStyle(fontSize: 17),
                                        textFieldAlignment:
                                            MainAxisAlignment.spaceAround,
                                        fieldStyle: FieldStyle.box,
                                        onCompleted: (String verificationCode) {
                                          handleOtp(verificationCode);
                                        },
                                      ),
                                      if (otpApiResponse?['status'] ==
                                          'failure')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            otpApiResponse?['message']?['message'] ??
                                                '',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            onPressed:
                                                () => setState(
                                                  () => _currentStep = 1,
                                                ),
                                            child: const Text("Back"),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            onPressed:
                                                isOtpValid() ? submitOtp : null,
                                            child: const Text("Verify OTP"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  String maskMobileNumber(String? number) {
    if (number == null || number.length < 10) return '';
    return '${number.substring(0, 2)}******${number.substring(number.length - 2)}';
  }

  void handleOtp(String otpValue) {
    setState(() => otp = otpValue);
  }

  void startOtpCountdown() {
    setState(() {
      isResendEnabled = false;
      otpTimer = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        otpTimer--;
        if (otpTimer == 0) {
          isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Widget buildOtpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Enter the OTP sent to your registered mobile"),
        const SizedBox(height: 16),
        OTPTextField(
          length: 6,
          width: MediaQuery.of(context).size.width,
          fieldWidth: 40,
          style: const TextStyle(fontSize: 17),
          textFieldAlignment: MainAxisAlignment.spaceAround,
          fieldStyle: FieldStyle.box,
          onChanged: (String code) {},
          onCompleted: (String verificationCode) {
            handleOtpSubmit(verificationCode);
          },
        ),
        const SizedBox(height: 20),
        isResendEnabled
            ? TextButton(onPressed: resendOtp, child: const Text("Resend OTP"))
            : Text("Resend in $otpTimer seconds"),
      ],
    );
  }

  void handleOtpSubmit(String code) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("OTP Submitted: $code")));
  }

  void resendOtp() {
    startOtpCountdown();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP resent.")));
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedOption == 'card') {
        final request = {
          'doc_name': 'credit_card',
          'user_uuid': userUUID,
          'acc_uuid': acctUUID,
        };

        setState(() => isLoading = true);

        proceedKycInit(request).then((_) {
          setState(() => isLoading = false);
          if (mounted) {
            setState(() => _currentStep = 2);
          }
        });
      } else {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        if (_selectedProof == 'aadhaar') {
          final sessionData = SessionManager().getSessionData();
          final String mobileNumber = sessionData?['mobileNo'] ?? '';
          
          final request = {
            'doc_name': _selectedProof,
            'doc_number': _docNumberController.text.trim().toUpperCase(),
            'user_uuid': userUUID,
            'acc_uuid': acctUUID,
            'mobileNo': mobileNumber,
          };
          
          proceedKycV2Init(request);
        } else {
          final request = {
            'doc_name': _selectedProof,
            'doc_number': _docNumberController.text.trim().toUpperCase(),
            'user_uuid': userUUID,
            'acc_uuid': acctUUID,
          };

          setState(() => isLoading = true);

          proceedKycInit(request).then((_) {
            setState(() => isLoading = false);
            if (mounted) {
              setState(() => _currentStep = 2);
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Widget _buildProofRadio({
    required String title,
    required String value,
    required String info,
  }) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: Text(title),
            value: value,
            groupValue: _selectedProof,
            onChanged: (val) {
              setState(() {
                _selectedProof = val!;
                _docNumberController.clear();
              });
            },
          ),
        ),
        GestureDetector(
          onTap: () => _showInfoDialog(context, info),
          child: const Icon(Icons.info_outline),
        ),
      ],
    );
  }

  Future<void> submitOtp() async {
    setState(() => isLoading = true);

    final request = {
      "client_id": kycInitData?["client_id"],
      "otp": otp,
      "doc_name": _selectedProof,
    };

    try {
      final response = await _kycService.verifyOtp(request);
      final Map<String, dynamic> body = json.decode(response.body);
      otpApiResponse = body;

      if (body['status'] != 'failure') {
        final message =
            body['message']?['message'] ?? 'OTP verified successfully';
        await showSuccessDialog(message);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
      } else {
        final errorMessage =
            body['message']?['message'] ?? "OTP verification failed";
        await showErrorDialog(errorMessage);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KycView()),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("OTP Verification failed: $e\n$stackTrace");
      await showErrorDialog("Something went wrong during OTP verification.");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycView()),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> showSuccessDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Success',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
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
      },
    );
  }

  Future<void> showErrorDialog(String message) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
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
      },
    );
  }

  String getErrorMessage(dynamic message) {
    if (message is String) return message;
    if (message is Map && message.containsKey('message')) {
      return message['message'];
    }
    return 'Something went wrong, Please try again.';
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }
}
