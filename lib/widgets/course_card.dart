import 'package:flutter/material.dart';
import '../models/course.dart';
import 'status_badge.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onSignPressed;

  const CourseCard({
    super.key,
    required this.course,
    required this.onSignPressed,
  });

  @override
  Widget build(BuildContext context) {
    final status = course.currentStatus;
    final isOpen = status == CourseSigningStatus.open;
    final isSigned = status == CourseSigningStatus.alreadySigned;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOpen
              ? Colors.green.shade400
              : isSigned
                  ? Colors.blue.shade200
                  : Colors.grey.shade200,
          width: isOpen ? 1.8 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne d'en-tête : Horaires et Badge d'état
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded,
                        size: 16, color: Colors.blueGrey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      course.formattedTimeRange,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ],
                ),
                StatusBadge(course: course),
              ],
            ),
            const SizedBox(height: 12),

            // Titre du cours
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),

            // Détails : Enseignant et Salle
            Row(
              children: [
                if (course.room != null && course.room!.isNotEmpty) ...[
                  Icon(Icons.meeting_room_outlined,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    course.room!,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                ],
                if (course.teacher != null && course.teacher!.isNotEmpty) ...[
                  Icon(Icons.person_outline_rounded,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.teacher!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Bouton d'action "Émarger"
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: isOpen ? onSignPressed : null,
                icon: Icon(
                  isSigned
                      ? Icons.check_circle_outline_rounded
                      : Icons.draw_rounded,
                  size: 18,
                ),
                label: Text(
                  isSigned
                      ? 'Déjà émargé'
                      : isOpen
                          ? 'Émarger maintenant'
                          : 'Émargement indisponible',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen ? Colors.green.shade600 : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade100,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: isOpen ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
