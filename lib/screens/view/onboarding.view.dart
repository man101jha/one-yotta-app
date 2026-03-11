import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myaccount/screens/modules/profile/contact.dart';
import 'package:myaccount/screens/pages/dashboard.view%20copy.dart';
import 'package:myaccount/screens/pages/main_wrapper.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/onboard_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:myaccount/services/auth_service.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _formkey = GlobalKey<FormState>();
  final OnboardService _onboardService = OnboardService();
  final AuthService _authService = AuthService();

  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController addLineOneController = TextEditingController();
  final TextEditingController addLineTwoController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController gstinController = TextEditingController();
  final TextEditingController lutNumberController = TextEditingController();
  final TextEditingController lutExpiryController = TextEditingController();
  File? lutFile;
  String? selectedCountry;
  String? selectedState;
  String? addressType = 'billing';
  String? sez;
  bool panApplicable = false;
  bool gstApplicable = false;
  bool isLoading = false;
  bool onboardStatus = false;
  bool showSezError = false;
  bool agreeTerms = false;
  List<Map<String, dynamic>> countryStateList = [];
  List<String> countryNames = [];
  List<String> stateNames = [];
  String? uploadedDocumentName;
  String? uploadedBase64File;
  String? selectedAddressCrmUid;
  String contactFirstName = '';
  String ContactLastName = '';

  int _step = 0; // 0: Basic, 1: Address, 2: Taxation

  double get _progress {
    switch (_step) {
      case 0:
        return 0.3;
      case 1:
        return 0.5;
      case 2:
        return 0.8;
      case 3:
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _nextStep() {
    if (_formkey.currentState!.validate()) {
      if (_step == 2 && !agreeTerms) {
        showWarning(context, "Please agree to the Master Service Agreement");
        return;
      }
      setState(() {
        if (_step < 3) _step++;
      });
    }
  }

  void _prevStep() {
    setState(() {
      if (_step > 0) _step--;
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchCountriesAndStates();
    await _fetchOnboardingData();
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

        if (!mounted) return;

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
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch countries: $e");
    }
  }

  Future<void> _fetchOnboardingData() async {
    try {
      final response = await _onboardService.getOnboardingData();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!mounted) return;

        setState(() {
          accountNameController.text = data['accountName'] ?? '';
          cityController.text = data['city'] ?? '';
          postalCodeController.text = data['pinCode'] ?? '';

          selectedCountry = data['country'];
          selectedState = data['state'];
          selectedAddressCrmUid = data['addressCRMUID'];

          contactFirstName = data['firstName'] ?? '';
          ContactLastName = data['lastName'] ?? '';

          // Populate states AFTER countries are loaded
          if (selectedCountry != null) {
            stateNames =
                countryStateList
                    .where((e) => e['countryName'] == selectedCountry)
                    .map((e) => e['stateName'] as String)
                    .toList()
                  ..sort();
          }

          // SEZ logic
          sez = selectedCountry == 'India' ? '0' : '2';

          // PAN/GST toggle
          if (selectedCountry != 'India') {
            gstApplicable = false;
            panApplicable = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch onboarding data : $e');
    }
  }

  int? getStateId(String? stateName) {
    if (stateName == null) return null;

    return int.tryParse(
      countryStateList
          .firstWhere((e) => e['stateName'] == stateName)['id']
          .toString(),
    );
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Message"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void showWarning(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Warning"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> pickAndValidatePdf(
    BuildContext context,
    void Function(void Function()) setModalState,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.extension != 'pdf') {
      showWarning(context, "Please select pdf file for upload");
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      showWarning(
        context,
        "File too large, please select a file smaller than 5 Mb.",
      );
      return;
    }

    final base64File = base64Encode(file.bytes!);

    setModalState(() {
      uploadedDocumentName = file.name;
      uploadedBase64File = base64File;
    });
  }

  Future<void> uploadFile(BuildContext context) async {
    final accountDataService = AccountDataService();
    final response = await accountDataService.getAccountData();

    final jsonData = json.decode(response.body);
    final accountCrmUid = jsonData['accountCRMUUID'];

    try {
      setState(() {
        // isLoading = true;
      });

      final requestBody = {
        "IsDeleted": false,
        "Name": 'LOA Certificate Address Proof',
        "Address": selectedAddressCrmUid,
        "DocumentCategory": "Address Proof",
        "Document": 'LOA Certificate Address Proof',
        "ObjectName": "Address",
        "attachment": uploadedBase64File, // BASE64 PDF
        "Account": accountCrmUid,
      };

      final token = await _authService.getAccessToken();

      final response = await http.post(
        Uri.parse(
          "https://uatmyaccountapi.yotta.com/my_account/api/v1/address/document/upload",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      setState(() {
        // isLoading = false;
      });

      final responseBody = jsonDecode(response.body);

      if (responseBody["Status"] == "Failure") {
        _showAlert(context, "Document upload failed");
        Navigator.pop(context);
      } else {
        _showAlert(context, "Document uploaded successfully");
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        // isLoading = false;
      });
      _showAlert(context, e.toString());
    }
  }

  static const String _MSAContent = '''
This Master Service Agreement (“Agreement”) is entered into by and between:

YOTTA DATA SERVICES PRIVATE LIMITED bearing CIN number U72900MH2022FTC391832 incorporated under the provision of the Companies Act, 2013, having its registered address at Unit No. 101, 1st Floor, B. G. House, Lake Boulevard Street, Hiranandani Gardens, Powai, Mumbai, Maharashtra, India, 400076, hereinafter referred to as “Yotta”, (which expression shall unless repugnant to the context or meaning thereof, mean and include its successors and permitted assigns) the FIRST PART;

AND

Customer means the legal entity accessing or using our Service(s), which expression shall, unless repugnant to the context or meaning thereof, be deemed to include its successors, and permitted assigns, which expression shall unless repugnant to the context or meaning thereof, mean and include its successors and permitted assigns) the SECOND PART.

Yotta and the Customer shall hereby individually be referred to as a “Party” and collectively referred to as “Parties”.

WHEREAS,
Yotta is engaged in the business of providing data Centre services along with internet services and other related services. Yotta is a licensed Internet Service Provider (“ISP”) National Long Distance (NLD), and other services vide the unified license (VNO) issued byDepartment of Telecommunications (“DoT”), (“Yotta Business”).

The Customer is desirous of availing Services from Yotta, and Yotta have agreed to provide such Services to the Customer in accordance with the terms and conditions set forth under this Agreement.

NOW THEREFORE,
in consideration of the mutual covenants and representations set forth in this Agreement and for other good and valuable considerations, the Parties, intending to be legally bound, hereby agree as follow

1. DEFINTIONS
1.1. Affiliate shall mean, in relation to any person:

     i. if that person is an individual, any person who is a relative of such person; and

     ii. if that person (the “Subject Person”) is other than a natural person, any other person that, either directly or indirectly through one or more intermediate persons, controls, is controlled by or is under common control with the Subject Person. “Control” means the power to direct the management or policies of a person directly or indirectly, whether through the ownership of over fifty percent (50%) of the voting power of such person, or through the power to appoint over half of the members of the board of directors or similar governing body of such person or through any other arrangements. And the words “Controls” or “Controlled by” or “Controlling” shall be construed accordingly.

1.2. Agreement means this Master Services Agreement, with reference to any SOF, addenda, exhibits, schedules, annexures and supplements thereto.

1.3. Applicable Laws shall mean any law, statute, rule, regulation, order, circular, decree, directive, judgement, decision or other similar mandate of any applicable central, national, state or local governmental authority having competent jurisdiction over, or application to a party or subject matter in question.

1.4. Customer Equipment means all equipment or other tangible items (including without limitation, cabling) owned by Customer and installed, stored or located in the Designated Customer Area by the Customer, except Yotta supplied equipment. The definition excludes stored data and software loaded in Customer Equipment.

1.5. Designated Customer Area means the area(s) or space(s) (including any rack space, full cabinets and / or cages) for the use of the Service(s) and for placement of the Customer Equipment and/ or Yotta supplied equipment.

1.6. Force Majeure shall include, but not limited to, any of the following incidents, namely: war, pandemic or epidemics, quarantine, blockades, hostilities, civil disturbance, terrorism, insurrections, sabotage, hurricane, earthquake, tornados, revolution, riots, strikes, lockout, fire, storm, flood, failure of the internet, delay or interruption in transportation or any other cause that is not reasonably within the control of the party claiming Force Majeure and also such circumstance(s) which may be declared by the Government Authority as a Force Majeure ground.

1.7. Governmental Authority shall mean any governmental authority or quasi-governmental body, whether foreign or domestic, including any department, agency, commission, bureau, or other administrative or regulatory bodies, courts, public utilities, and communication authorities, (e.g., Department of Telecommunications, Telecom Regulatory Authority of India, etc.)

1.8. Service(s) means any services provided by Yotta to the Customer including the related support made available by Yotta to the Customer under applicable Service Order Form.

1.9. Service Order Form / SOF means an ordering document or online order specifying the Service(s) to be provided hereunder that is entered into between the Customer and Yotta, including any addenda, exhibits and supplements thereto. By entering into a SOF hereunder, an Affiliate agrees to be bound by the terms of this Agreement as if it were an original party hereto.

1.10. Yotta Data Centre shall mean any facility of Yotta or Yotta’s Affiliate(s), which is owned, leased, occupied, taken on leave and license, or used by Yotta to provide Service(s).

2. INTERPRETATION
2.1. Words of any gender are deemed to include those of the other gender;

2.2. Words using the singular or plural number also include the plural or singular number, respectively;

2.3. The terms “hereof”, “herein”, “hereby”, “hereto” and derivative or similar words refer to this entire Agreement or specified Clauses of this Agreement, as the case may be;

2.4. The term “Clause” or “Schedule” refers to the specified Clause or Schedule of this Agreement;

2.5. Heading and bold typeface are only for convenience and shall be ignored for the purposes of interpretation;

2.6. reference to any legislation or Applicable Law or to any provision thereof shall include references to any such Applicable Law as it may, after the Agreement Date, from time to time, be amended, supplemented or re-enacted, and any reference to a statutory provision shall include any subordinate legislation made from time to time under that provision;

2.7. reference to any agreement, document or any provision thereof shall include references to such agreement, document or provision thereof as it may from time to time, be amended, amended and restated, modified or supplemented;

2.8. Reference to the word “include” shall be construed without limitation.

3. SCOPE OF THIS MSA
3.1. This Agreement shall principally govern the contract(s) formed under the related SOF herewith which will contain Service(s) and commercial related specific terms .

3.2. Subject to the terms of this Agreement and payment of charges, Yotta shall provide the Customer Services as agreed under the SOF.

3.3. Service Commencement Note (“SCN”):

     3.3.1. Yotta will communicate to Customer about the provisioning of the Service(s) through a written note (i.e., SCN).

     3.3.2. Customer shall confirm the provisioning of Service(s) within the time frame as provided under the SCN . Service(s) shall be deemed to be delivered in case if there is no confirmation from the Customer.

     3.3.3. The date of Service provisioning as mentioned in the SCN shall be deemed as the billing commencement date for the particular Service(s).

     3.3.4. The Service(s) delivery date for individual Service(s) under a SOF may differ and billing of each line items shall commence for such service(s) as and when they are provisioned/delivered.

4. PAYMENT AND INVOICING
4.1. Charges: The Customer shall pay the charges as specified in SOF. The payment obligations are non- cancellable, and charges paid are non-refundable.

4.2. Invoicing and Payment: All charges will be invoiced in advance or arrears as may be mutually agreed under the SOF and payment terms shall be more specifically set out in the SOF .

4.3. All invoice(s) dispute claims must be delivered through email to Yotta within 5 working days from the date of receipt of invoice, else such invoice(s) shall be deemed not disputed by the Customer and amounts thereunder shall be payable by the Customer. Further, credit notes, if any, raised by Yotta shall be accepted by the Customer on or before 16th of the subsequent month to the month in which credit note is issued by Yotta. If the Customer does not accept or reject the credit note within the time frame mentioned in this clause then Yotta shall have the right to recover the GST amount paid by Yotta. In case the Customer rejects the credit note, the Customer shall provide Yotta with the reason(s) for the same.

4.4. All amounts payable by Customer in terms hereof shall be made without any deduction, set-off or counter claim and free and clear of any deduction or other charges of whatever nature imposed by any taxation or government authority save and except Tax Deduction at Source (“TDS”) as per the rate prescribed by the prevailing Finance Act.

4.5. Yotta shall raise and issue a tax invoice for the Services pursuant to SOF(s) as per prevailing Goods and Services Tax laws & regulations and shall forward the digitally signed tax invoice to the registered email address of the Customer. Customer shall make payment of tax invoice as per credit period agreed in SOF.

4.6. Customer shall inform Yotta at-least 10 days prior to the date of invoice of any modification to its registration certificate under Goods and Services Tax (“GST”). Yotta will mention correctly all requisite information on invoice and the GST portal, as required under the GST laws including but not limited to correct amounts, place of supply, rate of tax, GSTIN of Customer as informed by Customer.

4.7. Customer hereby acknowledges that under the Agreement, the place of supply under Goods and Services Tax Act shall be the place of supply as determined under a SOF signed by Customer. It shall be the responsibility of the Customer to notify Yotta in writing 10 days prior to issuance of tax invoice. in case of deviation / disagreement with the place of supply as mentioned in the SOF and on rate of tax, billing location, HSN /SAC code and other particulars stated in SOF.

4.8. Yotta shall be responsible for performing all compliances and making payments of GST collected from Customer, cesses applicable under the GST laws & regulations.

4.9. Yotta shall not be liable for any damages for loss of GST credit to the Customer if it demonstrates that they complied with all the laws/rules and regulation under the GST and has filed all returns with correct details and the error/non receipt of credit to the Customer is beyond its act and/or control.

4.10. In case of any reverse charges is applicable on the services availed by the Customer, Yotta shall not charge the same on its invoice and Customer shall be liable to pay GST as applicable under domestic reverse charges/partial reserve charges provisions.

4.11. Yotta shall issue GST compliant receipt voucher to Customer, where in terms of the agreement, Customer pays advance amount for supply of goods/ Services. Further, Yotta shall issue refund voucher as prescribed under the GST Act in case no supply is made and no invoice is raised or the value of goods or services is less than the advance amount paid;

4.12. In the event the Customer fails to pay dues for Services as per related SOF, Yotta reserves the right to suspend, discontinue and / or terminate the Services and take back Yotta owned equipment, if any, by giving five (5) days' written notice to Customer. Notwithstanding to aforesaid herein, Customer shall not be absolved of any duties, responsibilities or liability as agreed under this Agreement.

4.13. Customer is under the obligation to inform Yotta of any errors that needs to be corrected and any changes to be affected within 5 working days from the date of the Invoice. All changes and modification in the Tax Invoices will be done by issuing a Credit note and/or Debit note. No Credit notes / Debit Notes will be issued post 31st October of the year following the financial year in which such supply or services was made or provided.

4.14. In case the customer is an SEZ customer, the SEZ Customer shall provide renewed LOA certificate or SEZ Validity certificate upon the expiry of the LOA. In the event of non-submission of renewed LOA or validity certificate, Yotta shall bill the customer as per the prevailing GST laws.

5. CUSTOMER’S RESPONSIBILITIES
(i) The Customer shall be responsible for compliance with this Agreement and terms of the SOF(s).

(ii) The Customer shall make payment to Yotta as per the invoice raised with reference to the SOF.

(iii) The Customer shall inform Yotta as under:
     a) within [5] days about any changes or plans in its IT infrastructure that might affect the delivered Service(s) or Service(s) provisioning under progress (if any).
     b) within [5] days about any changes in use of the Service(s).
     c) three (3) business days written intimation in advance to manage the visitor facilitation for Yotta Data Centre visit.

(iv) The Customer shall provide Yotta with a list of all authorised personnel and approved maintainers who shall be entitled to enter the Yotta Data Centre. The Customer will promptly inform Yotta in writing of any changes to the list of authorised personnel and approved maintainers.

(v) The Customer shall ensure that those people approved to have access to the Yotta Data Centre, are suitably competent to carry out the necessary tasks and that they are responsible for their own safety whilst on the Yotta Data Centre site.

(vi) Where the Customer or its authorised personnel enters the Yotta Data Centre, it is the Customer’s responsibility to ensure that the Customer racks(s) are (where applicable) securely locked before the Customer or its authorised personnel leaves the Yotta Data Centre.

(vii) The Customer shall be responsible for the accuracy, quality legality, means and processing of its data within the Yotta Data Center.

(viii) The Customer acknowledges and agrees that Yotta exercises no control whatsoever over the content, voice, data, or the information passing through the network within Yotta Data Centre premises including Customer's website(s) and Customer shall be solely responsible for compliance of applicable laws and regulations in terms of information and content that Customer and its users transmit and receive.

(ix) The Customer shall provide Yotta with complete and accurate information regarding any customization, current usage, or anticipated changes in the usage of the Service(s). The Customer acknowledges that Yotta will customize and deliver the Service(s) based on the requirements and information provided by the Customer, including design, build, including platform, infrastructure, or any other related components, Yotta shall not be obligated to maintain upgraded service levels and other commitments related to the Service(s) until the Service(s) capacity is appropriately upgraded pursuant to an applicable service levels between the Parties in writing.

(x) The Customer shall not reverse engineer, disassemble/ decompile the Service(s) or apply any other process/ procedure to derive the source code of any software included in the Service(s), access or use the Service(s) in a way intended to avoid incurring fees or exceeding usage limits or quotas, resell the Service(s) or misrepresent or embellish the relationship (implied affiliation except as expressly permitted by this Agreement).

(xi) The Customer shall where applicable:
     a) maintain log-in/log-out details of all its subscribers for network services provided such as internet access, e-mail, internet telephony, IPTV for a period of minimum 2 years.
     b) record and maintain the following SYSLOG Parameters for any Network Address Translation (NAT) mechanism deployed by the Customer for Internet access:
         I. as per para no:3 of DoT letter no: 8520-01/98- LR/Vol. (IX) Pt I dated 16/11/2021 and;
         II. DoT Letter No: 20-271/2010/AS-I (Vol:III) dated 21.12.2021 and its amendments if any. The Customer shall maintain logs for a minimum period of 2 years.

6. YOTTA’S RESPONSIBILITIES
6.1. Performance: Yotta shall provision and render Service(s) as per the agreed scope of work under the SOF.

6.2.Insurance: Yotta shall effect and maintain appropriate insurance for its equipments and facilities provided by Yotta in terms of provision of Service(s).

6.3.Support: Yotta shall facilitate reasonable support to Customer as and when so required as part of the agreed scope of work or otherwise undertaken in writing.

6.4.Data Protection: Yotta shall maintain reasonable administrative, physical, and technical safeguards for protection of the security, confidentiality, and integrity of data of the Customer to prevent unauthorized access thereto.

7. DATA PROTECTION AND PRIVACY
7.1. Business Data means any data pertaining to data of the Customer and hosted in the Yotta Data Center or the cloud or other facility of Yotta. Unless otherwise agreed in writing under the scope of work or SOF, Yotta shall have no visibility or control of the Business Data. Customer shall be solely responsible for the protection of its Business Data and shall ensure that the Business Data is under adequate security control.

7.2. Personal Data shall mean the data about any employee, director or signatory (natural person) of the Customer which is collected and processed by Yotta for providing Services and other lawful purposes including the process of Know Your Customer (KYC) as more specifically elaborated under Yotta’s privacy policy.

7.3. The Privacy Policy of Yotta is available at http://www.yotta.com/ in particular at https://www.yotta.com/privacy-policy/ describing how Yotta collects, handles, stores, and/or transmits personal data.

7.4. Customer is aware that Yotta may collect Personal Data during the process of due diligence and for the purposes aforesaid in preceding paragraph while providing Services. Customer hereby gives consent to Yotta to collect and process personal data in accordance with applicable laws and reasonable technical assurance.

7.5. The Parties shall comply with any data protection laws applicable to it in its processing of Personal Data pursuant to this Agreement.

8. CONFIDENTIALITY
8.1. The Parties shall endeavor to protect Confidential Information. In the context of the relationship under this Agreement, each party (“Disclosing Party”) may disclose to the other party (“Receiving Party”) certain confidential information that has been marked “confidential” or with words of similar meaning, at the time of disclosure by such party (“Confidential Information”). Yotta’s Confidential Information shall deem to include, without limitation, the pricing oServices, business proposals, technical documentation, integration methodologies, technical data, methods, processes, know-how and inventions. Confidential Information shall not include information that Receiving Party can show: (a) was already lawfully known to, or independently developed by, Receiving Party without access to, or use of, Confidential Information, (b) was received by Receiving Party from any third party without restrictions, (c) is publicly and generally available, free of confidentiality restrictions; or (d) is required to be disclosed by law, regulation or is requested in the context of a law enforcement investigation.

8.2. Upon request by the disclosing party at any time during the term of the Agreement or within thirty (30) days of termination thereof, receiving party shall promptly return to the disclosing party or destroy at the disclosing party’s option all documents and materials (including computer media) containing any Conﬁdential Information, together with any copies thereof which are in receiving party’s possession or control, provided that such information is in a form which is capable of delivery or destruction. Nothing in this section obliges a party to return or destroy any document or information which (i) must be retained for compliance purposes; (ii) is contained in backups which cannot be practicably deleted; or (iii) which must be retained as required by Applicable Law.

9 REPRESENTATION AND WARRANTIES
9.1. Each Party represents and warrants that: (a) it is duly organized under Applicable Law and has sufficient authority to enter into this Agreement, and (b) the person entering into this Agreement is authorized to sign this Agreement on behalf of such party

9.2. The Parties will not knowingly violate or infringe the rights of either party and/or any third party, including Intellectual Property Rights (“IPR”), contractual, employment, trade secrets, proprietary information, and non-disclosure rights, or any and shall not violate Applicable Law. Any trade secrets, inventions, copyrights, and other intellectual property that is conceived, made, or developed in whole or in part by Yotta (including any developed jointly with) during or as a result of our relationship with Customer shall become and remain the sole and exclusive property of Yotta (unless otherwise agreed in writing therefor).

9.3. The Services shall be provided as per the service description under the SOF. The Service Level commitments shall be as per the Service Level Agreement (“SLA”) agreed in writing. The SLA shall be the only warranty about the service in contract and disclaims all implied and statutory warranties, including, but not limited to, any implied warranty of merchantability, fitness for a particular purpose.

9.4. The Parties agree that Yotta shall not be responsible for any issues related to the performance, operation or security of the Services that arise from Customer’s applications or third-party applications. Notwithstanding anything contained herein, parties agree that the Services may contain third party service component also such third party service provider shall be solely responsible and liable therefor as per the terms and conditions of such third party service contracts .Yotta does not make any representation or warranty regarding the reliability, accuracy, completeness, authenticity, merchantability, non-infringement, correctness, or usefulness of the information and data, third-party applications, or services, and disclaims all liabilities arising from or related to such third party applications or services.

10 INDEMNIFICATION
10.1. Notwithstanding anything contained in this Agreement, the Parties shall defend, indemnify and hold harmless each other upon demand from and against any and all damages, actions, proceedings, claims, demands, costs, losses, liabilities, expenses (including court costs and reasonable attorneys’ legal fees) in connection with, arising out of, or in relation to:
     i. breach or non-compliance of its representations or warranties;
     ii. misrepresentation, gross negligence, fraud, willful concealment and misconduct;
     iii. misuse of the Services provided by Yotta for any illegal or unauthorized purposes;
     iv. any claim related to breach of third party IPR and
     v. Breach of Applicable Law.

11 LIMITATION OF LIABILITY
11.1. In no event, Parties, its directors, officers, employees, affiliates or agents shall be liable for any consequential, indirect, special, incidental or punitive damages, or any loss of profits, revenue, data or data use, arising out of, or relating to, the Services or the arrangements between the Parties.

11.2. Yotta shall not be liable for:
     a) any damage or destruction of Customer equipment, tangible material or software or Business Data belonging to and is under the control of Customer resulting from any cause whatsoever other than gross negligence or willful misconduct of Yotta.

     b) any direct or indirect damage (including without limitation, lost or corrupted data, lost profits or savings, loss of business, business disruption or other economic loss) arising out of security breaches, incorrectly supplied customer information including third party, malfunctioning or improperly working or improperly used or incompatible systems, hardware and or hardware components of the Customer.

11.3. The liability of Yotta in respect of the service performance shall be limited to the amount of service credits as agreed under the respective SLA.

11.4. Save and except as aforesaid under this clause, in all other cases of liability claim, the cumulative maximum liability of Yotta, its directors, officers, employees, affiliates or agents, whether in contract or tort or damages or indemnification claims or negligence, by statute or otherwise, including arising out of the work or deliverables or services offered by this Agreement, and regardless of the theory of liability, shall be limited to payment of incurred and suffered direct damages only and shall in no event exceed twenty five percent (25%) of the charges received by Yotta in preceding Six (6) months from the date of such liability arises, from the Customer.

TERM, TERMINATION AND EFFECT OF TERMINATION
12.1. Term : The terms and condition herein and as contained in the SOF(s) shall be effective from the date of issue of the related SOF(s) and shall remain in force until expiry or termination of the related Service(s) / SOF(s).

12.2. Term of Service(s) or SOF(s): The Service(s) duration of a Service(s) / SOF(s) shall be mentioned in the SOF and shall be the initial contract period therefor. Service(s) specific contractual terms and conditions shall be mentioned in the respective SOF.

12.3.Termination :
     (i) Either party may terminate this Agreement:
         a) if the other party commits a breach of any of the terms and conditions of this Agreement, which if capable of cure or remedy, is not cured or remedied by the other party, within a period of thirty (30) days from the date of receipt of such notice from the non-breaching party, or
         b) other party is restricted, prohibited or constrained under Applicable Law from continuing to provide or avail Service(s) respectively, under this Agreement,
             c) the other party acts in violation of Applicable Law,
         d) the other party is adjudicated bankrupt, or if a receiver or a trustee is appointed for it or for a substantial portion of its assets, or if any assignment for the benefit of its creditors is made and such adjudication appointment or assignment is not set aside within 90 (ninety) days, or
         e) liquidation proceedings are initiated either voluntarily or compulsorily against the other party.      ii) Yotta may suspend or terminate the Service(s) by providing thirty (30) days prior written notice to the Customer for non-payment of invoiced amount within the applicable due date.

12.4. Effect of Termination

12.4.1. Service(s) under the contract shall terminate with immediate effect of termination and with no liability on Yotta.

12.4.2. Customer shall be liable to pay and Yotta will be entitled to receive accrued or outstanding payment (if any) in accordance with the related SOF and have the rights of an unpaid seller under Applicable Laws.

12.4.3. Service(s) running under existing SOF(s) shall continue to be governed by the terms and conditions of this Agreement till full and final settlement of the Service(s) accounts.

12.4.4. Parties shall forthwith cease usage of all Intellectual Property Rights of the other party to this Agreement.

12.4.5. In case of Service(s) where there is allocation of a Designated Customer Area within the Yotta Data Center facility:
     a) access to such allocated area (except common areas such as reception, etc.), may be suspended or terminated. However, access to aforesaid areas shall be allowed only subject to clearance of payment of dues.
     b) If the Designated Customer Area is not vacated within the timeline specified, the Customer shall pay 200% of the monthly recurring charges (MRC) from the date of termination till the Designated Customer Area is returned to Yotta.
     c) Notwithstanding anything to the contrary contained in this Agreement, in the event the Customer fails to pay Yotta all dues owed under this Agreement within ten (10) days from the date of termination of any particular SOF or this Agreement, Yotta shall have the right to restrict the Customer/its representatives from accessing the Designated Customer Area and the Customer Equipment and will have right to retain the Customer Equipment until the Customer pays the dues as aforesaid (without being liable to prosecution or damages).

12.4.6. Within fifteen (15) days following the termination or expiration, Yotta shall permanently delete or purge all Customer data stored on any equipment provided by Yotta during the service term, including but not limited to server(s), without any further notice to the Customer. Yotta shall thereafter be entitled to use such equipment for its other business operations.

GENERAL PROVISIONS
13.1. Third Party Service Providers: Yotta may use third-party service providers, including application service providers, hosting service providers and system integrators for rendering Service(s).

13.2. Performance of obligation: Yotta shall be exempted from performance hereunder, without any liability, to the extent that performance is prevented, delayed or obstructed by circumstances beyond its reasonable control. Such circumstances may be including but not limited to an act of God, act of government, flood, fire, earthquake, civil unrest, act of terror, strike or other labor problem, a virus attack on the Customer’s system leading to disruption, issues with File Transfer Protocol (FTP) access from the Customer’s system, emergency maintenance upgrades or government restrictions (including the denial or cancellation of any licenses).

13.3. Anti-Corruption: The Customer agrees and confirms that it has not received or been offered any illegal or improper bribe, kickback, payment, gift, or thing of value from an employee or agent of Yotta in connection with this Agreement.

13.4. Entire Agreement and Order of Precedence: This Agreement along with the SOF represents the entire agreement between the parties regarding the subject matter hereof and supersedes any and all other agreements between the parties, whether written or oral, regarding the subject matter hereof. For clarity, the provisions of this Agreement supersede any earlier non-disclosure or confidentiality agreements, purchase orders or in any other Customer documentation (excluding Service Order Forms). In the event of any conflict or inconsistency among the following documents, the order of precedence shall be: (1) the applicable Service Order Form, (2) this Agreement and (3) Acceptable Use of Products and Services (available at : https://www.yotta.com/acceptable-use-of-products-and-services and Privacy Policy available at http://www.yotta.com/ in particular at https://www.yotta.com/privacy-policy/ .

13.5. Relationship: The parties are independent contractors. This Agreement does not create a partnership, franchise, joint venture, agency, fiduciary or employment relationship between the parties.

13.6. Waiver: No failure or delay by either party in exercising any right under this Agreement will constitute a waiver of that right.

13.7. Severability: If any provision of this Agreement is held by a court of competent jurisdiction to be contrary to law, the provision will be deemed null and void, and the remaining provisions of this Agreement will remain in effect.

13.8. Assignment: The Customer shall not assign any of its rights and obligations under this Agreement without the prior written consent of Yotta. Yotta may, in its sole and absolute discretion, assign, novate, transfer or otherwise dispose of any or all of its rights and obligations under this Agreement or any part thereof including but not limited to the right to payments, to any of its Affiliates, successors, associates or any other third parties or Persons in order to exercise any of the rights or perform any of the obligations under this Agreement, and the Customer shall, at Yotta’s intimation, enter into an appropriate agreement with such Affiliates, successors, associates or any other third parties or Persons in such form as Yotta may specify in order to enable Yotta to exercise its rights pursuant to this Clause. A change in the legal status of Yotta shall not affect the validity of this Agreement and this Agreement shall be binding on any successor to Yotta.

13.9. No Tenancy Contract: Customer agrees and acknowledges that this Agreement is merely a Service Agreement and neither intended nor constitutes a lease, leave and license or any mode of tenancy agreement of any real estate, or the creation of any real estate interest in any part and parcel of the Yotta Data Centre from where the Service is rendered. Customer has no rights as a tenant or otherwise under any applicable tenancy laws.

13.10. Amendment: This Agreement may not be modified except by an instrument in writing signed by the duly authorized representatives of the Parties.

13.11. Audit: In case the Customer desires to audit the Service(s) contracted, the Customer shall notify Yotta with at least fifteen (15) days prior written notice for such audit. The scope and timelines of the audit shall be mutually agreed between Customer and Yotta in writing. In a year more than two audits shall attract commercials depending on mutually agreed scope.

13.12. Counterparts: This Agreement may be executed by electronic mode or in any other means, and in any number of counterparts, each of which shall constitute and deemed to be an original, but all of which when taken together shall constitute a single Agreement 13.13. Arbitration: Any disputes, controversies or disagreements relating to this Agreement, including but not limited to any question regarding its existence, validity or termination, shall be settled amicably by the Parties. In case of failure of the Parties to settle such dispute/s within fifteen (15) days of one-Party giving notice of such dispute/ breach to the other Party, either Party shall be entitled to refer the dispute to the sole arbitrator who shall be appointed by mutual agreement of both the Parties. The arbitration proceedings shall be conducted in Mumbai and the same shall be governed by the provisions of the Arbitration and Conciliation Act, 1996 in force or any subsequent amendment or re-enactment thereof. The language of arbitration shall be English.

13.14. Governing Law and Jurisdiction: This Agreement shall be governed by and construed in accordance with the laws of India, without regard to conflict of law principles. The courts, tribunals, councils, forums and other dispute resolution bodies in India shall have the exclusive jurisdiction to adjudicate upon any or all disputes arising out of or in connection with this Agreement.

13.15. Notice: The Customer shall direct notices under this Agreement to the following address.

     Attn: i. helpdesk@yotta.com for any non-legal general communication, and;

     ii. legal@yotta.com for any Legal Notice communication.

13.16. Survival: Clause 1 (Definitions), Clause 4 (Payment and Invoicing), Clause 5 (Customer Responsibilities), Clause 6 (Yotta Responsibilities), Clause 7 (Data Protection and Privacy), Clause 8 (Confidentiality), Clause 9 (Representation and Warranties), 10 (Indemnification), Clause 11 (Limitation of Liability), Clause 12 (Term, Termination and Effect of Termination) and Clause 13 (General Provisions) shall survive termination or expiration of this Agreement.

IN WITNESS WHEREOF
the Parties have executed this Agreement through their authorized signatories

''';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF283E81,
      ), // Same as GlobalColors.mainColor
      body: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset('assets/images/loginbg.jpg', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FE), // Same as RegisterView card color
                borderRadius: BorderRadius.only(
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
                      if (_step == 0) ...[
                        Center(
                          child: Text(
                            'Basic Details',
                            style: TextStyle(
                              color: Color(0xFF283E81),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: accountNameController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Account Name',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Account Name is required'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: panApplicable,
                          onChanged:
                              (selectedCountry == 'India')
                                  ? (val) {
                                    setState(() {
                                      panApplicable = val ?? false;
                                      if (!panApplicable) panController.clear();
                                    });
                                  }
                                  : null,
                          title: const Text('PAN Applicable'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (panApplicable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: panController,
                              enabled: selectedCountry == 'India',
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                labelText: 'PAN',
                                border: OutlineInputBorder(),
                                errorMaxLines: 3,
                              ),
                              validator: (value) {
                                if (panApplicable &&
                                    (value == null || value.isEmpty)) {
                                  return 'PAN is required';
                                }
                                if (panApplicable &&
                                    !RegExp(
                                      r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
                                    ).hasMatch(value ?? '')) {
                                  return 'PAN must be in (5 Alphabets, 4 Digit, 1 Alphabet) format';
                                }
                                return null;
                              },
                            ),
                          ),
                      ] else if (_step == 1) ...[
                        Center(
                          child: Text(
                            'Address Details',
                            style: TextStyle(
                              color: Color(0xFF283E81),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: addLineOneController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Address Line 1',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Address Line 1 is required'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: addLineTwoController,
                          decoration: const InputDecoration(
                            labelText: 'Address Line 2',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cityController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'City is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: postalCodeController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            border: OutlineInputBorder(),
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Postal Code is required';
                            if (selectedCountry == 'India') {
                              if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                                return 'Postal Code must contain 6 digits';
                              }
                              if (value == '000000') {
                                return 'Postal Code can not be 000000';
                              }
                            } else {
                              if (!RegExp(
                                r'^[a-zA-Z0-9]{1,10}$',
                              ).hasMatch(value)) {
                                return 'Postal Code must contain 10 alpha numeric characters';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCountry,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              countryNames
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedCountry = val;
                              stateNames =
                                  countryStateList
                                      .where((e) => e['countryName'] == val)
                                      .map((e) => e['stateName'] as String)
                                      .toList()
                                    ..sort();
                              selectedState = null;
                              if (val != 'India') {
                                gstApplicable = false;
                                panApplicable = false;
                                sez = '2';
                              } else {
                                sez = '0';
                              }
                            });
                          },
                          validator:
                              (v) =>
                                  v == null || v == 'Select Country'
                                      ? 'Select Country'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedState,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              stateNames
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => selectedState = val),
                          validator: (v) => v == null ? 'Select State' : null,
                        ),
                      ] else if (_step == 2) ...[
                        Center(
                          child: Text(
                            'Taxation',
                            style: TextStyle(
                              color: Color(0xFF283E81),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          value: gstApplicable,
                          onChanged: (val) {
                            setState(() {
                              gstApplicable = val ?? false;
                              if (!gstApplicable) gstinController.clear();
                            });
                          },
                          title: const Text('GST Applicable'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (gstApplicable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: gstinController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN',
                                border: OutlineInputBorder(),
                                errorMaxLines: 3,
                              ),
                              validator: (value) {
                                if (gstApplicable &&
                                    (value == null || value.isEmpty)) {
                                  return 'GSTIN is required';
                                }
                                if (gstApplicable &&
                                    !RegExp(
                                      r'^[0-9]{2}([a-zA-Z]){5}[0-9]{4}([a-zA-Z]){1}[0-9]{1}([a-zA-Z]){1}[0-9A-Za-z]{1}$',
                                    ).hasMatch(value ?? '')) {
                                  return 'GSTIN must be in (2 Digit, 5 Alphabets, 4 Digits, 1 Alphabet, 1 Digit, 1 Alphabet, 1 Digit/Alphabet) format';
                                }
                                return null;
                              },
                            ),
                          ),
                        if (selectedCountry == 'India') ...[
                          RadioListTile<String>(
                            value: '0',
                            groupValue: sez,
                            onChanged: (val) => setState(() => sez = val),
                            title: const Text(
                              'Indian Organization or Individual (Non-SEZ)',
                            ),
                          ),
                          RadioListTile<String>(
                            value: '1',
                            groupValue: sez,
                            onChanged: (val) => setState(() => sez = val),
                            title: const Text(
                              'Indian Organization or Individual (Located in a SEZ)',
                            ),
                          ),
                        ] else if (selectedCountry != null &&
                            selectedCountry != 'Select Country') ...[
                          RadioListTile<String>(
                            value: '2',
                            groupValue: sez,
                            onChanged: null,
                            title: const Text(
                              'Non-Indian Organization or Individual (Located outside India)',
                            ),
                          ),
                        ],
                        if (showSezError)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Text(
                              'Select option applicable',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Checkbox(
                              value: agreeTerms,
                              onChanged: (value) {
                                setState(() {
                                  agreeTerms = value!;
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
                                    const TextSpan(text: "I agree to the "),
                                    TextSpan(
                                      text: "Master Service Agreement *",
                                      style: const TextStyle(
                                        color: Color(0XFF283E81),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              _showPolicyDialog(
                                                context,
                                                "Master Service Agreement (MSA)",
                                                _MSAContent,
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_step == 3) ...[
                        if (sez == '1') ...[
                          Center(
                            child: Text(
                              'LOA Details',
                              style: TextStyle(
                                color: Color(0xFF283E81),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: lutNumberController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              labelText: 'LOA Certificate Number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please Enter LOA Certificate Number';
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: lutExpiryController,
                            readOnly: true,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              labelText: 'LOA Certificate Expiry Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please Enter valid LOA Certificate Expiry Date';
                            },
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setState(() {
                                  lutExpiryController.text =
                                      "${picked.day}-${picked.month}-${picked.year}";
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          InkWell(
                            onTap: () async {
                              await pickAndValidatePdf(context, setState);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.upload_file),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      uploadedDocumentName != null
                                          ? uploadedDocumentName!
                                          : 'Upload LOA Certificate',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Center(
                            child: Text(
                              'Do you want to submit onboarding?',
                              style: TextStyle(
                                color: Color(0xFF283E81),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  size: 80,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'You can proceed to submit your onboarding details.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          !onboardStatus
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: FloatingActionButton(
                        heroTag: 'back',
                        backgroundColor: Color(0xFF283E81),
                        foregroundColor: Colors.white,
                        onPressed: _prevStep,
                        child: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                      ),
                    ),
                  const Spacer(),
                  if (_step < 3)
                    Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: FloatingActionButton(
                        heroTag: 'next',
                        backgroundColor: Color(0xFF283E81),
                        foregroundColor: Colors.white,
                        onPressed: _nextStep,
                        child: const Icon(Icons.arrow_forward),
                        tooltip: 'Next',
                      ),
                    ),
                  if (_step == 3)
                    Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: FloatingActionButton(
                        heroTag: 'submit',
                        backgroundColor: Colors.green,
                        onPressed: () async {
                          if (_formkey.currentState!.validate() && agreeTerms) {
                            if (sez == null) {
                              setState(() {
                                showSezError = true;
                              });
                              return;
                            } else {
                              setState(() {
                                showSezError = false;
                              });
                            }
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              if (sez == '1') {
                                await uploadFile(context);
                              }
                              final response = await _onboardService
                                  .completeOnboarding(
                                    accountName: accountNameController.text,
                                    pan: panController.text,
                                    gstin: gstinController.text,
                                    addressLine1: addLineOneController.text,
                                    addressLine2: addLineTwoController.text,
                                    city: cityController.text,
                                    postalCode: postalCodeController.text,
                                    country: selectedCountry!,
                                    state: getStateId(selectedState)!,
                                    addressType: addressType!,
                                    sez: sez,
                                    showMSA: agreeTerms,
                                    addressLUTNumber: lutNumberController.text,
                                    addressLUTExpiry:
                                        lutExpiryController.text.isNotEmpty
                                            ? DateFormat(
                                              'dd-MM-yyyy',
                                            ).parse(lutExpiryController.text)
                                            : null,
                                    contactFirstName: contactFirstName,
                                    contactLastName: ContactLastName,
                                  );
                              if (response.statusCode == 200) {
                                setState(() {
                                  onboardStatus = true;
                                });
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(),
                                  ),
                                );
                              } else {
                                _showError('Failed to complete onboarding');
                              }
                            } catch (e) {
                              _showError('An error occurred. Please try again');
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                        child:
                            isLoading
                                ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                : const Icon(Icons.check),
                        tooltip: 'Submit',
                      ),
                    ),
                ],
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

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
}
