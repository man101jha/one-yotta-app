import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/ticket/ticket_list.dart';

class StatusBarChart extends StatelessWidget {
  final Map<String, int>? barChartData;
  final List<Map<String, dynamic>>? stackedData;
  final bool isStacked;
  final String? flag;
  static const blockedLabels=['teamS1','severityVsTeam'];

  const StatusBarChart({
    super.key,
    this.barChartData,
    this.stackedData,
    this.isStacked = false,
    this.flag
  });

  @override
  Widget build(BuildContext context) {
if (isStacked && (stackedData == null || stackedData!.isEmpty)) {
    return const Center(child: Text('No Data available'));
  }

  if (!isStacked && (barChartData == null || barChartData!.isEmpty)) {
    return const Center(child: Text('No Data available'));
  }
final List<String> bottomLabels =barChartData?.keys.toList() ?? [];
  final entries = isStacked
      ? stackedData!
      : barChartData!.entries.toList();
final ScrollController _scrollController = ScrollController();
final legendWidth = isStacked ? 90.0 : 0.0;
    return SizedBox(
      height: isStacked ? 260 : 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
       return Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,        // 👈 always show
        trackVisibility: true,        // 👈 shows track
        thickness: 6,
        radius: const Radius.circular(6),
        child: Padding(
        padding: const EdgeInsets.only(bottom: 15), // 
         child:SingleChildScrollView(
          controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (entries.length * 60) + legendWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  BarChart(
                    BarChartData(
                      barGroups: _buildBarGroups(entries),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: _titlesData(entries),
                      maxY:
                          isStacked
                              ? _getStackedMaxY()
                              : max(10.0, (barChartData!.values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble()),
                      barTouchData: BarTouchData(
                         enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                    

                          getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                String label = '';

                                if (isStacked) {
                                  if (groupIndex < stackedData!.length) {
                                    label =
                                        stackedData![groupIndex]['Team'] ?? '';
                                  }
                                } else {
                                  if (groupIndex < bottomLabels.length) {
                                    label = bottomLabels[groupIndex];
                                  }
                                }
                                // ✅ STACKED BAR TOOLTIP
                                if (isStacked && rod.rodStackItems.isNotEmpty) {
                                  final items = rod.rodStackItems;

                                  // Safely calculate each stack value
                                  double s1 =
                                      items.length > 0
                                          ? items[0].toY - items[0].fromY
                                          : 0;
                                  double s2 =
                                      items.length > 1
                                          ? items[1].toY - items[1].fromY
                                          : 0;
                                  double s3 =
                                      items.length > 2
                                          ? items[2].toY - items[2].fromY
                                          : 0;
                                  double s4 =
                                      items.length > 3
                                          ? items[3].toY - items[3].fromY
                                          : 0;

                                  return BarTooltipItem(
                                    '$label\n'
                                    'S1: ${s1.toInt()}\n'
                                    'S2: ${s2.toInt()}\n'
                                    'S3: ${s3.toInt()}\n'
                                    'S4: ${s4.toInt()}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  );
                                }

                                // ✅ NORMAL BAR TOOLTIP (UNCHANGED)
                                return BarTooltipItem(
                                  '$label: ${rod.toY.toInt()}',
                                  const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    backgroundColor: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                );
                              },

                        ),
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent &&
                              response != null &&
                              response.spot != null) {
                            final touchedIndex =
                                response.spot!.touchedBarGroupIndex;
                            if (touchedIndex >= 0 &&
                                touchedIndex < bottomLabels.length) {
                              final selectedLabel = bottomLabels[touchedIndex];
                              if (blockedLabels.contains(flag)) {
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TicketListView(
                                        selectedSeverityFilter: selectedLabel,
                                        selectedStatusFilter: 'all',
                                        flag: flag,
                                      ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),

                  if (isStacked)
                    Positioned(
                      right: 0,
                      top: 40,
                      child: severityLegendVertical(),
                    ),
                ],
              ),
            ),
          )));
        },
      ),
    );
  }

Widget severityLegendVertical() {
  const items = [
    {'label': 'S1', 'color': Colors.blue},
    {'label': 'S2', 'color': Colors.green},
    {'label': 'S3', 'color': Colors.orange},
    {'label': 'S4', 'color': Colors.red},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              color: item['color'] as Color,
            ),
            const SizedBox(width: 6),
            Text(
              item['label'] as String,
              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins',fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList(),
  );
}



  /// Convert map entries to bar groups
  List<BarChartGroupData> _buildBarGroups(dynamic entries) {
  if (!isStacked) {
    return List.generate(entries.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entries[index].value.toDouble(),
            width: 18,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  const severityColors = {
    'S4': Colors.red,
    'S3': Colors.orange,
    'S1': Colors.blue,
    'S2': Colors.green,
  };

  return List.generate(entries.length, (index) {
    final row = entries[index];

    return BarChartGroupData(
      x: index,
      groupVertically: true,
      barRods: [
        for (final key in ['S1', 'S2', 'S3', 'S4'])
          BarChartRodData(
            toY: (row[key] as int).toDouble(),
            width: 18,
            color: severityColors[key],
          ),
      ],
    );
  });
}


FlTitlesData _titlesData(dynamic entries) {
  return FlTitlesData(
    topTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),

    rightTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),

    /// 🔹 LEFT (Y-AXIS)
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,

        /// ✅ FIXED: dynamic interval + no duplicates
        interval: isStacked
            ? _getStackedInterval()
            : getInterval(barChartData!),

        getTitlesWidget: (value, meta) {
          // Prevent floating labels like 2.5, 7.5
          if (value % meta.appliedInterval != 0) {
            return const SizedBox.shrink();
          }

          return Text(
            value.toInt().toString(),
            style: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
          );
        },
      ),
    ),

    // / 🔹 BOTTOM (X-AXIS)
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,

        getTitlesWidget: (value, _) {
          final index = value.toInt();

          /// ✅ STACKED (Severity vs Team)
          if (isStacked) {
            if (index < 0 || index >= stackedData!.length) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _shortCategory(stackedData![index]['Team']),
                style: const TextStyle(fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }

          /// ✅ NORMAL BAR
          if (index < 0 || index >= entries.length) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _shortCategory(entries[index].key),
              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins',fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    ),

  );
}

double _getStackedInterval() {
  final maxY = _getStackedMaxY();

  if (maxY <= 10) return 2;
  if (maxY <= 50) return 10;
  if (maxY <= 100) return 20;
  return 50;
}

  /// Short labels for UI
 String _shortCategory(String label) {
  if (label.length <= 6) return label;
  return label.substring(0, 6); // or use acronyms if you want
}


 double _getStackedMaxY() {
  int max = 0;
  for (final row in stackedData!) {
    final total =
        row['S1'] + row['S2'] + row['S3'] + row['S4'];
    if (total > max) max = total;
  }
  return (max * 1.2).ceilToDouble();
}

double getInterval(Map<String, int> data) {
  final maxValue = data.values.reduce((a, b) => a > b ? a : b);

  if (maxValue <= 5) return 1;
  if (maxValue <= 10) return 2;
  if (maxValue <= 50) return 10;
  if (maxValue <= 100) return 20;
  return 50;
}

}
