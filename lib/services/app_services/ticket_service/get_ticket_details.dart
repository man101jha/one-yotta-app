import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/session/ticket_data_manager.dart';
import 'package:myaccount/services/auth_service.dart';

class TicketDetailsService {
  final AuthService _authService = AuthService();

  Future<http.Response> getTicketDetailsData(String ticketNumber) async {
    final token = await _authService.getAccessToken();
    final sessionData = SessionManager().getSessionData();
    final bto = sessionData?['bto'];
    final sto = sessionData?['sto'];

    if (token == null) {
      throw Exception('Access token not found.');
    }

    print('Calling Account data API...');
    print('Token: $token');
    print('Ticket Number: $ticketNumber');

    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/view_ticket'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "ticketID": [ticketNumber],
        "articles": "1",
        "attachments": "1",
        "externalID": "yisausuou",
        "externalSource": "dkjakdjlk",
        "dynamicFields": "1",
        "billToCRMID": bto,
        "supportToCRMID": sto
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      // TicketDataManager().setTicketData(jsonData);
    }

    return response;
  }
}
