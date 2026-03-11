import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/button.global.dart';
import 'package:myaccount/widgets/text.form.global.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  Future<Map<String, dynamic>?> callAccountRecoveryAPI(String userEmail) async {
    var apiUrl =
        'https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/user/account-retrieval';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userEmail': userEmail,
        "appUser": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('Account Recovery API response: $data');
        return data;
      } else {
        debugPrint(
            'Account Recovery API error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (error) {
      debugPrint('Account Recovery API error: $error');
      return null;
    }
  }

  void _handleForgotPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email.')));
      return;
    }

    setState(() {
      _isLoading = true;
      _submitted = false;
    });

    final result = await callAccountRecoveryAPI(emailController.text);

    setState(() {
      _isLoading = false;
      _submitted = true;
    });

    if (result != null) {
      final message = result['data'] ??
          "Password reset link sent if email exists.";
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Center(child: Text("Success")),
              content: Text(message),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Go back to Login
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reset link. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/loginbg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: GlobalColors.borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        Center(
                          child: Text(
                            'Forgot Password',
                            style: TextStyle(
                              color: GlobalColors.mainColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Enter your email to reset your password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormGlobal(
                          controller: emailController,
                          text: 'Email',
                          textInputType: TextInputType.emailAddress,
                          obscure: false,
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ButtonGlobal(
                              buttonText: 'Send Reset Link',
                              onTap: _handleForgotPassword),
                        if (_submitted)
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF283E81)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
