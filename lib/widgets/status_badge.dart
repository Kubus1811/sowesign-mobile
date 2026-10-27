import 'package:flutter/material.dart';
import '../models/course.dart';

class StatusBadge extends StatelessWidget {
  final Course course;

  const StatusBadge({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final status = course.currentStatus;

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case CourseSigningStatus.alreadySigned:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.check_circle_rounded;
        label = 'Déjà émargé';
        break;
      case CourseSigningStatus.open:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.edit_document;
        label = 'Émargement ouvert';
        break;
      case CourseSigningStatus.upcoming:
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        icon = Icons.schedule_rounded;
        final timeDiff = course.timeUntilOpen;
        if (timeDiff != null && timeDiff.inMinutes < 60) {
          label = 'Ouvre dans ${timeDiff.inMinutes} min';
        } else {
          label = 'À venir';
        }
        break;
      case CourseSigningStatus.closed:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        icon = Icons.lock_clock_rounded;
        label = 'Clos';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
