import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../models/ride_option_model.dart';
import '../models/ride_request_details.dart';

Future<RideRequestDetails?> showRideQualificationDialog({
  required BuildContext context,
  required AppLocation currentLocation,
  required AppLocation destination,
  required RideOption selectedOption,
}) async {
  final passengerController = TextEditingController(text: '1');
  final durationController = TextEditingController(text: '60');

  RideScheduleType scheduleType = RideScheduleType.immediate;
  RideGroupContext groupContext = RideGroupContext.soloBusiness;
  DateTime? scheduledStart;
  String? validationError;

  try {
    return await showDialog<RideRequestDetails>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final passengerCount =
                int.tryParse(passengerController.text.trim()) ?? 1;
            final requestedDurationMinutes =
                int.tryParse(durationController.text.trim()) ?? 60;

            final preview = RideRequestDetails.fromSelections(
              pickupLocation: currentLocation,
              destinationLocation: destination,
              selectedOption: selectedOption,
              scheduleType: scheduleType,
              scheduledStart: scheduledStart,
              groupContext: groupContext,
              passengerCount: passengerCount,
              requestedDurationMinutes: requestedDurationMinutes,
            );

            Future<void> pickScheduledStart() async {
              final date = await showDatePicker(
                context: dialogContext,
                initialDate: DateTime.now().add(const Duration(hours: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (date == null) return;
              if (!dialogContext.mounted) return;

              final time = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.now(),
              );

              if (time == null) return;
              if (!dialogContext.mounted) return;

              setDialogState(() {
                scheduledStart = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                validationError = null;
              });
            }

            void submit() {
              final safePassengerCount =
                  int.tryParse(passengerController.text.trim());
              final safeDuration = int.tryParse(durationController.text.trim());

              if (safePassengerCount == null || safePassengerCount < 1) {
                setDialogState(() {
                  validationError =
                      'Le nombre de passagers doit etre superieur a 0.';
                });
                return;
              }

              if (safeDuration == null || safeDuration < 30) {
                setDialogState(() {
                  validationError =
                      'La duree reservee doit etre d\'au moins 30 minutes.';
                });
                return;
              }

              if (scheduleType == RideScheduleType.scheduled &&
                  scheduledStart == null) {
                setDialogState(() {
                  validationError =
                      'Veuillez choisir une date et une heure de depart.';
                });
                return;
              }

              if (scheduleType == RideScheduleType.scheduled &&
                  scheduledStart != null &&
                  scheduledStart!.isBefore(DateTime.now())) {
                setDialogState(() {
                  validationError =
                      'La course planifiee doit etre dans le futur.';
                });
                return;
              }

              Navigator.of(dialogContext).pop(preview);
            }

            return AlertDialog(
              title: Text(
                'Qualifier la commande',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Depart de la mise a disposition',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Immediat'),
                          selected: scheduleType == RideScheduleType.immediate,
                          onSelected: (_) {
                            setDialogState(() {
                              scheduleType = RideScheduleType.immediate;
                              scheduledStart = null;
                              validationError = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Planifie'),
                          selected: scheduleType == RideScheduleType.scheduled,
                          onSelected: (_) {
                            setDialogState(() {
                              scheduleType = RideScheduleType.scheduled;
                              validationError = null;
                            });
                          },
                        ),
                      ],
                    ),
                    if (scheduleType == RideScheduleType.scheduled) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: pickScheduledStart,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          scheduledStart == null
                              ? 'Choisir date et heure'
                              : _formatDateTime(scheduledStart!),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Contexte de groupe',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RideGroupContext.values.map((contextValue) {
                        return ChoiceChip(
                          label: Text(_groupLabel(contextValue)),
                          selected: groupContext == contextValue,
                          onSelected: (_) {
                            setDialogState(() {
                              groupContext = contextValue;
                              validationError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: passengerController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) =>
                          setDialogState(() => validationError = null),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de passagers',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) =>
                          setDialogState(() => validationError = null),
                      decoration: const InputDecoration(
                        labelText: 'Duree reservee (minutes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synthese operationnelle',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vehicule: ${preview.vehicleType} (${preview.seatCapacity} places)',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tarif horaire: ${preview.hourlyRate.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Montant estime: ${preview.estimatedPrice.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          if (preview.requiresMiniCar) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Mini-car force automatiquement pour 10 passagers ou plus.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF1E90FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        validationError!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    passengerController.dispose();
    durationController.dispose();
  }
}

Future<bool> showRideCreatedDialog({
  required BuildContext context,
  required Ride ride,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Course enregistree'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference: ${ride.id}'),
            const SizedBox(height: 8),
            Text('Statut: ${_statusLabel(ride.status)}'),
            const SizedBox(height: 8),
            Text('Vehicule: ${ride.vehicleType}'),
            const SizedBox(height: 8),
            Text(
              'Montant reserve: ${ride.estimatedPrice.toStringAsFixed(0)} FCFA',
            ),
            const SizedBox(height: 8),
            Text(
              'Tarif horaire: ${ride.hourlyRate.toStringAsFixed(0)} FCFA',
            ),
            if (ride.scheduledStart != null) ...[
              const SizedBox(height: 8),
              Text('Depart prevu: ${_formatDateTime(ride.scheduledStart!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Fermer'),
          ),
          if (!ride.isTerminal)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Annuler la course'),
            ),
        ],
      );
    },
  );

  return result ?? false;
}

String _groupLabel(RideGroupContext context) {
  switch (context) {
    case RideGroupContext.couple:
      return 'Couple';
    case RideGroupContext.family:
      return 'Famille';
    case RideGroupContext.group:
      return 'Groupe';
    case RideGroupContext.soloBusiness:
      return 'Solo/Affaires';
  }
}

String _statusLabel(RideStatus status) {
  switch (status) {
    case RideStatus.requested:
      return 'En attente';
    case RideStatus.accepted:
      return 'Confirmee';
    case RideStatus.scheduled:
      return 'Planifiee';
    case RideStatus.inProgress:
      return 'En cours';
    case RideStatus.overtime:
      return 'Overtime';
    case RideStatus.arrived:
      return 'Chauffeur arrive';
    case RideStatus.completed:
      return 'Terminee';
    case RideStatus.cancelled:
      return 'Annulee';
    case RideStatus.restricted:
      return 'Restreinte';
    case RideStatus.pending:
      return 'En attente';
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} a $hour:$minute';
}
