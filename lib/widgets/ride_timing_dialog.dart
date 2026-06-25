import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideTimingSelection {
  const RideTimingSelection.immediate() : scheduledStart = null;
  const RideTimingSelection.scheduled(this.scheduledStart);

  final DateTime? scheduledStart;

  bool get isImmediate => scheduledStart == null;
}

Future<RideTimingSelection?> showRideTimingDialog(BuildContext context) {
  return showDialog<RideTimingSelection>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Quand souhaitez-vous partir ?',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bolt, color: Color(0xFF1E90FF)),
            title: const Text('Commander maintenant'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(
              dialogContext,
              const RideTimingSelection.immediate(),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule, color: Color(0xFF00B894)),
            title: const Text('Planifier pour plus tard'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: dialogContext,
                initialDate: now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (date == null || !dialogContext.mounted) return;

              final time = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.fromDateTime(
                  now.add(const Duration(hours: 1)),
                ),
              );
              if (time == null || !dialogContext.mounted) return;

              Navigator.pop(
                dialogContext,
                RideTimingSelection.scheduled(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
