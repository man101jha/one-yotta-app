import 'package:flutter/material.dart';
import 'package:myaccount/screens/view/login.view.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/screens/pages/dashboard.view.dart';

import 'package:myaccount/widgets/button.global.dart';
import 'package:myaccount/widgets/checkbox.form.global.dart';
import 'package:myaccount/widgets/contact.form.global.dart';
import 'package:myaccount/widgets/dropdown.form.global.dart';
import 'package:myaccount/widgets/select.form.global.dart';
import 'package:myaccount/widgets/text.form.global.dart';
import 'package:myaccount/utilities/env.dart'; // Import env file
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'dart:convert';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController contryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  bool isActive = false;
  bool isCompany = false; // Toggle for Company/Individual
  bool isFormFilled = false; // Track if form is filled
  bool agreeTerms = false;
  bool _termsError = false;
  bool registrationSuccess = false;
  bool isLoading = false; // <-- Add this

  List<Map<String, dynamic>> countryStateList = [];
  List<String> countryNames = [];
  List<String> stateNames = [];
  String? selectedCountry = "India"; // <-- Set default to India
  String? selectedState;

  List<Map<String, dynamic>> countryCallingCodes = [];
  String selectedCountryCode = '91'; // Default to India

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your First Name';
    if (value.length < 2 || value.length > 25)
      return 'First Name must be 2-25 characters';
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your Last Name';
    if (value.length < 2 || value.length > 25)
      return 'Last Name must be 2-25 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value == null || value.isEmpty) return 'Please enter your Email';
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validateCompanyName(String? value) {
    if (isCompany) {
      if (value == null || value.isEmpty)
        return 'Please enter your Company Name';
      if (value.length > 255)
        return 'Company Name must be less than 255 characters';
    }
    return null;
  }

  String? _validateCity(String? value) {
    final cityRegex = RegExp(r'^[A-Za-z ]{1,40}$');
    if (value == null || value.isEmpty) return 'Please enter your City';
    if (!cityRegex.hasMatch(value))
      return 'City must contain only letters and spaces, max 40 chars';
    return null;
  }

  String? _validateContact(String? value) {
    final contactRegex = RegExp(r'^[0-9]{10}$');
    if (value == null || value.isEmpty)
      return 'Please enter your Mobile Number';
    if (!contactRegex.hasMatch(value)) return 'Mobile Number must be 10 digits';
    return null;
  }

  String? _validatePincode(String? value) {
    if (selectedCountry == 'India') {
      final pinRegex = RegExp(r'^[0-9]{6}$');
      if (value == null || value.isEmpty) return 'Please enter your Pincode';
      if (!pinRegex.hasMatch(value)) return 'Pincode must be 6 digits';
      if (value == '000000') return 'Pincode cannot be 000000';
    } else {
      final pinRegex = RegExp(r'^[a-zA-Z0-9]{1,10}$');
      if (value == null || value.isEmpty) return 'Please enter your Pincode';
      if (!pinRegex.hasMatch(value))
        return 'Pincode must be 1-10 alphanumeric characters';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fetchCountriesAndStates();
    _fetchCountryCallingCodes(); // <-- Add this

    // Listen to field changes to update button state
    firstNameController.addListener(_checkFormFilled);
    lastNameController.addListener(_checkFormFilled);
    emailController.addListener(_checkFormFilled);
    mobileController.addListener(_checkFormFilled);
    companyNameController.addListener(_checkFormFilled);
  }

  Future<void> _fetchCountriesAndStates() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/countrystates',
        ),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          countryStateList = List<Map<String, dynamic>>.from(data);
          countryNames =
              countryStateList
                  .map((e) => e['countryName'] as String)
                  .toSet()
                  .toList()
                ..sort();
          if (!countryNames.contains('Select Country')) {
            countryNames.insert(0, 'Select Country');
          }
          // Set default to India if present, else first in list
          if (countryNames.contains("India")) {
            selectedCountry = "India";
          } else {
            selectedCountry = countryNames.first;
          }
          // Update stateNames for India by default
          stateNames =
              countryStateList
                  .where((e) => e['countryName'] == selectedCountry)
                  .map((e) => e['stateName'] as String)
                  .toList()
                ..sort();
        });
      } else {
        print("Error fetching countries: ${response.body}");
      }
    } catch (e) {
      print("Failed to fetch countries: $e");
    }
  }

  Future<void> _fetchCountryCallingCodes() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/country/callingcodes',
        ),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          countryCallingCodes = List<Map<String, dynamic>>.from(data);
          // Set default to India if present
          final india = countryCallingCodes.firstWhere(
            (e) => e['countryName'] == 'India',
            orElse: () => {},
          );
          if (india.isNotEmpty) {
            selectedCountryCode = india['countryCode'] ?? '91';
          }
        });
      }
    } catch (e) {
      print("Failed to fetch country codes: $e");
    }
  }

  // Check if all fields are filled
  void _checkFormFilled() {
    setState(() {
      isFormFilled =
          firstNameController.text.isNotEmpty &&
          lastNameController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          mobileController.text.isNotEmpty &&
          (isCompany ? companyNameController.text.isNotEmpty : true) &&
          isActive;
    });
  }

  static const String _termsAndConditionsContent = '''
Terms and Conditions (T&C) – One Yotta

1. AGREEMENT TO TERMS

These Terms of Use constitute a legally binding agreement made between you (“you” or “Customer”) and Yotta Data Services Pvt. Ltd.(together with its subsidiaries/affiliates/associate companies, “we,” “us” or “our”), concerning your access to and use of One Yotta (including sub-domains and microsites),as well as any other mobile website or mobile application related, linked, or otherwise connected thereto (collectively, the “Platform”). You agree that by accessing the Platform,you have read, understood, and agree to be bound by all of these Terms of Use.IF YOU DO NOT AGREE WITH ALL OF THESE TERMS OF USE, THEN YOU ARE PROHIBITED FROM USING THE PLATFORM AND YOU MUST DISCONTINUE USE IMMEDIATELY.

The information provided on the Platform is not intended for distribution to or use by any person or entity in any jurisdiction or country where such distribution or use would be contrary to law or regulation or which would subject us to any registration requirement within such jurisdiction or country. Accordingly, those persons who choose to access the Platform from other locations do so on their own initiative and are solely responsible for compliance with local laws, if and to the extent local laws are applicable.

2.SERVICES

We provide a broad range of services that are subject to these terms. The permission we give you to use our services continues as long as you meet your responsibilities in:

Service Specific terms mentioned in the Master Service Agreement and the SOFs respectively; and
These terms and conditions.
3. IPR
Unless otherwise indicated, the Platform is our proprietary property and all source code, databases, functionality, software, website designs, audio, video, text, photographs, and graphics on the Platform (collectively, the “Content”) and the trademarks, service marks, and logos contained therein (the “Marks”) are owned or controlled by us or licensed to us, and are protected by copyright and trademark laws and various other intellectual property rights of India, foreign jurisdictions and international conventions. The Content and the Marks are provided on the Platform “AS IS” for your information only. Except as expressly provided in these Terms of Use, no part of the Platform and no Content or Marks may be copied, reproduced, aggregated, republished, uploaded, posted, publicly displayed, encoded, translated, transmitted, distributed, sold, licensed, framed, mirrored or used for the creation of any derivative works or otherwise exploited for any commercial purpose whatsoever, without our express prior written permission. You are not permitted to reverse-compile, disassemble, reverse-engineer or otherwise replicate any part of the Content or the Marks.

You are granted a limited license to access and use the Platform and to download or print a copy of any portion of the Content (if so enabled by the Platform) to which you have properly gained access solely for your personal, non-commercial use. We reserve all rights not expressly granted to you in and to the Platform, Content and the Marks.

4. USER REPRESENTATIONS

By using the Platform, you represent and warrant that:

All registration information you submit will be true, accurate, current, complete and not misleading;
You will maintain the accuracy of such information and promptly update such registration information as necessary.
You have the legal capacity and you agree to comply with these Terms of Use;
You are not under the age of 18 or a minor in the jurisdiction in which you reside;
You will not access the Platform through automated or non-human means, whether through a bot, script or otherwise; and
You will not use the Platform for any illegal or unauthorized purpose.
In case of a breach of the representations in this Clause 4 or of any other part of these Terms of Use, we have the right to:

(a) Suspend or terminate your account;
(b) Refuse any and all current or future use of the Platform (or any portion thereof); and
(c) Terminate your access to any other programs or features.
5. PROHIBITED ACTIVITIES

You may not access or use the Platform for any purpose other than that for which we make the Platform available. Access to the Platform shall not be made available to any person(s)/ entity other than the persons(s)/ entity approved by us.

As a user of the Platform, you agree not to:

Systematically retrieve data or other content from the Platform to create or compile, directly or indirectly, a collection, compilation, database, or directory without written permission from us;
Make any unauthorized use of the Platform, including collecting usernames and/or email addresses of users by electronic or other means for the purpose of sending unsolicited email, or creating user accounts by automated means or under false pretenses.
Use the Platform to advertise or offer to sell goods and services.
Circumvent, disable, or otherwise interfere with security-related features of the Platform, including features that prevent or restrict the use or copying of any Content or enforce limitations on the use of the Platform and/or the Content contained therein.
Engage in unauthorized framing of or linking to the Platform.
Trick, defraud, or mislead us and other users, especially in any attempt to learn sensitive account information such as user passwords.
Make improper use of our support services or submit false reports of abuse or misconduct;
Engage in any automated use of the system, such as using scripts to send comments or messages, or using any data mining, robots, or similar data gathering and extraction tools;
Interfere with, disrupt, or create an undue burden on the Platform or the networks or services connected to the Platform;
Attempt to impersonate another user or person or use the username or account of another user;
Sell or otherwise transfer your Account or access of your Account;
Use any information obtained from the Platform in order to harass, abuse, or harm another person;
Use the Platform as part of any effort to compete with us or otherwise use the Platform and/or the Content for any revenue-generating endeavor or commercial enterprise;
Decipher, decompile, disassemble, or reverse engineer any of the software comprising or in any way making up a part of the Platform;
Attempt to bypass any measures of the Platform designed to prevent or restrict access to the Platform, or any portion of the Platform;
Harass, annoy, intimidate, or threaten any of our employees or agents engaged in providing any portion of the Platform to you;
Delete the copyright or other proprietary rights notice from any Content;
Copy or adapt the Platform’s software;
Upload or transmit (or attempt to upload or to transmit) viruses, Trojan horses, or other material, including excessive use of capital letters and spamming (continuous posting of repetitive text), that interferes with any party’s uninterrupted use and enjoyment of the Platform or modifies, impairs, disrupts, alters, or interferes with the use, features, functions, operation, or maintenance of the Platform;
Except as may be the result of standard search engine or Internet browser usage, use, launch, develop, or distribute any automated system, including without limitation, any spider, robot, cheat utility, scraper, or offline reader that accesses the Platform, or using or launching any unauthorized script or other software.
Disparage, tarnish, or otherwise harm, in our opinion, us, our reputation or goodwill and/or the Platform; or
Use the Platform in a manner inconsistent with any applicable laws or regulations and these Terms of Use.
6. PRIVACY POLICY AND DATA

We care about data privacy and security. Please review our Privacy Policy(Privacy Policy). By using the Platform, you agree to be bound by our Privacy Policy.

Please be advised that the Platform is hosted in India. If you access the Platform from the European Union, United States, or any other region of the world with laws or other requirements governing personal data collection, use, or disclosure that differ from applicable laws in India, then through your continued use of the Platform or Services, you are transferring your data to India, and you expressly consent to have your data transferred to and processed in India.

7.COPYRIGHT INFRINGEMENT

We respect the intellectual property rights of others. If you believe that any material available on or through the Platform infringes upon any copyright you own or control, please immediately notify us using the contact information provided below (a “Notification”).If you are not sure that material located on or linked to by the Platform infringes your copyright, you should consider first contacting an attorney.

8.TERM AND TERMINATION

These Terms of Use shall remain in full force and effect while you use the Platform or as long as our content is protected by applicable intellectual property rights law, whichever is later.WITHOUT LIMITING ANY OTHER PROVISION OF THESE TERMS OF USE, WE RESERVE THE RIGHT TO, IN OUR DISCRETION AND WITHOUT NOTICE OR LIABILITY, DENY ACCESS TO AND USE OF THE PLATFORM (INCLUDING BLOCKING CERTAIN IP ADDRESSES),TO ANY PERSON FOR BREACH OF ANY REPRESENTATION, WARRANTY, OR COVENANT CONTAINED IN THESE TERMS OF USE OR OF ANY APPLICABLE LAW OR REGULATION. WE MAY TERMINATE YOUR USE OR PARTICIPATION IN THE PLATFORM OR SUSPEND YOUR ACCOUNT AND ANY CONTENT OR INFORMATION THAT YOU POSTED AT ANY TIME WITHOUT NOTICE IN CASE OF BREACH OF TERMS AND CONDITION HEREIN OR INCORPORATED UNDER ANY AGREEMENT.

If we suspend your Account for any reason, you are prohibited from registering and creating a new Account under your name, a fake or borrowed name, or the name of any third party, even if you may be acting on behalf of the third party. In addition to suspending your Membership Account, we reserve the right to take appropriate legal action, including without limitation pursuing civil, criminal, and injunctive redress.

9. MODIFICATION AND INTERRUPTIONS

We reserve the right to change, modify, or remove the contents of the Platform at any time or for any reason at our discretion without notice. However, we have no obligation to update any information on our Platform. We also reserve the right to modify or discontinue all or part of the Platform without notice. We will not be liable to you or any third party for any modification, price change, suspension, or discontinuance of the Platform.

We cannot guarantee the Platform will be available at all times. We may experience hardware, software, or other problems or need to perform maintenance related to the Platform, resulting in interruptions, delays, or errors. We reserve the right to change, revise, update, suspend, discontinue, or otherwise modify the Platform for any reason without notice to you. You agree that we have no liability whatsoever for any loss, damage, or inconvenience caused by your inability to access or use the Platform during any downtime or discontinuance of the Platform. Nothing in these Terms of Use will be construed to obligate us to maintain and support the Platform or to supply any corrections, updates, or releases in connection therewith.

11. GOVERNING

These Terms of Use and your use of the Platform are governed by and will be construed in accordance with the laws of India, without regard to its conflict of law principles.

11. DISCLAIMER

THE PLATFORM IS PROVIDED ON AN AS-IS AND AS-AVAILABLE BASIS. YOU AGREE THAT YOUR USE OF THE PLATFORM SERVICES WILL BE AT YOUR SOLE RISK. TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, IN CONNECTION WITH THE PLATFORM AND YOUR USE THEREOF, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. WE MAKE NO WARRANTIES OR REPRESENTATIONS ABOUT THE ACCURACY OR COMPLETENESS OF THE PLATFORM’S CONTENT OR THE CONTENT OF ANY WEBSITES LINKED TO THIS PLATFORM AND WE WILL ASSUME NO LIABILITY OR RESPONSIBILITY FOR ANY (1) ERRORS, MISTAKES, OR INACCURACIES OF CONTENT AND MATERIALS, (2) PERSONAL INJURY OR PROPERTY DAMAGE,OF ANY NATURE WHATSOEVER, RESULTING FROM YOUR ACCESS TO AND USE OF THE PLATFORM, (3) ANY UNAUTHORIZED ACCESS TO OR USE OF OUR SECURE SERVERS AND/OR ANY AND ALL PERSONAL INFORMATION AND/OR FINANCIAL INFORMATION STORED THEREIN, (4) ANY INTERRUPTION OR CESSATION OF TRANSMISSION TO OR FROM THE PLATFORM, (5) ANY BUGS, VIRUSES, TROJAN HORSES, OR THE LIKE WHICH MAY BE TRANSMITTED TO OR THROUGH THE PLATFORM BY ANY THIRD PARTY, AND/OR (6) ANY ERRORS OR OMISSIONS IN ANY CONTENT AND MATERIALS OR FOR ANY LOSS OR DAMAGE OF ANY KIND INCURRED AS A RESULT OF THE USE OF ANY CONTENT POSTED, TRANSMITTED, OR OTHERWISE MADE AVAILABLE VIA THE PLATFORM. WE DO NOT WARRANT, ENDORSE, GUARANTEE, OR ASSUME RESPONSIBILITY FOR ANY PRODUCT OR SERVICE ADVERTISED OR OFFERED BY A THIRD PARTY THROUGH THE PLATFORM, ANY HYPERLINKED WEBSITE, OR ANY WEBSITE OR MOBILE APPLICATION FEATURED HEREIN, AND WE WILL NOT BE A PARTY TO OR IN ANY WAY BE RESPONSIBLE FOR MONITORING ANY TRANSACTION BETWEEN YOU AND ANY THIRD-PARTY PROVIDERS OF PRODUCTS OR SERVICES. AS WITH THE PURCHASE OF A PRODUCT OR SERVICE THROUGH ANY MEDIUM OR IN ANY ENVIRONMENT, YOU SHOULD USE YOUR BEST JUDGMENT AND EXERCISE CAUTION WHERE APPROPRIATE.

''';

  static const String _privacyPolicyContent = '''
Data Protection and Privacy Policy
INTRODUCTION
This General Privacy Policy (“Policy”) explains how we may collect and use information that Yotta Data Services Private Limited, its related corporations and/ or associated companies (“Yotta“) obtains about you, and your rights in relation to that information.

Please read this Policy to understand how we will collect, use, and process your personal data and the rights you have in relation to your personal data. This Policy may be amended from time to time. Please visit this page if you want to stay up to date, as we will post any changes in our approach to data privacy here.

By providing your explicit consent and/ or by your provision of information to us, you acknowledge the terms of this Policy and the use and disclosure of your personal data as set out in this Policy.

SCOPE OF POLICY
This Policy applies to our processing of personal data in relation to the provision of any of our products and/or services, including:

when you request information from us;
when you engage our services and/or purchase our products;
as a result of your relationship with one or more of our clients;
where you apply for a job or work placement; and
your use of our websites (including our associated sites) and online services (including our mobile apps, if any).
DEFINITION
Personal Data

‘Personal Data’ is any information which either directly or in combination with other information availed or likely to be availed by an organisation, identifies an individual. Examples of Personal Data could include names, email ids, phone numbers etc. Certain types of Personal Data known as ‘Special Categories of Personal Data or Sensitive Personal Data’ include passwords, financial details, official identifiers, medical information etc. For the purposes of this Policy, Personal Data includes Sensitive Personal Data.

HOW YOUR PERSONAL DATA IS COLLECTED
Directly:

We generally collect your personal data directly from you when you are one of our customers. When you enter a contract with us, you will be asked to provide personal data. This information is likely to include your name, address, date of birth, email address, phone number, and financial information (this is not an exhaustive list).
We may also collect personal data from you when you make transactions or otherwise interact with us, for example by contacting our customer service personnel or reporting a problem on our website. The categories and range of personal data we collect, and hold will vary from customer to customer. However, our policy is to collect only the personal data necessary for the provision of services to You.
Business Contacts and Suppliers.

We collect certain limited personal data about our business contacts, including subcontractors and individuals associated with our suppliers and subcontractors, and service providers (including professional advisors and individuals associated with our service providers). Personal data collected in this context usually includes (but may not exclusively be limited to) name, employer name, contact title, phone, email, and other business contact details.

Careers and Recruitment

If you apply for a job or work placement you may need to provide information about your education, employment, nationality, and state of health. Your application will constitute your express consent to our use of this information to assess your application and to allow us to carry out both recruitment analytics and any monitoring activities which may be required of us under applicable law as an employer. We may also carry out screening checks (including reference, background, directorship, financial probity, identity, eligibility to work, vocational suitability and criminal record checks) and consider you for other positions. We may disclose your personal data (including diversity and equal opportunities data) to academic institutions, recruiters, screening check providers, health service providers, professional and trade associations, law enforcement agencies, recruitment analytics and diversity research providers, referees, and your current and previous employers. We may also collect your personal data from these parties in some circumstances. Without your personal data we may not be able to progress considering you for positions with us.

Visitors to our Offices and Facilities

We have security measures in place at our offices and facilities, including CCTV and building access controls. There are signs in our premises showing that CCTV is in operation. The images captured are securely stored and only accessed on a need-to-know basis (e.g., to investigate an incident). CCTV recordings are typically automatically overwritten after a defined period unless an issue is identified that requires investigation (such as a theft). Our visitor records are securely stored and only accessible on a need-to-know basis (e.g., to investigate an incident). In some cases, we require visitors to our offices or facilit scan biometrics (e.g., thumbprints) at reception or security guard house and keep a record of the same for. Such records are securely stored and only accessible on a need-to-know basis (e.g., to investigate an incident).

Automatically:

When you use our online services or visit our website, we may collect the following information from you automatically:

details of visits made to our website such as the volume of traffic received, logs (including, the internet protocol (IP) address and location of the device connecting to the online services and other identifiers about the device and the nature of the visit) and the resources accessed.
We use cookies to collect certain personal data. For further information on Cookies please refer to our Cookie Policy.
PURPOSE AND USE OF PERSONAL DATA:
We may use/process your personal data in the following circumstances:

performance of a contract with you.
to comply with Yotta’s legal or regulatory obligations.
to process your job application.
to provide our services including this website to You.
to provide and improved experience when you avail our services and products.
to notify you about changes to the products and/or services that we offer and (where you have indicated your consent) to directly market these products and/or services to you.
research, statistical and survey purposes.
to allow you to participate in interactive features of our products and services.
as part of our efforts to keep our products and/or services safe and secure.
to analyze your credit history (if applicable).
to handle payment and collection processes to and from customers.
for anti-money laundering, prevention of terrorist financing, and identity verification purposes.
With reference to above stated purposes the following data elements may be collect as applicable:

During Registration	During KYC	For Billing	For Support
Organization name
Identification proof
Billing address
First name
Primary contact first name
Address proof
Country
Last name
Primary contact last name
State
Email
Primary email
City
Country code
Country Code
Postal Code
Contact no.
Primary Contact no.
Taxation Type
Company website
Taxation Id
Primary address
Credit Limit
Country
BIlling Cycle
State
Bill Date
City
Billing type
Postal Code
Currency
Marketing
We (and permitted third parties) may contact you for direct marketing purposes via social media, direct messages, post, telephone, email and SMS/MMS.

This marketing may relate to:

Products and services we (or permitted third parties) feel may interest you;
Information about other goods and services we offer that are similar to those that you have already used or inquired about;
Upcoming events, promotions, and new products and/or services or other opportunities as well as;
those of selected third parties who are contracted by Yotta; and
If you no longer wish to receive marketing communications from us, you may click on the unsubscribe link on any marketing communication that you receive from us.
For clarity, any telephone calls that you make to us may be recorded for training or security purposes and may be stored and used to verify your instructions to us.

WHO DO WE SHARE YOUR PERSONAL DATA WITH:
We may share your personal data with the following categories of recipients:

Regulatory bodies
We may disclose your personal data:

to regulators and law enforcement agencies (including those responsible for enforcing anti-money laundering legislations);
in response to an inquiry from a government agency;
to data protection regulatory authorities; and
to other regulatory authorities with jurisdiction over our activities

Service providers
We may disclose your personal data to third party service providers who require access to such information for the purpose of providing specific services to us. These third parties will generally only be able to access your data to provide us with their services and will not be able to use it for their own purposes.

Change of Ownership
In the event, we sell or buy any business assets, we may disclose your personal data to the prospective seller or buyer of such business or assets. If Yotta or substantially all its assets are acquired by a third party, personal data held by us about our clients will be one of the transferred assets.

HOW WE PROTECT YOUR PERSONAL DATA
We care about protecting your information and put in place appropriate measures that are designed to prevent unauthorized access to, and misuse of, your personal data. These include measures to deal with any suspected data breach.

We do this by having in place a range of appropriate technical and organizational measures, for example, the protection of passwords using industry standard encryption, measures to preserve system security and prevent unauthorized access and back-up systems to prevent accidental or malicious loss of data.

HOW LONG WE KEEP YOUR PERSONAL DATA
We will not keep your personal data for longer than is necessary for the purposes for which we have collected it, unless we believe that the law or other regulation requires us to retain it.

In determining the appropriate retention period for different types of personal data, the amount, nature, and sensitivity of the personal data in question, as well as the potential risk of harm from unauthorized use or disclosure of that personal data, the purposes for which we need to process it.

Once we have determined that we no longer need to hold your personal data, we will delete it from our systems or render it inaccessible/unusable by Yotta or its third parties. with due regard to protection of privacy of the said personal data.

GUIDELINES FOR CHILDREN
Services provided by Yotta are intended for general public and are not meant for individuals below 18 years of age.

We do not knowingly or intent to gather personal information from children. If you have any concerns, please contact our Privacy Officer / DPO at dpo@Yotta.com.

RIGHTS TO PERSONAL DATA:
If you wish to access, rectify or delete your data, please contact our Privacy Officer/ DPO at dpo@Yotta.com. We will seek to deal with your request without undue delay, and in any event within one month (subject to any extensions to which we are lawfully entitled) of receipt of your request. Please note that we may keep a record of your communications to help us resolve any issues which you raise.

You may also withdraw your consent previously provided by writing to us at dpo@Yotta.com. Please note,that should you withdraw your consent, it may hamper our ability to provide services to you and may result in complete cessation of all services to You. Yotta or any of its authorised third parties will not be liable for any losses suffered by You as a result of the same.

CHANGES TO THIS POLICY
This Policy is effective since November 2019. We may change this Privacy Policy from time to time adhering to the best practices and standards and reserve the right to do so any time.

Updated Policy will be available at our website, You are advised to check this Privacy Policy periodically.


''';

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final double maxHeight = MediaQuery.of(context).size.height * 0.85;
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          initialChildSize: 0.85,
          builder:
              (context, scrollController) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            content,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Show loading
      });

      String formatName(String name) =>
          name.isNotEmpty
              ? name[0].toUpperCase() + name.substring(1).toLowerCase()
              : '';
      String firstName = formatName(firstNameController.text.trim());
      String lastName = formatName(lastNameController.text.trim());
      String email = emailController.text.trim().toLowerCase();
      String mobile = '$selectedCountryCode-${mobileController.text.trim()}';
      String country = selectedCountry ?? '';
      String state = selectedState ?? '';
      String city = cityController.text.trim();
      String pincode = pincodeController.text.trim();
      String companyName = isCompany ? companyNameController.text.trim() : '';

      String formatCity(String city) =>
          city.isNotEmpty ? city[0].toUpperCase() + city.substring(1) : '';

      String countryCode = '';
      if (selectedCountry != null && selectedCountry != 'Select Country') {
        final countryObj = countryStateList.firstWhere(
          (e) => e['countryName'] == selectedCountry,
          orElse: () => {},
        );
        countryCode = countryObj['countryCode']?.toString() ?? '';
      }

      // Get state id from countryStateList
      String stateId = '';
      if (selectedCountry != null && selectedState != null) {
        final stateObj = countryStateList.firstWhere(
          (e) =>
              e['countryName'] == selectedCountry &&
              e['stateName'] == selectedState,
          orElse: () => {},
        );
        stateId = stateObj['id']?.toString() ?? '';
      }

      final registrationData = {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "mobileNo": mobile,
        "accountName": companyName,
        "accountType": "Prospect",
        "countryName": country,
        "countryCode": countryCode,
        "state": stateId, // <-- Use the state id here
        "currency": "INR",
        "city": formatCity(city),
        "pinCode": pincode,
        "isCompany": isCompany,
        "isTAndCApplied": agreeTerms,
      };

      try {
        final response = await http.post(
          Uri.parse(
            'https://uatmyaccountapi.yotta.com/my_account/pub/api/v1/register',
          ),
          headers: {"Content-Type": "application/json"},
          body: json.encode(registrationData),
        );

        setState(() {
          isLoading = false; // Hide loading
        });

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(width: 8),
                      Text(
                        'Registration Successful',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Thank you. Please check your email for further details to complete your registration.',
                    style: TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                        ); // Navigate to login page
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
          );
        } else {
          // Parse error message from response
          String errorMsg = "Registration failed. Please try again.";
          try {
            final errorBody = json.decode(response.body);
            if (errorBody is Map && errorBody['message'] != null) {
              errorMsg = errorBody['message'];
            }
          } catch (_) {}
          // Show error to user
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Registration Failed'),
                  content: Text(errorMsg),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false; // Hide loading on error
        });
        print("Failed to register: $e");
      }
    }
  }

  int _step = 0; // 0: Personal, 1: Address

  void _nextStep() {
    if (_step == 0 && _formkey.currentState!.validate()) {
      setState(() => _step = 1);
    }
  }

  void _prevStep() {
    if (_step == 1) setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                        child: Form(
                          key: _formkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Create your account',
                                  style: TextStyle(
                                    color: GlobalColors.mainColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_step == 0) ...[
                                _buildTextFormField(
                                  'First Name',
                                  firstNameController,
                                  validator: _validateFirstName,
                                ),
                                const SizedBox(height: 15),
                                _buildTextFormField(
                                  'Last Name',
                                  lastNameController,
                                  validator: _validateLastName,
                                ),
                                const SizedBox(height: 15),
                                _buildTextFormField(
                                  'Email',
                                  emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Container(
                                      width: 95,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedCountryCode,
                                        items:
                                            countryCallingCodes.map((code) {
                                              return DropdownMenuItem<String>(
                                                value: code['countryCode'],
                                                child: Text(
                                                  '+${code['countryCode']}',
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            selectedCountryCode = val ?? '91';
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Code',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildTextFormField(
                                        'Mobile Number',
                                        mobileController,
                                        keyboardType: TextInputType.phone,
                                        validator: _validateContact,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Individual"),
                                    Switch(
                                      value: isCompany,
                                      onChanged: (value) {
                                        setState(() {
                                          isCompany = value;
                                          _checkFormFilled();
                                        });
                                      },
                                    ),
                                    const Text("Company"),
                                  ],
                                ),
                                if (isCompany) ...[
                                  _buildTextFormField(
                                    'Company Name',
                                    companyNameController,
                                    validator: _validateCompanyName,
                                  ),
                                  const SizedBox(height: 15),
                                ],
                                const SizedBox(height: 20),
                                ButtonGlobal(
                                  buttonText: 'Next',
                                  onTap: _nextStep,
                                ),
                              ] else ...[
                                DropdownFormGlobal<String>(
                                  value: selectedCountry ?? "Select Country",
                                  label: "Country",
                                  items:
                                      countryNames.map((country) {
                                        return DropdownMenuItem(
                                          value: country,
                                          child: Text(country),
                                        );
                                      }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedCountry = val;
                                      if (val == 'Select Country') {
                                        stateNames = [];
                                        selectedState = null;
                                      } else {
                                        stateNames =
                                            countryStateList
                                                .where(
                                                  (e) =>
                                                      e['countryName'] == val,
                                                )
                                                .map(
                                                  (e) =>
                                                      e['stateName'] as String,
                                                )
                                                .toList()
                                              ..sort();
                                        selectedState = null;
                                      }
                                    });
                                  },
                                  validator:
                                      (val) =>
                                          (val == null ||
                                                  val == 'Select Country')
                                              ? 'Select country'
                                              : null,
                                ),
                                const SizedBox(height: 15),
                                DropdownFormGlobal<String>(
                                  value: selectedState,
                                  label: 'State',
                                  items:
                                      stateNames.map((state) {
                                        return DropdownMenuItem(
                                          value: state,
                                          child: Text(state),
                                        );
                                      }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedState = val;
                                    });
                                  },
                                  validator:
                                      (val) =>
                                          val == null ? 'Select state' : null,
                                ),

                                const SizedBox(height: 15),
                                _buildTextFormField(
                                  'City',
                                  cityController,
                                  validator: _validateCity,
                                ),
                                const SizedBox(height: 15),
                                _buildTextFormField(
                                  'Pincode',
                                  pincodeController,
                                  validator: _validatePincode,
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: agreeTerms,
                                      activeColor: const Color(0xFF283E81),
                                      onChanged: (value) {
                                        setState(() {
                                          agreeTerms = value!;
                                          if (agreeTerms) _termsError = false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: "I agree to the ",
                                            ),
                                            TextSpan(
                                              text: "Term and Conditions",
                                              style: const TextStyle(
                                                color: Color(0XFF283E81),
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              recognizer:
                                                  TapGestureRecognizer()
                                                    ..onTap = () {
                                                      _showPolicyDialog(
                                                        context,
                                                        "Terms & Conditions",
                                                        _termsAndConditionsContent,
                                                      );
                                                    },
                                            ),
                                            const TextSpan(text: " and "),
                                            TextSpan(
                                              text: "Privacy Policy",
                                              style: const TextStyle(
                                                color: Color(0XFF283E81),
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              recognizer:
                                                  TapGestureRecognizer()
                                                    ..onTap = () {
                                                      _showPolicyDialog(
                                                        context,
                                                        "Privacy Policy",
                                                        _privacyPolicyContent,
                                                      );
                                                    },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_termsError)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      top: 4,
                                    ),
                                    child: Text(
                                      'Please accept the Terms and Conditions to proceed.',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonGlobal(
                                        buttonText: 'Back',
                                        onTap: _prevStep,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ButtonGlobal(
                                        buttonText: 'Submit',
                                        onTap:
                                            isLoading
                                                ? null
                                                : () {
                                                  final formValid =
                                                      _formkey.currentState!
                                                          .validate();
                                                  if (!agreeTerms) {
                                                    setState(() {
                                                      _termsError = true;
                                                    });
                                                  }
                                                  if (formValid && agreeTerms) {
                                                    _submitForm();
                                                  }
                                                },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF283E81),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            height: 50,
            color: Colors.white,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already a member? ',
                  style: TextStyle(fontSize: 16),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: GlobalColors.mainColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextFormGlobal(
      controller: controller,
      text: label,
      obscure: obscure,
      textInputType: keyboardType,
      validator: validator,
      suffixIcon: suffixIcon,
    );
  }
}
