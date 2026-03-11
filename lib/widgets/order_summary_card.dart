import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myaccount/screens/modules/orders/order_distinctlist.dart';
import 'package:myaccount/screens/modules/orders/order_list.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:shimmer/shimmer.dart';

class OrderSummaryCard extends StatelessWidget {
  final bool isLoading;
  final int totalOrders;
  final Map<String, double> orderDistribution;

  const OrderSummaryCard({
    super.key,
    required this.isLoading,
    required this.totalOrders,
    required this.orderDistribution,
  });

  // A list of colors to cycle through for each asset type slice
  static final List<Color> sliceColors = [
    Colors.orangeAccent,
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.tealAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  @override
  Widget build(BuildContext context) {
    // Generate PieChart sections without titles and with distinct colors
    final List<PieChartSectionData> sections = orderDistribution.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value.key;
      final value = entry.value.value;

      final color = sliceColors[index % sliceColors.length];
      return PieChartSectionData(
        color: color,
        value: value,
        radius: 50,
        title: '', // no text inside the pie slice
      );
    }).toList();

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
          // Header row with "Assets" label and asset count with shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF283e81),
                ),
              ),
              isLoading
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
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
                      ),
                      const SizedBox(width: 50),
                      Shimmer.fromColors(
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
                    ],
                  )
                  
                  : 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllOrdersView(flag:true),
                        ),
                      );
                    },
                    child: Text(
                      'All Services',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: GlobalColors.secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30), // Add spacing between buttons
                  
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrdersView(selectedStatusFilter: 'ALL',flag: false)),
                      );
                    },
                    child: Text(
                      '$totalOrders',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: GlobalColors.secondaryColor,
                      ),
                    ),
            ),   
                    ],
                  ) 
            ],
          ),
          const SizedBox(height: 12),
          // Show PieChart and legend only when not loading
          if (!isLoading)
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Pie chart takes left half of width
                  Expanded(
                    flex: 1,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend on right takes right half of width
                  Expanded(
                    flex: 1,
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: orderDistribution.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final key = entry.value.key;
                        final value = entry.value.value;

                        final color = sliceColors[index % sliceColors.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: 
                                InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        OrdersView(selectedStatusFilter: key),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            '$key (${value.toInt()})',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ), 
                                
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
