import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/asset_data_manager.dart';
import 'package:myaccount/services/app_services/session/order_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<http.Response> getOrdersHeadDetails() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.post(
      Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/order/order_head_details'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [bto],
        "support_to_customerid": [sto],
        "sof_no": []
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      OrderDataManager().setOrderData(jsonData);
    }

    return response;
  }

  Future<http.Response> getOrderLineDetails(
      String sofNo, String lineItemId) async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.post(
      Uri.parse(
          'https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/order/order_line_details'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": [bto],
        "support_to_customerid": [sto],
        "sof_no": [sofNo],
        "line_item_id": [lineItemId]
      }),
    );

    return response;
  }




  Future<http.Response> getDocumentData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/kyc/docs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "accountNumber": bto,
        "docType": 'Contract',
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print(jsonData);
      // OrderDataManager().setOrderData(jsonData);
    }

    return response;
  }


  //   fetchDocumentData(bto,sto){
  //   this.userData = JSON.parse(localStorage.getItem('userData'));
  //     let data = {}
  //     data["accountNumber"] = this.userData.acctType == 'End User' ? sto:bto;
  //     data["docType"]='Contract';

  //     this.http.post(`https://uatmyaccountapi.yotta.com/my_crm/api/v1/crm/kyc/docs`, data).subscribe(res=>{
  //       // let documentData = res['documentWrapperList'] || [];
  //       this.setDocumentData(res);
  //     })
  //  }
}