import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';

class ComplaintStatusTracker extends StatelessWidget {
  final ComplaintStatus status;

  const ComplaintStatusTracker({super.key, required this.status});

  int _getStatusStepIndex(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.submitted:
        return 0;
      case ComplaintStatus.underReview:
        return 1;
      case ComplaintStatus.investigating:
        return 2;
      case ComplaintStatus.pendingInspection:
        return 3;
      case ComplaintStatus.resolved:
      case ComplaintStatus.rejected:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getStatusStepIndex(status);
    final isRejected = status == ComplaintStatus.rejected;

    final steps = [
      'Submitted',
      'Under Review',
      'Investigating',
      'Pending Inspection',
      isRejected ? 'Rejected' : 'Resolved',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complaint Progress Tracking',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isPassed = index <= activeIndex;
              final isCurrent = index == activeIndex;
              Color circleColor = isPassed
                  ? (isRejected && index == activeIndex ? Colors.red : Colors.teal)
                  : Colors.grey.shade300;

              return Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: isCurrent ? 14 : 10,
                      backgroundColor: circleColor,
                      child: isPassed
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
