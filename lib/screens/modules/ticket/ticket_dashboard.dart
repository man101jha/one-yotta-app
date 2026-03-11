import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/ticket/chart_files/barchart.dart';
import 'package:myaccount/screens/modules/ticket/chart_files/chartcard.dart';
import 'package:myaccount/screens/modules/ticket/chart_files/dashboardCard.dart';
import 'package:myaccount/screens/modules/ticket/chart_files/piechart.dart';
import 'package:myaccount/services/app_services/session/ticket_data_manager.dart';
import 'package:intl/intl.dart';
import 'package:myaccount/widgets/common_app_bar.dart';

class TicketDashboard extends StatefulWidget {
  const TicketDashboard({super.key});

  @override
  State<TicketDashboard> createState() => _TicketDashboardState();
}

class _TicketDashboardState extends State<TicketDashboard> {
final ticketData = TicketDataManager().getTicketData();
Map<String,dynamic> severityData={};
Map<String,dynamic> stateWiseData={};
Map<String, int>formattedData = {};
Map<String, int> statusData = {};
Map<String,int> s1StatusData={};
String totalTicketCount='0';
String closedTicketCount='0';
String openTicketCount='0';
String inProgressTicketCount='0';
Map<String, int> assignedTeamData = {};
bool hasAssignedTeam = false;
List<dynamic> ticketInfo =[];
Map<String, int> categoryCount = {};
List<Map<String, dynamic>> severityTeamData = [];
String selectedMonth = '';
List<Map<String, dynamic>> severityVsTeamData = [];
List<String> latestSixMonths = [];
bool hasTeamS1Chart = false;
String? selectedS1Month;
 Map<String, int> resolvedData={};
@override
  void initState() {
  super.initState();
   severityData = ticketData?['ticketSeverityWiseInfo'] ?? {};
   stateWiseData = ticketData?['ticketStateWiseInfo'] ?? {};
   ticketInfo= ticketData?['ticketInfo']?? [];
    severityWiseTickets(severityData);
    statusWiseTickets(stateWiseData);
    loadAssignedTeam();
    buildCategoryWiseData(ticketInfo);
    // severityTeamData = buildSeverityVsTeam(ticketInfo);
    closedTicketCount = stateWiseData?['Closed']?.toString() ?? '0';
    openTicketCount = stateWiseData?['Open']?.toString() ?? '0';
    inProgressTicketCount = stateWiseData?['Work in Progress']?.toString() ?? '0';
    initMonthData(ticketInfo);
    resolvedData=monthwiseResolvedTickets(ticketInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: CommonAppBar(
        title: 'Ticket Dashboard',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopCards(),
            const SizedBox(height: 16),
            _buildChartsGrid(),
          ]
        )));
  }


  Widget _buildTopCards() {
    final width = MediaQuery.of(context).size.width;

  double aspectRatio;
  if (width < 360) {
    aspectRatio = 1.1; // very small phones
  } else {
    aspectRatio = 2.2; 
  }
  return GridView.count(
    shrinkWrap: true,
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: aspectRatio, 
    physics: const NeverScrollableScrollPhysics(),
    children: [
      DashboardCard(title: "Total", value: totalTicketCount, icon: Icons.confirmation_number),
      DashboardCard(title: "Open", value: openTicketCount, icon: Icons.open_in_new),
      DashboardCard(title: "Closed", value: closedTicketCount, icon: Icons.check_circle),
      DashboardCard(title: "In Progress", value: inProgressTicketCount, icon: Icons.sync),
    ],
  );
}

Widget _buildChartsGrid() {
  return GridView.count(
    shrinkWrap: true,
    crossAxisCount: 1, // change to 2 for tablets
    mainAxisSpacing: 16,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      ChartCard(
        title: "Severity wise Tickets",
        child: SeverityPieChart(formattedData: formattedData),
      ),
      ChartCard(
        title: "Status wise Tickets",
        child: StatusBarChart(barChartData: statusData,flag:'ticket-status'),
      ),
      ChartCard(
        title: "Assigned Team wise Tickets",
        child: SeverityPieChart(formattedData: assignedTeamData,flag:'assignedTeam'),
      ),
       ChartCard(
          title: "Month wise Resolved Tickets",
          child: resolvedTicketsAreaChart(resolvedData),
        ),
        ChartCard(
          title: "Category wise Tickets",
          child: StatusBarChart(barChartData: categoryCount,flag:'category'),
        ),
        ChartCard(
          title: "Severity Vs Team Tickets",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Month selector
              Row(
                children: [
                  const Text(
                    'Select Month:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: latestSixMonths.isNotEmpty ? selectedMonth : null,
                    items:
                        latestSixMonths.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                    onChanged:
                        latestSixMonths.isNotEmpty
                            ? (value) {
                              if (value == null) return;
                              setState(() {
                                selectedMonth = value;
                                updateSeverityData(ticketInfo);
                              });
                            }
                            : null,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// ✅ CHART
              Expanded(
                child: StatusBarChart(
                  isStacked: true,
                  stackedData: severityVsTeamData,
                  flag: 'severityVsTeam',
                ),
              ),
            ],
          ),
        ),
        ChartCard(
          title: "Teams S1-Severity Tickets",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 MONTH DROPDOWN
              Row(
                children: [
                  const Text(
                    'Select Month:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(width: 10),

                  DropdownButton<String>(
                    value: latestSixMonths.isNotEmpty ? selectedS1Month : null,
                    items:
                        latestSixMonths.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedS1Month = value;
                        teamWiseS1TicketsByMonth(ticketInfo, selectedS1Month);
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// 🔹 NORMAL BAR CHART
              Expanded(
                child:
                    hasTeamS1Chart
                        ? StatusBarChart(barChartData: s1StatusData,flag: 'teamS1')
                        : const Center(child: Text('No Data Available',style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey,
                              ),)),
              ),
            ],
          ),
        ),
      ],
    );
  }


void teamWiseS1TicketsByMonth(
    List<dynamic> tickets,
    String? selectedMonth, // "2025-12"
  ) {
    final Map<String, Map<String, int>> teamMonthMap = {};

    for (final ticket in tickets) {
      if (ticket['severity'] != 'S1') continue;

      final team = ticket['ticketassignteam'] ?? 'Unassigned';

      final dateStr = ticket['creationdate'];
      if (dateStr == null) continue;

      final date = _parseCustomDate(dateStr);
      if (date == null) continue;

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      teamMonthMap.putIfAbsent(team, () => {});
      teamMonthMap[team]![monthKey] = (teamMonthMap[team]![monthKey] ?? 0) + 1;
    }

    /// 🔹 same as Angular "teams" filter
    final Map<String, int> chartData = {};

    teamMonthMap.forEach((team, monthMap) {
      if (monthMap[selectedMonth] != null) {
        chartData[team] = monthMap[selectedMonth]!;
      }
    });

    s1StatusData = chartData;
    hasTeamS1Chart = s1StatusData.isNotEmpty;
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


void severityWiseTickets(Map<String,dynamic> severityData) {
  // Process severityData as needed
    final severityLabels = {
    'S1': 'Critical',
    'S2': 'High',
    'S3': 'Moderate',
    'S4': 'Low',
  };


  severityData.forEach((key, value) {
    formattedData['$key:${severityLabels[key]}'] =
        int.tryParse(value.toString()) ?? 0;
  });

  final sortedEntries = formattedData.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

 final Map<String, int> sortedFormattedData = {
  for (var entry in sortedEntries) entry.key: entry.value
};
  totalTicketCount = sortedFormattedData.values
    .fold(0, (sum, value) => sum + value).toString() ;

}

void statusWiseTickets(Map<String,dynamic> stateWiseData) {
  // Process stateWiseData as needed
    int accepted =
    int.tryParse(stateWiseData['Accepted']?.toString() ?? '0') ?? 0;

int assigned =
    int.tryParse(stateWiseData['Assigned']?.toString() ?? '0') ?? 0;

bool hasAssignedTeam = assigned > 0;

int othersCount = accepted + assigned;

stateWiseData.forEach((key, value) {
  statusData[key] = int.tryParse(value.toString()) ?? 0;
});

}

Map<String, int> buildAssignedTeamData(List<dynamic> data) {
  final List<dynamic> ticketInfo = data;
  final Map<String, int> teamCounts = {};
  bool hasAssignedTeam = false;

  for (var ticket in ticketInfo) {
    final String? teamValue =
        ticket['ticketassignteam']?.toString();
    final String team = (teamValue == null || teamValue.isEmpty) 
      ? 'Unassigned' 
      : teamValue;

    teamCounts[team] = (teamCounts[team] ?? 0) + 1;
  }

  // Check if any team has count > 0
  for (final count in teamCounts.values) {
    if (count > 0) {
      hasAssignedTeam = true;
      break;
    }
  }

  // Sort by count DESC
  final sortedEntries = teamCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final sortedTeamCounts = {
    for (var entry in sortedEntries) entry.key: entry.value
  };

  return sortedTeamCounts;
}

void loadAssignedTeam() {
    // API response list
    final data = buildAssignedTeamData(ticketInfo);

    setState(() {
      assignedTeamData = data;
      hasAssignedTeam = data.values.any((v) => v > 0);
    });
  }

  void buildCategoryWiseData(List<dynamic> data) {
  int totalTickets = 0;

  for (final ticket in data) {
    final String? category = ticket['category'];

    if (category == null || category.isEmpty) {
      continue;
    }

    categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    totalTickets++;
  }

  // equivalent to hasCategory flag
  final bool hasCategory = totalTickets > 0;
   hasCategory ? categoryCount : {};
}


List<Map<String, dynamic>> buildSeverityVsTeam(List<dynamic> ticketInfo) {
  const severityLevels = ['S1', 'S2', 'S3', 'S4'];
  final Map<String, Map<String, int>> teamMap = {};

  for (final ticket in ticketInfo) {
    final String? teamValue =
        ticket['ticketassignteam']?.toString();
    final String team = (teamValue == null || teamValue.isEmpty) 
      ? 'Unassigned' 
      : teamValue;
    final String? severity = ticket['severity'];

    if (!severityLevels.contains(severity)) continue;

    teamMap.putIfAbsent(team, () => {
      'S1': 0,
      'S2': 0,
      'S3': 0,
      'S4': 0,
    });

    teamMap[team]![severity!] =
        (teamMap[team]![severity] ?? 0) + 1;
  }

  return teamMap.entries.map((e) {
    return {
      'Team': e.key,
      'S1': e.value['S1'],
      'S2': e.value['S2'],
      'S3': e.value['S3'],
      'S4': e.value['S4'],
    };
  }).toList();
}

void initMonthData(List<dynamic> ticketInfo) {
  final Set<String> monthSet = {};
  final formatter = DateFormat('dd-MM-yyyy hh:mm:ss a');

  for (final ticket in ticketInfo) {
    final String? dateStr = ticket['creationdate'];
    if (dateStr == null || dateStr.isEmpty) continue;

    final DateTime createdDate = formatter.parse(dateStr);

    final key =
        '${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}';

    monthSet.add(key);
  }

  latestSixMonths = monthSet.toList()
    ..sort((a, b) => b.compareTo(a));

  if (latestSixMonths.isNotEmpty) {
    selectedMonth = latestSixMonths.first;
    selectedS1Month=latestSixMonths.first;
    updateSeverityData(ticketInfo);
  }
}

void updateSeverityData(List<dynamic> allTickets) {
  final formatter = DateFormat('dd-MM-yyyy hh:mm:ss a');

  final filteredTickets = allTickets.where((ticket) {
    final String? dateStr = ticket['creationdate'];
    if (dateStr == null || dateStr.isEmpty) return false;

    final DateTime date = formatter.parse(dateStr);

    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}';

    return key == selectedMonth;
  }).toList();

  setState(() {
    severityVsTeamData = buildSeverityVsTeam(filteredTickets);
  });
}

Map<String, int> monthwiseResolvedTickets(
    List<dynamic> ticketInfo,
) {
  final Map<String, int> monthlyResolvedCount = {};
  bool hasResolvedTickets = false;

  for (final ticket in ticketInfo) {
    if (ticket['ticketstatus'] == 'Closed' &&
        ticket['resolvedTime'] != null &&
        ticket['resolvedTime'].toString().isNotEmpty) {

      hasResolvedTickets = true;

      final DateTime? resolvedDate = _parseCustomDate(ticket['resolvedTime']);
      final String? year = resolvedDate?.year.toString();
      final String? month = _monthShortName(resolvedDate?.month);

      final String formattedMonthYear = '$month-$year';

      monthlyResolvedCount[formattedMonthYear] =
          (monthlyResolvedCount[formattedMonthYear] ?? 0) + 1;

    }
  }

  return monthlyResolvedCount;
}

String _monthShortName(int? month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
if (month == null) return '';

return months[month - 1];

}
List<FlSpot> _buildAreaSpots(Map<String, int> data) {
  double index = 0;
    return data.entries.map((e) {
    final spot = FlSpot(index, e.value.toDouble());
    index += 1;
    return spot;
  }).toList();
}


Widget resolvedTicketsAreaChart(Map<String, int> data) {
  if (data.isEmpty) {
    return const Center(child: Text('No Data Available',style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey,
                              ),));
  }

  final spots = _buildAreaSpots(data);
  final labels = data.keys.toList();
  final maxY = data.values.reduce((a, b) => a > b ? a : b).toDouble();
  final yInterval = (maxY / 5).ceilToDouble(); // 5 steps


  return SizedBox(
    height: 300,
    child: LineChart(
      LineChartData(
         minY: 0,
         maxY: maxY + yInterval,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) =>
                  Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, fontFamily: 'Poppins')),
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  labels[index],
                 style: const TextStyle(fontSize: 10, fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
  preventCurveOvershootingThreshold: 0,
            color: Colors.blue,
            barWidth: 2,

            dotData: FlDotData(show: true),

            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    ),
  );
}

}