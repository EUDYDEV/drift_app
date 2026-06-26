import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/pack_journey_controller.dart';
import '../models/cart_model.dart';
import '../models/hotel_model.dart';
import '../models/pack_journey_model.dart';
import '../models/partner_catalog_prestation.dart';
import '../models/room_model.dart';
import '../services/partner_catalog_service.dart';
import '../theme/app_colors.dart';
import 'driving_license_verification_sheet.dart';

class PackConfiguratorPanel extends StatefulWidget {
  const PackConfiguratorPanel({super.key});

  @override
  State<PackConfiguratorPanel> createState() => _PackConfiguratorPanelState();
}

class _PackConfiguratorPanelState extends State<PackConfiguratorPanel> {
  bool _isRunningWizard = false;

  Future<void> _startWizard() async {
    if (_isRunningWizard) return;
    setState(() => _isRunningWizard = true);

    final controller = context.read<PackJourneyController>();
    try {
      final basics = await _showBasicsSheet(controller);
      if (basics == null || !mounted) return;

      final freeTimeItems = await _showBusinessFreeTimeSheet(basics);
      if (freeTimeItems == null || !mounted) return;

      final hotelSelection = await _showHotelAndMealsSheet(
        basics: basics,
        controller: controller,
      );
      if (hotelSelection == null || !mounted) return;

      final transportSelection = await _showTransportSheet(
        basics: basics,
        controller: controller,
      );
      if (transportSelection == null || !mounted) return;

      final draftItems = _sortTimeline(<PackTimelineItem>[
        if (basics.momentType == PackMomentType.business &&
            basics.meetingSchedule.trim().isNotEmpty)
          controller.meetingItem(
            day: 1,
            timeLabel: basics.meetingSchedule.trim(),
            destination: basics.destination,
          ),
        ...freeTimeItems,
        controller.hotelRoomItem(
          hotel: hotelSelection.hotel,
          room: hotelSelection.room,
          durationDays: basics.durationDays,
        ),
        ...hotelSelection.mealItems,
        ...transportSelection.items,
      ]);

      final budget = await _showBudgetSheet(
        basics: basics,
        hotelSelection: hotelSelection,
        transportSelection: transportSelection,
        items: draftItems,
      );
      if (budget == null || !mounted) return;

      final generated = controller.applySequentialPlan(
        destination: basics.destination,
        durationDays: basics.durationDays,
        durationHours: basics.durationHours,
        momentType: basics.momentType,
        maxBudget: budget,
        vehicleLabel: transportSelection.vehicleLabel,
        items: draftItems,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            generated
                ? 'Pack Drift généré avec des disponibilités réelles.'
                : controller.errorMessage ?? 'Impossible de générer ce pack.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunningWizard = false);
      }
    }
  }

  Future<_TripBasicsDraft?> _showBasicsSheet(
    PackJourneyController controller,
  ) async {
    final destinationController = TextEditingController(
      text: controller.destination.isEmpty ? '' : controller.destination,
    );
    final daysController = TextEditingController(
      text: controller.durationDays.toString(),
    );
    final hoursController = TextEditingController(
      text: controller.durationHours.toString(),
    );
    final meetingController = TextEditingController(
      text: '08h00 - 12h00',
    );
    var momentType = controller.momentType;

    final result = await _showSheet<_TripBasicsDraft>(
      title: 'Destination et moment',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputField(
                controller: destinationController,
                label: 'Destination',
                hint: 'Abidjan, Yamoussoukro, Assinie...',
                icon: Icons.place_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      controller: daysController,
                      label: 'Durée en jours',
                      hint: '2',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      controller: hoursController,
                      label: 'Heures en plus',
                      hint: '0',
                      icon: Icons.schedule_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Type de moment', style: _sectionStyle()),
              const SizedBox(height: 8),
              DropdownButtonFormField<PackMomentType>(
                initialValue: momentType,
                decoration: _inputDecoration(Icons.auto_awesome_outlined),
                items: PackMomentType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setSheetState(() => momentType = value);
                },
              ),
              if (momentType == PackMomentType.business) ...[
                const SizedBox(height: 12),
                _inputField(
                  controller: meetingController,
                  label: 'Créneau d obligation',
                  hint: '08h00 - 12h00',
                  icon: Icons.business_center_outlined,
                ),
              ],
              const SizedBox(height: 20),
              _primaryButton(
                label: 'Continuer',
                icon: Icons.arrow_forward,
                onPressed: () {
                  final destination = destinationController.text.trim();
                  final days = int.tryParse(daysController.text.trim()) ?? 0;
                  final hours = int.tryParse(hoursController.text.trim()) ?? 0;
                  if (destination.isEmpty || days <= 0) {
                    _showInlineError(
                      sheetContext,
                      'Destination et durée sont obligatoires.',
                    );
                    return;
                  }
                  Navigator.pop(
                    sheetContext,
                    _TripBasicsDraft(
                      destination: destination,
                      durationDays: days.clamp(1, 30),
                      durationHours: hours.clamp(0, 23),
                      momentType: momentType,
                      meetingSchedule: meetingController.text.trim(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    destinationController.dispose();
    daysController.dispose();
    hoursController.dispose();
    meetingController.dispose();
    return result;
  }

  Future<List<PackTimelineItem>?> _showBusinessFreeTimeSheet(
    _TripBasicsDraft basics,
  ) async {
    if (basics.momentType != PackMomentType.business) {
      return const <PackTimelineItem>[];
    }

    final endLabel = _meetingEndLabel(basics.meetingSchedule);
    final decision = await _showSheet<_FreeTimeDecision>(
      title: 'Temps libre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre réunion se termine à $endLabel mais votre séjour dure plus longtemps. Que souhaitez-vous faire le reste de votre temps libre ?',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.45,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          _choiceTile(
            icon: Icons.check_circle_outline,
            title: 'Je sais déjà quoi faire',
            subtitle: 'Passer directement à l hébergement',
            onTap: () => Navigator.pop(
              context,
              _FreeTimeDecision.skip,
            ),
          ),
          const SizedBox(height: 10),
          _choiceTile(
            icon: Icons.auto_awesome,
            title: 'Je ne sais pas, proposez-moi',
            subtitle: 'Afficher les suggestions réelles du catalogue',
            onTap: () => Navigator.pop(
              context,
              _FreeTimeDecision.propose,
            ),
          ),
        ],
      ),
    );

    if (decision == null) return null;
    if (decision == _FreeTimeDecision.skip) {
      return const <PackTimelineItem>[];
    }
    if (!mounted) return null;

    final service = context.read<PartnerCatalogService>();
    final controller = context.read<PackJourneyController>();
    final suggestions = <PartnerCatalogPrestation>[
      ...await service.fetchActivityCatalog(city: basics.destination),
      ...await service.fetchMealCatalog(city: basics.destination),
    ];

    if (!mounted) return null;
    final selected = <String>{};
    return _showSheet<List<PackTimelineItem>>(
      title: 'Suggestions réelles',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final available =
              suggestions.where((item) => item.isAvailable).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (available.isEmpty)
                _emptyAvailability()
              else
                ...available.map(
                  (prestation) => _feedCard(
                    title: prestation.name,
                    subtitle: prestation.partnerName,
                    price: prestation.price.round(),
                    mediaUrls: prestation.mediaUrls,
                    selected: selected.contains(prestation.id),
                    onTap: () {
                      setSheetState(() {
                        if (!selected.add(prestation.id)) {
                          selected.remove(prestation.id);
                        }
                      });
                    },
                  ),
                ),
              const SizedBox(height: 18),
              _primaryButton(
                label: 'Valider et continuer',
                icon: Icons.arrow_forward,
                onPressed: () {
                  final chosen = available
                      .where((item) => selected.contains(item.id))
                      .toList(growable: false);
                  final items = <PackTimelineItem>[];
                  for (var index = 0; index < chosen.length; index++) {
                    final prestation = chosen[index];
                    final isMeal = prestation.typeService == 'table_resto' ||
                        prestation.typeService == 'plat_livraison';
                    items.add(
                      controller.prestationItem(
                        prestation: prestation,
                        category: isMeal
                            ? PackTimelineCategory.meal
                            : PackTimelineCategory.activity,
                        day: 1,
                        timeLabel:
                            index == 0 ? 'Après $endLabel' : 'Temps libre',
                        subtitle:
                            'Suggestion du catalogue pour ${basics.destination}',
                        track: 'Affaires',
                      ),
                    );
                  }
                  Navigator.pop(sheetContext, items);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_HotelMealSelection?> _showHotelAndMealsSheet({
    required _TripBasicsDraft basics,
    required PackJourneyController controller,
  }) async {
    final service = context.read<PartnerCatalogService>();
    final hotelsFuture = service.fetchHotelCatalog(city: basics.destination);

    Hotel? selectedHotel;
    Room? selectedRoom;
    Future<List<Room>>? roomsFuture;
    Future<List<PartnerCatalogPrestation>>? hotelMealFuture;
    Future<List<PartnerCatalogPrestation>>? externalMealFuture;
    var stage = _HotelStage.hotels;
    var groupMealPlanning = false;
    final mealSelection = <String, PartnerCatalogPrestation>{};

    return _showSheet<_HotelMealSelection>(
      title: 'Hébergement et repas',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Widget content;
          switch (stage) {
            case _HotelStage.hotels:
              content = FutureBuilder<List<Hotel>>(
                future: hotelsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _loadingBlock();
                  }
                  final hotels = snapshot.data ?? const <Hotel>[];
                  if (hotels.isEmpty) return _emptyAvailability();
                  return Column(
                    children: hotels
                        .map(
                          (hotel) => _hotelFeedCard(
                            hotel: hotel,
                            onTap: () {
                              selectedHotel = hotel;
                              roomsFuture = service.fetchHotelRooms(
                                partnerId: hotel.partnerId ?? hotel.id,
                              );
                              hotelMealFuture = _fetchPartnerMeals(
                                service,
                                partnerId: hotel.partnerId ?? hotel.id,
                              );
                              externalMealFuture = service.fetchMealCatalog(
                                city: basics.destination,
                              );
                              setSheetState(() => stage = _HotelStage.rooms);
                            },
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              );
            case _HotelStage.rooms:
              content = FutureBuilder<List<Room>>(
                future: roomsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _loadingBlock();
                  }
                  final rooms = snapshot.data ?? const <Room>[];
                  if (rooms.isEmpty) {
                    return Column(
                      children: [
                        _emptyAvailability(),
                        const SizedBox(height: 12),
                        _secondaryButton(
                          label: 'Revenir aux hôtels',
                          onPressed: () =>
                              setSheetState(() => stage = _HotelStage.hotels),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backButton(
                        'Changer d hôtel',
                        () => setSheetState(() => stage = _HotelStage.hotels),
                      ),
                      const SizedBox(height: 8),
                      ...rooms.map(
                        (room) => _roomFeedCard(
                          room: room,
                          selected: selectedRoom?.id == room.id,
                          onTap: () => setSheetState(() => selectedRoom = room),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _primaryButton(
                        label: 'Ajouter la chambre à mon Pack',
                        icon: Icons.hotel_outlined,
                        onPressed: selectedRoom == null
                            ? null
                            : () => setSheetState(
                                  () => stage = _HotelStage.meals,
                                ),
                      ),
                    ],
                  );
                },
              );
            case _HotelStage.meals:
              content = FutureBuilder<List<List<PartnerCatalogPrestation>>>(
                future: Future.wait<List<PartnerCatalogPrestation>>([
                  hotelMealFuture ??
                      Future.value(const <PartnerCatalogPrestation>[]),
                  externalMealFuture ??
                      service.fetchMealCatalog(city: basics.destination),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _loadingBlock();
                  }
                  final hotelMeals =
                      snapshot.data?[0] ?? const <PartnerCatalogPrestation>[];
                  final externalMeals =
                      snapshot.data?[1] ?? const <PartnerCatalogPrestation>[];
                  final slots = _mealSlots(basics.durationDays);
                  final isGroup = basics.momentType == PackMomentType.group;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backButton(
                        'Changer de chambre',
                        () => setSheetState(() => stage = _HotelStage.rooms),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Souhaitez-vous prendre vos repas au sein de votre hôtel ou réserver dans d autres restaurants partenaires ?',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      if (isGroup) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.orange,
                          title: Text(
                            'Planifier les repas du groupe',
                            style: _optionStyle(),
                          ),
                          subtitle: const Text(
                            'Le mode Groupe reste flexible.',
                          ),
                          value: groupMealPlanning,
                          onChanged: (value) =>
                              setSheetState(() => groupMealPlanning = value),
                        ),
                        if (!groupMealPlanning)
                          _primaryButton(
                            label: 'Continuer sans repas imposés',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                                _HotelMealSelection(
                                  hotel: selectedHotel!,
                                  room: selectedRoom!,
                                  mealItems: const <PackTimelineItem>[],
                                ),
                              );
                            },
                          ),
                      ],
                      if (!isGroup || groupMealPlanning) ...[
                        const SizedBox(height: 12),
                        if (hotelMeals.isNotEmpty)
                          _choiceTile(
                            icon: Icons.room_service_outlined,
                            title: 'Repas à l hôtel',
                            subtitle:
                                'Petit-déjeuner, déjeuner et dîner à 0 FCFA',
                            onTap: () {
                              final meals = slots
                                  .map(
                                    (slot) => controller.includedHotelMealItem(
                                      day: slot.day,
                                      timeLabel: slot.time,
                                      mealLabel: slot.label,
                                      hotel: selectedHotel!,
                                    ),
                                  )
                                  .toList(growable: false);
                              Navigator.pop(
                                sheetContext,
                                _HotelMealSelection(
                                  hotel: selectedHotel!,
                                  room: selectedRoom!,
                                  mealItems: meals,
                                ),
                              );
                            },
                          )
                        else
                          _infoCard(
                            'Cet hôtel n a pas encore déclaré de restaurant dans PostgreSQL.',
                          ),
                        const SizedBox(height: 10),
                        if (externalMeals.isEmpty)
                          _emptyAvailability()
                        else
                          ...slots.map(
                            (slot) => _mealSlotDropdown(
                              slot: slot,
                              meals: externalMeals,
                              selected: mealSelection[slot.key],
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(() {
                                  mealSelection[slot.key] = value;
                                });
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        _primaryButton(
                          label: 'Valider les restaurants',
                          icon: Icons.restaurant_outlined,
                          onPressed: externalMeals.isEmpty
                              ? null
                              : () {
                                  final missing = slots.any(
                                    (slot) => mealSelection[slot.key] == null,
                                  );
                                  if (missing) {
                                    _showInlineError(
                                      sheetContext,
                                      'Chaque créneau repas doit être renseigné.',
                                    );
                                    return;
                                  }
                                  final mealItems = slots
                                      .map(
                                        (slot) => controller.prestationItem(
                                          prestation: mealSelection[slot.key]!,
                                          category: PackTimelineCategory.meal,
                                          day: slot.day,
                                          timeLabel: slot.time,
                                          subtitle:
                                              '${slot.label} réservé chez ${mealSelection[slot.key]!.partnerName}',
                                          metadata: <String, dynamic>{
                                            'mealSlot': slot.label,
                                          },
                                        ),
                                      )
                                      .toList(growable: false);
                                  Navigator.pop(
                                    sheetContext,
                                    _HotelMealSelection(
                                      hotel: selectedHotel!,
                                      room: selectedRoom!,
                                      mealItems: mealItems,
                                    ),
                                  );
                                },
                        ),
                      ],
                    ],
                  );
                },
              );
          }
          return content;
        },
      ),
    );
  }

  Future<_TransportSelection?> _showTransportSheet({
    required _TripBasicsDraft basics,
    required PackJourneyController controller,
  }) async {
    final service = context.read<PartnerCatalogService>();
    var stage = _TransportStage.people;
    var adults = 2;
    var children = 0;
    var participants = 10;
    var accompanied = false;
    var agents = 1;
    var peopleCount = 1;
    Future<List<PartnerCatalogPrestation>>? fleetFuture;
    _VehicleProposal? selectedProposal;
    var logistics = _TransportLogistics.fullDisposal;
    var withoutDriver = false;
    var driverCoverage = _DriverCoverage.continuous;

    return _showSheet<_TransportSelection>(
      title: 'Effectif et transport',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          if (stage == _TransportStage.people) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Composition de l effectif', style: _sectionStyle()),
                const SizedBox(height: 10),
                if (basics.momentType == PackMomentType.family) ...[
                  _stepperTile(
                    label: 'Adultes',
                    value: adults,
                    min: 1,
                    onChanged: (value) => setSheetState(() => adults = value),
                  ),
                  _stepperTile(
                    label: 'Enfants',
                    value: children,
                    min: 0,
                    onChanged: (value) => setSheetState(() => children = value),
                  ),
                ] else if (basics.momentType == PackMomentType.group) ...[
                  _stepperTile(
                    label: 'Participants',
                    value: participants,
                    min: 1,
                    max: 200,
                    onChanged: (value) =>
                        setSheetState(() => participants = value),
                  ),
                ] else if (basics.momentType == PackMomentType.business) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.orange,
                    title: Text('Je voyage accompagné', style: _optionStyle()),
                    value: accompanied,
                    onChanged: (value) =>
                        setSheetState(() => accompanied = value),
                  ),
                  if (accompanied)
                    _stepperTile(
                      label: 'Agents accompagnants',
                      value: agents,
                      min: 1,
                      max: 20,
                      onChanged: (value) => setSheetState(() => agents = value),
                    ),
                ] else
                  _stepperTile(
                    label: 'Personnes',
                    value: adults,
                    min: 1,
                    max: 10,
                    onChanged: (value) => setSheetState(() => adults = value),
                  ),
                const SizedBox(height: 18),
                _primaryButton(
                  label: 'Afficher la flotte réelle',
                  icon: Icons.directions_car_outlined,
                  onPressed: () {
                    peopleCount = switch (basics.momentType) {
                      PackMomentType.family => adults + children,
                      PackMomentType.group => participants,
                      PackMomentType.business => 1 + (accompanied ? agents : 0),
                      PackMomentType.couple => 2,
                    };
                    fleetFuture = service.fetchFleetCatalog(
                      city: basics.destination,
                    );
                    setSheetState(() => stage = _TransportStage.vehicles);
                  },
                ),
              ],
            );
          }

          if (stage == _TransportStage.vehicles) {
            return FutureBuilder<List<PartnerCatalogPrestation>>(
              future: fleetFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _loadingBlock();
                }
                final proposals = _buildVehicleProposals(
                  snapshot.data ?? const <PartnerCatalogPrestation>[],
                  peopleCount: peopleCount,
                  allowCombinations: basics.momentType == PackMomentType.group,
                );
                if (proposals.isEmpty) {
                  return Column(
                    children: [
                      _emptyAvailability(),
                      const SizedBox(height: 12),
                      _secondaryButton(
                        label: 'Revenir à l effectif',
                        onPressed: () =>
                            setSheetState(() => stage = _TransportStage.people),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _backButton(
                      'Modifier l effectif',
                      () => setSheetState(() => stage = _TransportStage.people),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capacité requise : $peopleCount personne${peopleCount > 1 ? 's' : ''}',
                      style: _optionStyle(),
                    ),
                    const SizedBox(height: 12),
                    ...proposals.map(
                      (proposal) => _vehicleFeedCard(
                        proposal: proposal,
                        selected: selectedProposal == proposal,
                        onTap: () => setSheetState(
                          () => selectedProposal = proposal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _primaryButton(
                      label: 'Configurer la logistique',
                      icon: Icons.route_outlined,
                      onPressed: selectedProposal == null
                          ? null
                          : () => setSheetState(
                                () => stage = _TransportStage.logistics,
                              ),
                    ),
                  ],
                );
              },
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(
                'Changer de véhicule',
                () => setSheetState(() => stage = _TransportStage.vehicles),
              ),
              const SizedBox(height: 10),
              Text('Formule logistique', style: _sectionStyle()),
              const SizedBox(height: 8),
              RadioGroup<_TransportLogistics>(
                groupValue: logistics,
                onChanged: (value) {
                  if (value == null) return;
                  setSheetState(() {
                    logistics = value;
                    if (logistics != _TransportLogistics.fullDisposal) {
                      withoutDriver = false;
                    }
                  });
                },
                child: Column(
                  children: _TransportLogistics.values
                      .map(
                        (option) => RadioListTile<_TransportLogistics>(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.orange,
                          value: option,
                          title: Text(option.label, style: _optionStyle()),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const Divider(height: 20),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.orange,
                title: Text('Sans Chauffeur', style: _optionStyle()),
                subtitle: Text(
                  logistics == _TransportLogistics.fullDisposal
                      ? 'Autorisé uniquement avec mise à disposition complète'
                      : 'Indisponible pour cette formule logistique',
                ),
                value: withoutDriver,
                onChanged: logistics != _TransportLogistics.fullDisposal
                    ? null
                    : (value) async {
                        final wantsSelfDrive = value ?? false;
                        if (wantsSelfDrive) {
                          final verified =
                              await ensureSelfDriveVerification(context);
                          if (!verified || !mounted) return;
                        }
                        setSheetState(() => withoutDriver = wantsSelfDrive);
                      },
              ),
              if (!withoutDriver) ...[
                const SizedBox(height: 10),
                Text('Parcours avec chauffeur', style: _sectionStyle()),
                RadioGroup<_DriverCoverage>(
                  groupValue: driverCoverage,
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => driverCoverage = value);
                    }
                  },
                  child: Column(
                    children: _DriverCoverage.values
                        .map(
                          (coverage) => RadioListTile<_DriverCoverage>(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.orange,
                            value: coverage,
                            title: Text(coverage.label, style: _optionStyle()),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _primaryButton(
                label: 'Ajouter le transport au Pack',
                icon: Icons.add_circle_outline,
                onPressed: () {
                  final proposal = selectedProposal!;
                  final multiplier = logistics.priceMultiplier(
                    totalHours: basics.totalHours,
                  );
                  final items = proposal.entries.map((entry) {
                    return controller.prestationItem(
                      prestation: entry.prestation,
                      category: PackTimelineCategory.transport,
                      day: 1,
                      timeLabel: 'Départ',
                      subtitle:
                          '${logistics.label} - ${withoutDriver ? 'sans chauffeur' : driverCoverage.label}',
                      quantity: entry.quantity,
                      priceOverride: entry.prestation.price.round() *
                          entry.quantity *
                          multiplier,
                      metadata: <String, dynamic>{
                        'peopleCount': peopleCount,
                        'capacity': entry.capacity,
                        'vehicleQuantity': entry.quantity,
                        'logistics': logistics.name,
                        'driverCoverage': withoutDriver
                            ? 'without_driver'
                            : driverCoverage.name,
                        'withoutDriver': withoutDriver,
                        'rideType':
                            withoutDriver ? 'withoutDriver' : 'withDriver',
                        'pricingMultiplier': entry.quantity * multiplier,
                      },
                    );
                  }).toList(growable: false);
                  Navigator.pop(
                    sheetContext,
                    _TransportSelection(
                      vehicleLabel: proposal.label,
                      peopleCount: peopleCount,
                      items: items,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<int?> _showBudgetSheet({
    required _TripBasicsDraft basics,
    required _HotelMealSelection hotelSelection,
    required _TransportSelection transportSelection,
    required List<PackTimelineItem> items,
  }) async {
    final total = items.fold<int>(0, (sum, item) => sum + item.price);
    final budgetController = TextEditingController(text: total.toString());
    final result = await _showSheet<int>(
      title: 'Résumé et budget',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryLine('Destination', basics.destination),
          _summaryLine(
            'Durée',
            '${basics.durationDays} jour${basics.durationDays > 1 ? 's' : ''}'
                '${basics.durationHours > 0 ? ' + ${basics.durationHours}h' : ''}',
          ),
          _summaryLine('Hôtel', hotelSelection.hotel.name),
          _summaryLine('Chambre', hotelSelection.room.name),
          _summaryLine('Transport', transportSelection.vehicleLabel),
          _summaryLine(
              'Effectif', '${transportSelection.peopleCount} personne(s)'),
          const SizedBox(height: 12),
          ...items.map(
            (item) => _compactTimelineRow(item),
          ),
          const Divider(height: 24),
          _summaryLine('Total calculé', CartModel.formatCurrency(total)),
          const SizedBox(height: 12),
          _inputField(
            controller: budgetController,
            label: 'Budget Max Global en FCFA',
            hint: '$total',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          _primaryButton(
            label: 'Valider le Pack',
            icon: Icons.check_circle_outline,
            onPressed: () {
              final budget =
                  int.tryParse(budgetController.text.replaceAll(' ', '')) ?? 0;
              if (budget < total) {
                _showInlineError(
                  context,
                  'Le budget max doit couvrir le total calculé.',
                );
                return;
              }
              Navigator.pop(context, budget);
            },
          ),
        ],
      ),
    );
    budgetController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PackJourneyController>();
    final plan = controller.plan;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONFIGURATEUR DRIFT',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        plan == null
                            ? 'Parcours immersif étape par étape'
                            : '${plan.destination} - ${CartModel.formatCurrency(plan.total)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isRunningWizard ? null : _startWizard,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                  ),
                  child: Text(plan == null ? 'Créer' : 'Reconfigurer'),
                ),
              ],
            ),
          ),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child:
                  _infoCard(controller.errorMessage!, color: Colors.redAccent),
            ),
          if (plan == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _primaryButton(
                label: 'Démarrer le parcours Pack',
                icon: Icons.layers_outlined,
                onPressed: _isRunningWizard ? null : _startWizard,
              ),
            )
          else
            _buildPlan(controller),
        ],
      ),
    );
  }

  Widget _buildPlan(PackJourneyController controller) {
    final plan = controller.plan!;
    final days = <int, List<PackTimelineItem>>{};
    for (final item in plan.items) {
      days.putIfAbsent(item.day, () => <PackTimelineItem>[]).add(item);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIMELINE DEFINITIVE',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.vehicleLabel} - ${CartModel.formatCurrency(plan.remaining)} restant',
            style: GoogleFonts.montserrat(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          ...days.entries.map(
            (entry) => _dayTimeline(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _dayTimeline(int day, List<PackTimelineItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JOUR $day',
            style: GoogleFonts.montserrat(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(_timelineItem),
        ],
      ),
    );
  }

  Widget _timelineItem(PackTimelineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              item.timeLabel,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  CartModel.formatCurrency(item.price),
                  style: GoogleFonts.montserrat(
                    color: item.price == 0 ? Colors.white54 : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<T?> _showSheet<T>({
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.of(sheetContext).size.height * 0.88;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hotelFeedCard({
    required Hotel hotel,
    required VoidCallback onTap,
  }) {
    return _feedCard(
      title: hotel.name,
      subtitle: '${hotel.city} - ${hotel.address}',
      price: hotel.priceValue,
      mediaUrls: hotel.imageUrls,
      badge: hotel.isFeatured ? 'Boosté' : null,
      onTap: onTap,
    );
  }

  Widget _roomFeedCard({
    required Room room,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final hasVideo = room.video360Urls.isNotEmpty;
    return _feedCard(
      title: room.name,
      subtitle:
          'Capacité ${room.capacity} - ${hasVideo ? 'Vidéo 360 disponible' : 'Fiche technique partenaire'}',
      price: room.priceValue,
      mediaUrls: room.imageUrls,
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _vehicleFeedCard({
    required _VehicleProposal proposal,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _feedCard(
      title: proposal.label,
      subtitle:
          'Capacité ${proposal.capacity} - ${proposal.entries.length} ligne(s) flotte',
      price: proposal.basePrice,
      mediaUrls: proposal.mediaUrls,
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _feedCard({
    required String title,
    required String subtitle,
    required int price,
    required List<String> mediaUrls,
    required VoidCallback onTap,
    bool selected = false,
    String? badge,
  }) {
    final imageUrl = mediaUrls
        .where((url) => !_looksLikeVideo(url))
        .cast<String?>()
        .firstWhere((url) => url != null && url.isNotEmpty, orElse: () => null);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.orange : const Color(0xFFECECF1),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: SizedBox(
                height: 154,
                width: double.infinity,
                child: imageUrl == null
                    ? Container(
                        color: const Color(0xFFF1F1F4),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.grayText,
                          size: 38,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F1F4),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.grayText,
                            size: 38,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.grayText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CartModel.formatCurrency(price),
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealSlotDropdown({
    required _MealSlot slot,
    required List<PartnerCatalogPrestation> meals,
    required PartnerCatalogPrestation? selected,
    required ValueChanged<PartnerCatalogPrestation?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<PartnerCatalogPrestation>(
        initialValue: selected,
        decoration: _inputDecoration(Icons.restaurant_outlined).copyWith(
          labelText: 'Jour ${slot.day} - ${slot.time} - ${slot.label}',
        ),
        items: meals
            .map(
              (meal) => DropdownMenuItem(
                value: meal,
                child: Text(
                  '${meal.name} - ${CartModel.formatCurrency(meal.price.round())}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }

  Widget _choiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E7EC)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _optionStyle()),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grayText),
          ],
        ),
      ),
    );
  }

  Widget _stepperTile({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 60,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _optionStyle())),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text(
            '$value',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          side: const BorderSide(color: Color(0xFFE0E0E5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _backButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: AppColors.orange),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(fontSize: 12),
      decoration: _inputDecoration(icon).copyWith(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange),
      ),
    );
  }

  Widget _loadingBlock() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
    );
  }

  Widget _emptyAvailability() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Text(
        'Aucune disponibilité réelle pour ces critères',
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.grayText,
        ),
      ),
    );
  }

  Widget _infoCard(String text, {Color color = AppColors.orange}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.grayText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactTimelineRow(PackTimelineItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              'J${item.day} ${item.timeLabel}',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                color: AppColors.grayText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.title,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            CartModel.formatCurrency(item.price),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionStyle() => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.darkText,
      );

  TextStyle _optionStyle() => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      );

  void _showInlineError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<List<PartnerCatalogPrestation>> _fetchPartnerMeals(
    PartnerCatalogService service, {
    required String partnerId,
  }) async {
    final tableMeals = await service.fetchPrestations(
      typeService: 'table_resto',
      partnerId: partnerId,
    );
    final deliveryMeals = await service.fetchPrestations(
      typeService: 'plat_livraison',
      partnerId: partnerId,
    );
    return <PartnerCatalogPrestation>[
      ...tableMeals.where((item) => item.isAvailable),
      ...deliveryMeals.where((item) => item.isAvailable),
    ];
  }

  List<_MealSlot> _mealSlots(int durationDays) {
    final slots = <_MealSlot>[];
    for (var day = 1; day <= durationDays.clamp(1, 30); day++) {
      slots.addAll(<_MealSlot>[
        _MealSlot(day: day, time: '09h00', label: 'Petit-déjeuner'),
        _MealSlot(day: day, time: '12h00', label: 'Déjeuner'),
        _MealSlot(day: day, time: '19h00', label: 'Dîner'),
      ]);
    }
    return slots;
  }

  List<_VehicleProposal> _buildVehicleProposals(
    List<PartnerCatalogPrestation> vehicles, {
    required int peopleCount,
    required bool allowCombinations,
  }) {
    final available = vehicles
        .where((vehicle) => vehicle.isAvailable && (vehicle.capacity ?? 0) > 0)
        .toList(growable: true)
      ..sort((a, b) {
        final capacityComparison = (a.capacity ?? 0).compareTo(b.capacity ?? 0);
        if (capacityComparison != 0) return capacityComparison;
        return a.price.compareTo(b.price);
      });

    final proposals = <_VehicleProposal>[];
    for (final vehicle in available) {
      final capacity = vehicle.capacity ?? 0;
      if (capacity >= peopleCount) {
        proposals.add(
          _VehicleProposal(
            entries: <_VehicleProposalEntry>[
              _VehicleProposalEntry(prestation: vehicle, quantity: 1),
            ],
          ),
        );
      }
    }

    if (allowCombinations && available.isNotEmpty) {
      final largest = available.reduce(
        (a, b) => (a.capacity ?? 0) >= (b.capacity ?? 0) ? a : b,
      );
      final largestCapacity = largest.capacity ?? 0;
      if (largestCapacity > 0 && largestCapacity < peopleCount) {
        final quantity = (peopleCount / largestCapacity).ceil();
        proposals.add(
          _VehicleProposal(
            entries: <_VehicleProposalEntry>[
              _VehicleProposalEntry(
                prestation: largest,
                quantity: quantity,
              ),
            ],
          ),
        );
      }

      final sortedDesc = available.reversed.toList(growable: false);
      var remaining = peopleCount;
      final combo = <_VehicleProposalEntry>[];
      for (final vehicle in sortedDesc) {
        if (remaining <= 0) break;
        final capacity = vehicle.capacity ?? 0;
        if (capacity <= 0) continue;
        combo.add(_VehicleProposalEntry(prestation: vehicle, quantity: 1));
        remaining -= capacity;
      }
      if (remaining <= 0 && combo.length > 1) {
        proposals.add(_VehicleProposal(entries: combo));
      }
    }

    final seen = <String>{};
    final unique = <_VehicleProposal>[];
    for (final proposal in proposals) {
      final signature = proposal.entries
          .map((entry) => '${entry.prestation.id}:${entry.quantity}')
          .join('|');
      if (seen.add(signature)) {
        unique.add(proposal);
      }
    }
    unique.sort((a, b) {
      final priceComparison = a.basePrice.compareTo(b.basePrice);
      if (priceComparison != 0) return priceComparison;
      return a.capacity.compareTo(b.capacity);
    });
    return unique.take(8).toList(growable: false);
  }

  List<PackTimelineItem> _sortTimeline(List<PackTimelineItem> items) {
    final sorted = List<PackTimelineItem>.from(items);
    sorted.sort((a, b) {
      final dayComparison = a.day.compareTo(b.day);
      if (dayComparison != 0) return dayComparison;
      return _timeScore(a.timeLabel).compareTo(_timeScore(b.timeLabel));
    });
    return sorted;
  }

  int _timeScore(String label) {
    final match = RegExp(r'(\d{1,2})h?(\d{2})?').firstMatch(label);
    if (match == null) return 9999;
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    return hour * 60 + minute;
  }

  String _meetingEndLabel(String value) {
    final parts = value.split('-');
    if (parts.length >= 2) {
      return parts.last.trim();
    }
    return 'la fin de votre réunion';
  }

  bool _looksLikeVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('vimeo.com');
  }
}

class _TripBasicsDraft {
  const _TripBasicsDraft({
    required this.destination,
    required this.durationDays,
    required this.durationHours,
    required this.momentType,
    required this.meetingSchedule,
  });

  final String destination;
  final int durationDays;
  final int durationHours;
  final PackMomentType momentType;
  final String meetingSchedule;

  int get totalHours => math.max(1, durationDays * 24 + durationHours);
}

class _HotelMealSelection {
  const _HotelMealSelection({
    required this.hotel,
    required this.room,
    required this.mealItems,
  });

  final Hotel hotel;
  final Room room;
  final List<PackTimelineItem> mealItems;
}

class _TransportSelection {
  const _TransportSelection({
    required this.vehicleLabel,
    required this.peopleCount,
    required this.items,
  });

  final String vehicleLabel;
  final int peopleCount;
  final List<PackTimelineItem> items;
}

class _MealSlot {
  const _MealSlot({
    required this.day,
    required this.time,
    required this.label,
  });

  final int day;
  final String time;
  final String label;

  String get key => '$day:$time:$label';
}

class _VehicleProposal {
  const _VehicleProposal({required this.entries});

  final List<_VehicleProposalEntry> entries;

  int get capacity => entries.fold<int>(
        0,
        (sum, entry) => sum + entry.capacity,
      );

  int get basePrice => entries.fold<int>(
        0,
        (sum, entry) => sum + entry.prestation.price.round() * entry.quantity,
      );

  String get label => entries
      .map(
        (entry) => entry.quantity > 1
            ? '${entry.quantity} x ${entry.prestation.name}'
            : entry.prestation.name,
      )
      .join(' + ');

  List<String> get mediaUrls => entries
      .expand((entry) => entry.prestation.mediaUrls)
      .toList(growable: false);
}

class _VehicleProposalEntry {
  const _VehicleProposalEntry({
    required this.prestation,
    required this.quantity,
  });

  final PartnerCatalogPrestation prestation;
  final int quantity;

  int get capacity => (prestation.capacity ?? 0) * quantity;
}

enum _FreeTimeDecision {
  skip,
  propose,
}

enum _HotelStage {
  hotels,
  rooms,
  meals,
}

enum _TransportStage {
  people,
  vehicles,
  logistics,
}

enum _TransportLogistics {
  dropOff,
  fullDisposal,
  returnPickup,
}

extension _TransportLogisticsLabel on _TransportLogistics {
  String get label => switch (this) {
        _TransportLogistics.dropOff => 'Dépôt uniquement',
        _TransportLogistics.fullDisposal => 'Mise à disposition complète',
        _TransportLogistics.returnPickup => 'Dépôt + Récupération',
      };

  int priceMultiplier({required int totalHours}) => switch (this) {
        _TransportLogistics.dropOff => 1,
        _TransportLogistics.fullDisposal => math.max(1, totalHours),
        _TransportLogistics.returnPickup => 2,
      };
}

enum _DriverCoverage {
  oneWay,
  roundTrip,
  continuous,
}

extension _DriverCoverageLabel on _DriverCoverage {
  String get label => switch (this) {
        _DriverCoverage.oneWay => 'Trajet Aller simple',
        _DriverCoverage.roundTrip => 'Trajet Aller-Retour',
        _DriverCoverage.continuous => 'Assistance continue durant le séjour',
      };
}
