import 'package:flutter/material.dart';
import 'package:myaccount/screens/modules/ticket/new_ticket.dart';
import 'package:myaccount/screens/modules/ticket/ticket_list.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:shimmer/shimmer.dart';

class TicketSummaryCard extends StatelessWidget {
  final bool isLoading;
  final Map<String, int> severity;
  final int totalTickets;
  final List<Map<String, dynamic>> statusList;

  const TicketSummaryCard({
    super.key,
    required this.isLoading,
    required this.severity,
    required this.totalTickets,
    required this.statusList,
  });

  Widget shimmerBox({double width = 20, double height = 20}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1.0, color: GlobalColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tickets',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF283e81),
                ),
              ),
              isLoading
                  ? shimmerBox(width: 20, height: 18)
                  : InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TicketListView(selectedSeverityFilter: 'all',selectedStatusFilter: 'all',)),
                      );
                    },
                    child: Text(
                      totalTickets.toString(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: GlobalColors.secondaryColor,
                      ),
                    ),
                  ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateTicketView()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlobalColors.secondaryColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_outlined, color: GlobalColors.secondaryColor, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        'New',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: GlobalColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Severity Row Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                isLoading
                    ? shimmerBox()
                    : _PriorityItem(label: 'Critical', count: severity['s1'] ?? 0),
                isLoading
                    ? shimmerBox()
                    : _PriorityItem(label: 'High', count: severity['s2'] ?? 0),
                isLoading
                    ? shimmerBox()
                    : _PriorityItem(label: 'Moderate', count: severity['s3'] ?? 0),
                isLoading
                    ? shimmerBox()
                    : _PriorityItem(label: 'Low', count: severity['s4'] ?? 0),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status List
          ...statusList.map((status) {
            return isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: shimmerBox(width: double.infinity, height: 20),
                  )
                : _StatusItem(
                    label: status['title'],
                    count: status['value'],
                  );
          }).toList(),
        ],
      ),
    );
  }
}

class _PriorityItem extends StatelessWidget {
  final String label;
  final int count;

  const _PriorityItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketListView(selectedSeverityFilter: label,selectedStatusFilter: 'all',)),
        );
      },
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;

  const _StatusItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketListView(selectedSeverityFilter: 'all',selectedStatusFilter: label,)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
