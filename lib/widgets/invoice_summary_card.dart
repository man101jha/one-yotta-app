import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myaccount/screens/modules/financials/invoice_list.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:shimmer/shimmer.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final bool isLoading;
  final double totalOutstanding;
  final Map<String, double> invoiceDistribution;

  const InvoiceSummaryCard({
    super.key,
    required this.isLoading,
    required this.totalOutstanding,
    required this.invoiceDistribution,
  });

  static final List<Color> barColors = [
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final List<BarChartGroupData> barGroups = invoiceDistribution.entries
        .toList()
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final value = entry.value.value;
      final color = barColors[index % barColors.length];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final List<String> bottomLabels = invoiceDistribution.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlobalColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Outstanding',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF283e81),
                ),
              ),
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InvoiceListView(),
                          ),
                        );
                      },
                      child: Text(
                        totalOutstanding.toStringAsFixed(2),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: GlobalColors.secondaryColor,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isLoading)
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 100,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        reservedSize: 28,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index >= 0 && index < bottomLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                bottomLabels[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = bottomLabels[groupIndex];
                        return BarTooltipItem(
                          '$label: ${rod.toY.toInt()}',
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent && response != null && response.spot != null) {
                        final touchedIndex = response.spot!.touchedBarGroupIndex;
                        if (touchedIndex >= 0 && touchedIndex < bottomLabels.length) {
                          final selectedLabel = bottomLabels[touchedIndex];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => InvoiceListView(selectedLabel:selectedLabel),
                          ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
