import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/ticket/ticket_list.dart';

class SeverityPieChart extends StatelessWidget {
  final Map<String, int> formattedData;
  final String? flag;

  const SeverityPieChart({super.key, required this.formattedData, this.flag});

  @override
  Widget build(BuildContext context) {
  final filteredData = formattedData.entries.where((e) => e.value > 0).toList();
  if (filteredData.isEmpty) {
      return const Center(child: Text('No Data Available'));
    }
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: _buildSections(filteredData),
            ),
          ),
        ),
        Padding(padding:  const EdgeInsets.symmetric(horizontal: 12)),
        Expanded(
          flex: 2,
          child: _buildLegend(context,filteredData),
        ),
      ],
    );
  }
  double _safeValue(int value) => value < 5 ? 10 : value.toDouble();

  List<PieChartSectionData> _buildSections(
      List<MapEntry<String, int>> entries) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red];

    return List.generate(entries.length, (index) {
      return PieChartSectionData(
        value: _safeValue(entries[index].value),
        color: colors[index % colors.length],
        title: '',
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend( BuildContext context,
List<MapEntry<String, int>> entries) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red];

    return SingleChildScrollView(
      child:Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(entries.length, (index) {
        final keyParts = entries[index].key.split(':');
        final label = keyParts.length > 1 ? keyParts[1] : keyParts[0];
        final count = entries[index].value;

        return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketListView(selectedSeverityFilter: label,selectedStatusFilter: 'all',flag:flag)),
        );
      },
        
        child:Padding(
          padding: const EdgeInsets.symmetric(vertical: 6,horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$label (${entries[index].value})',
                  style: const TextStyle(fontSize: 14, fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ));
      }),
    )
    );     
  }
}
