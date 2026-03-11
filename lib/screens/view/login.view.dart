import 'package:flutter/material.dart';
import 'package:myaccount/screens/pages/dashboard.view.dart';
import 'package:myaccount/screens/pages/main_wrapper.dart';
import 'package:myaccount/screens/view/msa.dart';
import 'package:myaccount/screens/view/onboarding.view.dart';
import 'package:myaccount/services/app_services/starter_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/screens/view/register.view.dart';
import 'package:myaccount/widgets/button.global.dart';
import 'package:myaccount/widgets/social.login.dart';
import 'package:myaccount/widgets/text.form.global.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/services/app_services/onboard_service.dart';
import 'dart:convert';
import 'package:myaccount/screens/view/onbording.dart';
import 'package:myaccount/screens/view/forgot_password.view.dart';
import 'package:myaccount/screens/modules/profile/profile.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _authService = AuthService();
  final OnboardService _onboardService = OnboardService();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  Map<String, dynamic>? sessionData;

  String? _error;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    bool isLoggedIn = await _authService.loginWithCredentials(
      emailController.text,
      passwordController.text,
      // 'waghharish01@yopmail.com',
      // 'waghharish0272@yopmail.com',
      // 'waghharish36+2143@gmail.com',
      // 'sandeep.yotta+1@gmail.com',
      // 'waghharish060126@yopmail.com',
      // 'Yotta@2027'
      // 'waghharish0272@yopmail.com',
      // 'DRFTgyhu@12'
    );

    setState(() {
      _isLoading = false;
    });

    if (isLoggedIn) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomeScreen()),
      // );
      bool tSuccess = await fetchSessionStarter();
      if (tSuccess) {
        await _checkOnboardingAndNavigate();
      } else {
        setState(() {
          _error = "Failed to load session data.";
        });
      }
    } else {
      setState(() {
        _error = "Invalid credentials or login failed.";
      });
    }
  }

  Future<bool> fetchSessionStarter() async {
    try {
      final response = await _apiClient.getSessionStarter();
      if (response.statusCode == 200) {
        setState(() {
          sessionData = jsonDecode(response.body);
        });
        return true;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    return false;
  }

  Future<void> _checkOnboardingAndNavigate() async {
    try {
      final response = await _onboardService.getOnboardingData();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['accountStatus'] == "NonActive") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingView()),
          );
        } else if (sessionData?['userRoles'].contains('Admin') &&
            data['showMSA'] == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MSAPage()),
          );
        } else {
          // Check KYC Status
          final isKycApproved = await AccountDataService().isKycApproved();
          
          if (!isKycApproved) {
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileView()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error while registering your account. Kindly contact helpdesk@yotta.com',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      body: Column(
        children: [
          // Top image
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset('assets/images/loginbg.jpg', fit: BoxFit.cover),
          ),

          // Bottom content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: GlobalColors.borderColor,
                borderRadius: BorderRadius.only(
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
                        'Login to your account',
                        style: TextStyle(
                          color: GlobalColors.mainColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormGlobal(
                      controller: emailController,
                      text: 'Email',
                      obscure: false,
                      textInputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextFormGlobal(
                      controller: passwordController,
                      text: 'Password',
                      obscure: _obscurePassword,
                      textInputType: TextInputType.text,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ForgotPasswordView(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: GlobalColors.mainColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ButtonGlobal(
                          buttonText: 'Sign In',
                          onTap: _handleLogin,
                        ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    const SizedBox(height: 25),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Not a member? ', style: TextStyle(fontSize: 16)),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterView()),
                              );
                            },
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: GlobalColors.mainColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    // const SocialLogin(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: Container(
      //   height: 50,
      //   color: Colors.white,
      //   alignment: Alignment.center,
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       const Text('Not a member? ', style: TextStyle(fontSize: 16)),
      //       InkWell(
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => const RegisterView()),
      //           );
      //         },
      //         child: Text(
      //           'Register',
      //           style: TextStyle(
      //             color: GlobalColors.mainColor,
      //             fontSize: 16,
      //             fontWeight: FontWeight.w600,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
