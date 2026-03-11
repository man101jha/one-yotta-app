import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/account_data_manager.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class AccountsService {
  final AuthService _authService = AuthService();

  Future<http.Response> getAccountsData() async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    if (token == null) {
      throw Exception('Access token not found.');
    }

    print('Calling session starter API...');
    print('Token: $token');

    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_crm/api/v1/account/get_accounts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bill_to_customerid": bto,
      }),
    );

    // print('Response code: ${response.statusCode}');
    // print('Response body here1: ${response.body}');
    final Map<String, dynamic> data = jsonDecode(response.body);
    final userData=SessionManager().getSessionData();

    List<dynamic> supportToCustomers = List.from(data['support_to_customers'] ?? []); 

  List<dynamic> sToIds = supportToCustomers
      .map((item) => item['support_to_custid'])
      .where((id) => id != null)
      .toList();

  final billToCustomerId = data['bill_to_customerid'];

    if (billToCustomerId != null && !sToIds.contains(billToCustomerId)) {
      final btoBlock = {
        'bill_to_name': userData?['accountName'],
        'bill_to_sfid': userData?['bto'],
        'support_to_cust_sfid': userData?['accountCrm'],
        'support_to_custid': userData?['bto'],
        'support_to_customername': userData?['accountName'],
      };
      supportToCustomers.add(btoBlock);
    }
  data['support_to_customers'] = supportToCustomers;
    AccountDataManager().setAccountStoBtoData(data);
    return response;
  }
}
