import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/session/ticket_data_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class TicketListService {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> projectList = [];

  Future<http.Response> getTicketData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }
    print('Calling Account data API...');
    print('Token: $token');
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/get_dashboard_details'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "accountID": sto,
         "auto": "No",
        "type": "Incident,Service Request"
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      TicketDataManager().setTicketData(jsonData);
    }

    return response;
  }

  Future<http.Response> getDomainCategorySubCategory() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];
 final postJson = {
    "flag": "External",
    "externalSource": "Myaccount",
    "externalID": "MP-123456",
    "type": "Incident",
  };
    if (token == null) {
      throw Exception('Access token not found.');
    }
 
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/getCatSubCat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        postJson),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      TicketDataManager().setCatSubcatData(jsonData);
    }

    return response;
  }

  
  Future<http.Response> getDomainCategorySubCategoryServRequest() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];
 final postJson = {
     "flag":"External",
      "externalSource": "Myaccount",
      "externalID": "MP-123456",
      "type":"Service Request"
  };
    if (token == null) {
      throw Exception('Access token not found.');
    }
 
    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/getCatSubCat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        postJson),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      TicketDataManager().setCatSubDataServRequest(jsonData);
    }

    return response;
  }

  Future<http.Response> getProjectList() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];
  final Map<String, dynamic> postJson = {
    "billToCRMID": bto,
    "supportToCRMID": sto,
    "externalID": "IDE-12345",
    "externalSource": "INDIQUS"
  };
  final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/get_project'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        postJson),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      TicketDataManager().setProjectListData(jsonData);
    }
 return response;
 
}


Future<List<Map<String, dynamic>>> loadCustomerList() async {
    List<Map<String, dynamic>> customerList = [];

    // final userData = jsonDecode(localStorage.getItem('details') ?? '{}');
    final crmIds = SessionManager().getSessionData();

    final accounts = AccountDataManager().getAccountStoBtoData();

    if (accounts?['support_to_customers'] != null &&
        accounts?['support_to_customers'].isNotEmpty) {
      customerList = List<Map<String, dynamic>>.from(accounts?['support_to_customers']);
    } else {
      final sto = {
        "support_to_cust_sfid": "",
        "support_to_custid": crmIds != null && crmIds['bto'] != null
    ? int.tryParse(crmIds['bto'].toString()) ?? 0
    : 0,
        "support_to_customername": accounts?['accountName']
      };
      customerList.add(sto);
    }
    return customerList;
  }

}