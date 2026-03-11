import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/financials/payment/data/payData.dart';
import 'package:myaccount/screens/modules/financials/payment/pages/webview_page.dart';
import 'package:myaccount/screens/modules/financials/wallet.dart';
import 'package:myaccount/screens/modules/profile/company_profile.dart';
import 'package:myaccount/services/app_services/account_data_service.dart';
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/wallet_service/wallet_service.dart';
import 'dart:async';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:myaccount/widgets/common_message_toast.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html;


class AddMoneyPage extends StatefulWidget {
  const AddMoneyPage({super.key});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  String selectedCurrency = 'INR';
  TextEditingController amountController = TextEditingController();
  TextEditingController tdsController = TextEditingController();
  double remainingAmount = 0.0;
  bool isAnimating = false;
  bool applyTds = false;
  bool giveConsent = true;
  final FocusNode _tdsFocusNode = FocusNode();
  String? tdsErrorText;
  late String sessionData;
Timer? _debounce;

  Future<void> _addMoney() async {
    if (amountController.text.isEmpty || double.tryParse(amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    
    // CommonMessageToast.showMessage(
    //   context,
    //   QuickAlertType.success,
    //   "Operation completed successfully!",
    //   "Ok"
    // );


  try {
    final response = await WalletService().addMoneyInWallet(
      amount: int.parse(amountController.text.trim()),
      applyTds: applyTds,
      tdsAmount: selectedCurrency=='INR'?int.tryParse(tdsController.text.trim()):0 ,
      consentGiven: giveConsent== true ? 1:0,
      net_amount: remainingAmount
    );

    if (response.statusCode == 200) {
      // Do something with response.body if needed
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (!mounted) return;

      // Close dialog
      Navigator.of(context).pop();

      // Open WebView
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => WebviewPage(
            data: PaymentData.fromJson(data),
          ),
        ),
      );

      if (result == true && mounted) {
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WalletView()),
        );
      }
    } else {
      CommonMessageToast.showMessage(
        context,
        QuickAlertType.error,
        "Failed to add money",
        "Status: ${response.statusCode}",
      );
    }
  } catch (e) {
    CommonMessageToast.showMessage(
      context,
      QuickAlertType.error,
      "Error occurred",
      e.toString(),
    );
  }
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isAnimating = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WalletView()),
      );
    });
  }

    @override
    void initState() {
      super.initState();
        var accountData = AccountDataManager().getAccountData(); 
         _tdsFocusNode.addListener(() {
        if (!_tdsFocusNode.hasFocus) {
          _validateTDS();
        }
      });
      giveConsent = accountData?['accountWalletConsent']==1 ? true : false;
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: const CommonAppBar(title: 'Add Money'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FE),
          // borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          border: Border.all(width: 1.0,color: GlobalColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _currencyButton('INR', '₹'),
                const SizedBox(width: 10),
                _currencyButton('USD', '\$'),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
              flex: 2,
              child:
              TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _calculateTDS();
    });
  },
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.black87),
              decoration: InputDecoration(
                prefixText: selectedCurrency == 'INR' ? '₹ ' : '\$ ',
                prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter Amount',
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),),
            // const SizedBox(width: 12),

            //       Expanded(
            //         flex: 1,
            //       child: DropdownButtonFormField<String>(
            //         value: selectedCurrency,
            //         items: ['INR', 'USD'].map((currency) {
            //           return DropdownMenuItem(
            //             value: currency,
            //             child: Text(currency),
            //           );
            //         }).toList(),
            //         onChanged: (value) {
            //           setState(() {
            //             selectedCurrency = value!;
            //           });
            //         },
            //         decoration: const InputDecoration(
            //           labelText: 'Currency',
            //           border: OutlineInputBorder(),
            //         ),
            //       ),
            //       )
                  
            ],),
            const SizedBox(height: 16),

            // Apply TDS
            if(selectedCurrency == 'INR')
            Row(
              children: [
                Checkbox(
                  value: applyTds,
                  onChanged: (value) {
                    setState(() {
                      applyTds = value!;
                      _calculateTDS();
                    });
                  },
                ),
                const Text('* Apply TDS on amount'),
              ],
            ),

            if(applyTds && selectedCurrency == 'INR')...[
              TextField(
              controller: tdsController,
                focusNode: _tdsFocusNode,
              keyboardType: TextInputType.number,
              // onChanged: (value) {
              //   _calculateTDS();

              // },   
              onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _validateTDS();
                  });
                },           
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.black87),
              decoration: InputDecoration(
                prefixText: selectedCurrency == 'INR' ? '₹ ' : '\$ ',
                prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'TDS Amount: Max 10% of Entered Amount',
                hintStyle: TextStyle(color: Colors.grey[500]),
                errorText: tdsErrorText, 
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Net Amount: ${selectedCurrency == 'INR' ? '₹' : '\$'} ${remainingAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ],
            
            // Consent with edit icon
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: giveConsent,
                  onChanged: (value) {
                    setState(() {
                      giveConsent = value!;
                    });
                  },
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '* I give consent to use my wallet balance for clearing the invoice(s) dues.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      Tooltip(
                        message: 'Change consent status from Company Profile',
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompanyProfileView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: tdsErrorText != null ? null : _addMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF283e81),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  elevation: 3,
                ),
                child: const Text(
                  'Add Money',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (isAnimating)
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Adding Money...',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Image.asset('assets/animations/wallet_animation.gif', height: 100),
                  ],
                ),
              ),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _currencyButton(String currency, String symbol) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCurrency = currency;
          });
          _onCurrencyChanged(selectedCurrency);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedCurrency == currency ? Colors.blueAccent : Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
        ),
        child: Text(
          '$symbol $currency',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: selectedCurrency == currency ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

//   void _submitToGateway(String encRequest, String accessCode, String merchantId) {
//   final html = '''
//     <html>
//       <body onload="document.forms[0].submit()">
//         <form method="POST" action="https://secure.paymentgateway.com/transaction">
//           <input type="hidden" name="encRequest" value="$encRequest" />
//           <input type="hidden" name="access_code" value="$accessCode" />
//           <input type="hidden" name="merchant_id" value="$merchantId" />
//         </form>
//       </body>
//     </html>
//   ''';

//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => PaymentWebView(htmlContent: html),
//     ),
//   );
// }


// void _submitToGateway(String encRequest, String accessCode, String merchantId) {
//   final form = html.FormElement()
//     ..method = 'POST'
//     ..action = 'https://secure.ccavenue.com/transaction/transaction.do?command=initiateTransaction&merchant_id={{merchantId}}&access_code={{accessCode}}&encRequest={{encRequest}}';

//   final encRequestInput = html.InputElement()
//     ..type = 'hidden'
//     ..name = 'encRequest'
//     ..value = encRequest;

//   final accessCodeInput = html.InputElement()
//     ..type = 'hidden'
//     ..name = 'access_code'
//     ..value = accessCode;

//   final merchantIdInput = html.InputElement()
//     ..type = 'hidden'
//     ..name = 'merchant_id'
//     ..value = merchantId;

//   form.children.addAll([encRequestInput, accessCodeInput, merchantIdInput]);

//   html.document.body!.append(form);
//   form.submit();
// }
void _calculateTDS() {
  if(applyTds){
 final amountText = amountController.text.trim();
  if (amountText.isEmpty) return;

  final amount = double.tryParse(amountText);
  if (amount != null) {
    // final tds = (amount * 0.10);
    // // final remaining = (amount * 0.90).toStringAsFixed(2);
    // final remaining = (amount * 0.90).toStringAsFixed(2);
    // final maxTDS = amount * 0.10;

    // tdsController.text = tds.toString();
    //  if (tds > maxTDS) {
    // setState(() {
    //   tdsErrorText = 'TDS cannot exceed 10% of the amount';

    // });
    
  // } else {
  //   setState(() {
  //     tdsErrorText = null;
  //   });
  // }
  //   setState(() {
  //     remainingAmount = double.parse(remaining);
  //   });

  final tds = (amount * 0.10).toStringAsFixed(2);
    final remaining = (amount * 0.90).toStringAsFixed(2);

    tdsController.text = tds;
    setState(() {
      remainingAmount = double.parse(remaining);
    });
  }}else{
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    remainingAmount = amount;
  }
}

void _onCurrencyChanged(String currency) {
  setState(() {
    selectedCurrency = currency;
    final amount = double.tryParse(amountController.text.trim()) ?? 0;

    if (selectedCurrency == 'USD') {
      tdsController.text = '0.00';
       tdsErrorText = null;
      remainingAmount = amount;
    } else {
      _calculateTDS();

    }
  });
}

void _validateTDS() {
  final tds = double.tryParse(tdsController.text) ?? 0.0;
  final amount = double.tryParse(amountController.text) ?? 0.0;

  final maxTDS = amount * 0.10;

  if (tds > maxTDS) {
    setState(() {
      //  ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('TDS cannot exceed 10% of the amount')),
      // );
      tdsErrorText = 'TDS cannot exceed 10% of the amount';

    });
  } else {
    setState(() {
      tdsErrorText = null;
    });
  }
}
void _submitToGateway(String encRequest, String accessCode, String merchantId) async {
  final url = Uri.https(
    'test.ccavenue.com',
    'transaction/transaction.do',
    {
      'command': 'initiateTransaction',
      'merchant_id': merchantId,
      'access_code': accessCode,
      'encRequest': encRequest,
    },
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // Use LaunchMode.inAppWebView if preferred
    );
  } else {
    throw 'Could not launch $url';
  }
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
}