import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/screens/modules/ticket/escalation_matrix.dart';
import 'package:myaccount/screens/modules/ticket/new_ticket.dart';
import 'package:myaccount/screens/modules/ticket/ticket_dashboard.dart';
import 'package:myaccount/screens/modules/ticket/ticket_details.dart';
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/session/ticket_data_manager.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class TicketListView extends StatefulWidget {
  final String selectedSeverityFilter;
  final String selectedStatusFilter;
  final String? flag;

  const TicketListView({
    super.key,
    required this.selectedSeverityFilter,
    required this.selectedStatusFilter,
    this.flag
  });

  @override
  State<TicketListView> createState() => _TicketListViewState();
}

class _TicketListViewState extends State<TicketListView> {
  String selectedTab = 'All';
  List<Map<String, dynamic>> tickets = [];
  bool _isSearching = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, Color> statusColors = {
    'Open': Colors.orange,
    'Closed': Colors.red,
    'Work in Progress': Colors.blue,
    'Assigned': Colors.purple,
    'Accepted': Colors.green,
  };

  Color _getStatusColor(String status) => statusColors[status] ?? Colors.grey;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCachedTickets();
  }

  void _loadCachedTickets() {
    final cachedData = TicketDataManager().getTicketData();
    if (cachedData != null && cachedData['ticketInfo'] != null) {
      _loadTicketsFromCache(cachedData['ticketInfo']);
    }
  }

  void _loadTicketsFromCache(List<dynamic> ticketList) {
    // print(ticketList);
    List<Map<String, dynamic>> loadedTickets = ticketList.map<Map<String, dynamic>>((ticket) {
      final map = Map<String, dynamic>.from(ticket);
      return {
        'ticketNo': map['ticketno'] ?? '',
        'createdOn': map['creationdate'] ?? '',
        'severity': map['severity'] ?? '',
        'status': map['ticketstatus'] ?? '',
        'type': map['tickettype'] ?? '',
        'subject': map['summary'] ?? '',
        'category': map['category'] ?? '',
        'subCategory': map['subcategory'] ?? '',
        'ticketid':map['ticketid'] ?? '',
        'resolved on':map['resolved'] ?? '',
        'ticket assignteam':map['ticketassignteam'] ?? ''
      };
    }).toList();

    // Sort tickets by createdOn descending
    loadedTickets.sort((a, b) {
      DateTime dateA = _parseCustomDate(a['createdOn']) ?? DateTime(1900);
      DateTime dateB = _parseCustomDate(b['createdOn']) ?? DateTime(1900);
      return dateB.compareTo(dateA);
    });
    if (widget.selectedSeverityFilter.isNotEmpty && widget.selectedSeverityFilter!='all') {
      if(widget.selectedSeverityFilter == 'Critical'){
        loadedTickets = loadedTickets.where((ticket) => ticket['severity'].toString() ==
                'S1')
            .toList();
      }
      else if(widget.selectedSeverityFilter == 'High'){
        loadedTickets = loadedTickets.where((ticket) => ticket['severity'].toString() ==
                'S2')
            .toList();
      }else if(widget.selectedSeverityFilter == 'Moderate'){
        loadedTickets = loadedTickets.where((ticket) => ticket['severity'].toString() ==
                'S3')
            .toList();
      }else if(widget.selectedSeverityFilter == 'Low'){
        loadedTickets = loadedTickets.where((ticket) => ticket['severity'].toString() ==
                'S4')
            .toList();
      }else if(widget.flag=='assignedTeam'){
        loadedTickets = loadedTickets.where((ticket) => ticket['ticket assignteam'].toString() ==
                widget.selectedSeverityFilter)
            .toList();
      }else if(widget.flag=='ticket-status'){
        if(widget.selectedSeverityFilter.toLowerCase()=='total'){
          loadedTickets= loadedTickets;
        }else{
        loadedTickets = loadedTickets.where((ticket) => ticket['status'].toString().toLowerCase().contains(widget.selectedSeverityFilter.toLowerCase()))
            .toList();
        }
      }else if(widget.flag=='category'){
        loadedTickets = loadedTickets.where((ticket) => ticket['category'].toString().toLowerCase()==widget.selectedSeverityFilter.toLowerCase())
            .toList();
      }
    }

    if (widget.selectedStatusFilter.isNotEmpty && widget.selectedStatusFilter !='all') {
      loadedTickets = loadedTickets
          .where((ticket) => ticket['status'].toLowerCase() ==
              widget.selectedStatusFilter.toLowerCase())
          .toList();
    }

    setState(() {
      tickets = loadedTickets;
    });
  }

DateTime? _parseCustomDate(String value) {
  try {
    // "04-12-2025 03:28:11 PM"
    final parts = value.split(' ');
    final d = parts[0].split('-');
    final t = parts[1].split(':');

    int hour = int.parse(t[0]);
    if (parts[2] == 'PM' && hour != 12) hour += 12;
    if (parts[2] == 'AM' && hour == 12) hour = 0;

    return DateTime(
      int.parse(d[2]),
      int.parse(d[1]),
      int.parse(d[0]),
      hour,
      int.parse(t[1]),
      int.parse(t[2]),
    );
  } catch (_) {
    return null;
  }
}

  Future<void> _fetchTicketsFromApi() async {
    try {
      final token = await _authService.getAccessToken();
      final sessionData = SessionManager().getSessionData();
      final bto = sessionData?['bto'];
      final sto = sessionData?['sto'];

      if (token == null) throw Exception('Access token not found.');

      final response = await http.post(
        Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/get_dashboard_details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "accountID": sto,
          "auto":"No",
          "type": "Incident,Service Request"
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        TicketDataManager().setTicketData(jsonData);

        if (jsonData['ticketInfo'] != null) {
          _loadTicketsFromCache(jsonData['ticketInfo']);
        }
      }
    } catch (e) {
      print('Error fetching tickets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    List<Map<String, dynamic>> filteredTickets = tickets.where((ticket) {
      final typeMatch = selectedTab == 'All' || ticket['type'] == selectedTab;
      final searchMatch = _searchText.isEmpty || ticket['ticketNo'].toLowerCase().contains(_searchText.toLowerCase());
      return typeMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      appBar: CommonAppBar(
        title: 'Ticket List',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Create Ticket') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTicketView()));
              } else if (value == 'Escalation Matrix') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EscalationMatrixView()));
              } else if (value == 'Ticket Dashboard') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TicketDashboard()));
              }
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Create Ticket',
                child: ListTile(
                  leading: Icon(Icons.add, color: Colors.black),
                  title: Text('Create Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
              const PopupMenuItem(
                value: 'Ticket Dashboard',
                child: ListTile(
                  leading: Icon(Icons.dashboard, color: Colors.black),
                  title: Text('Ticket Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
              const PopupMenuItem(
                value: 'Escalation Matrix',
                child: ListTile(
                  leading: Icon(Icons.help, color: Colors.black),
                  title: Text('Escalation Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              width: screenWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _isSearching
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search ticket number...',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _isSearching = false;
                                        _searchText = '';
                                        _searchController.clear();
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchText = value;
                                  });
                                },
                              )
                            : ToggleButtons(
                                isSelected: ['All', 'Incident', 'Service Request']
                                    .map((tab) => tab == selectedTab)
                                    .toList(),
                                onPressed: (index) {
                                  setState(() {
                                    selectedTab = ['All', 'Incident', 'Service Request'][index];
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                borderColor: GlobalColors.mainColor,
                                selectedBorderColor: GlobalColors.mainColor,
                                fillColor: GlobalColors.mainColor,
                                color: GlobalColors.mainColor,
                                selectedColor: Colors.white,
                                children: ['All', 'Incident', 'Service Request']
                                    .map(
                                      (tab) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                                        child: Text(
                                          tab,
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const SizedBox(width: 8),
                      if (!_isSearching)
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredTickets.isEmpty
                        ? const Center(
                            child: Text(
                              'No tickets found',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = filteredTickets[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TicketDetailsView(ticketData: ticket),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1.0,
                                      color: GlobalColors.borderColor,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ticket['ticketNo'],
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Created On: ${ticket['createdOn']}',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Severity: ${ticket['severity']}',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(ticket['status']),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                ticket['status'],
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }
}
