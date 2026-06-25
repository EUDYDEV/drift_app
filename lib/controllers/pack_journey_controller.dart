import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../models/pack_journey_model.dart';
import '../theme/app_colors.dart';

class PackJourneyController extends ChangeNotifier {
  static const String cartGroupKey = 'drift-generated-pack';

  String destination = 'Assinie';
  int maxBudget = 250000;
  int durationDays = 2;
  PackMomentType momentType = PackMomentType.family;
  PackTransportMode transportMode = PackTransportMode.driftFleet;
  DriftFleetOption fleetOption = DriftFleetOption.customDisposal;
  int disposalDays = 2;
  bool withoutDriver = false;
  bool hotelHasRestaurant = true;
  bool mealsAtHotel = false;
  int adults = 2;
  List<int> childrenAges = const <int>[7];
  int groupSize = 6;
  bool groupHasOwnProgram = false;
  bool secretSurprise = false;
  String meetingSchedule = '09h00 - 12h00';

  PackJourneyPlan? plan;
  String? errorMessage;
  String? noticeMessage;

  bool get canUseWithoutDriver =>
      transportMode == PackTransportMode.driftFleet &&
      fleetOption == DriftFleetOption.customDisposal &&
      disposalDays >= durationDays;

  void updateDestination(String value) {
    destination = value.trim();
    notifyListeners();
  }

  void updateBudget(int value) {
    maxBudget = math.max(0, value);
    notifyListeners();
  }

  void updateDuration(int value) {
    durationDays = value.clamp(1, 30);
    disposalDays = disposalDays.clamp(1, durationDays);
    if (!canUseWithoutDriver) withoutDriver = false;
    notifyListeners();
  }

  void updateMoment(PackMomentType value) {
    momentType = value;
    notifyListeners();
  }

  void updateTransportMode(PackTransportMode value) {
    transportMode = value;
    if (value != PackTransportMode.driftFleet) {
      withoutDriver = false;
    }
    notifyListeners();
  }

  void updateFleetOption(DriftFleetOption value) {
    fleetOption = value;
    if (!canUseWithoutDriver) withoutDriver = false;
    notifyListeners();
  }

  void updateDisposalDays(int value) {
    disposalDays = value.clamp(1, durationDays);
    if (!canUseWithoutDriver) withoutDriver = false;
    notifyListeners();
  }

  bool updateWithoutDriver(bool value) {
    if (value && !canUseWithoutDriver) {
      withoutDriver = false;
      noticeMessage =
          'Un chauffeur Drift est obligatoire pour ramener le véhicule à Abidjan.';
      notifyListeners();
      return false;
    }
    withoutDriver = value;
    noticeMessage = null;
    notifyListeners();
    return true;
  }

  void updateAdults(int value) {
    adults = value.clamp(1, 20);
    notifyListeners();
  }

  void updateChildrenAges(List<int> ages) {
    childrenAges = ages.where((age) => age >= 0 && age <= 17).toList();
    notifyListeners();
  }

  void updateGroupSize(int value) {
    groupSize = value.clamp(1, 60);
    notifyListeners();
  }

  void updateGroupProgram(bool value) {
    groupHasOwnProgram = value;
    notifyListeners();
  }

  void updateHotelRestaurant(bool value) {
    hotelHasRestaurant = value;
    if (!value) mealsAtHotel = false;
    notifyListeners();
  }

  void updateMealsAtHotel(bool value) {
    mealsAtHotel = hotelHasRestaurant && value;
    notifyListeners();
  }

  void updateSecretSurprise(bool value) {
    secretSurprise = value;
    notifyListeners();
  }

  void updateMeetingSchedule(String value) {
    meetingSchedule = value.trim();
    notifyListeners();
  }

  bool generatePlan() {
    errorMessage = null;
    noticeMessage = null;

    if (destination.isEmpty) {
      errorMessage = 'Renseignez une destination.';
      notifyListeners();
      return false;
    }
    if (maxBudget < 50000) {
      errorMessage = 'Le budget minimum conseillé est de 50 000 CFA.';
      notifyListeners();
      return false;
    }
    if (withoutDriver && !canUseWithoutDriver) {
      errorMessage =
          'Le mode sans chauffeur exige une mise à disposition pendant tout le séjour.';
      withoutDriver = false;
      notifyListeners();
      return false;
    }

    final existingCartTotal = CartModel.itemsOutsideGroup(cartGroupKey)
        .fold<int>(0, (sum, item) => sum + item.priceValue);
    final journeyBudget = maxBudget - existingCartTotal;
    if (journeyBudget < 50000) {
      errorMessage =
          'Les prestations déjà sélectionnées laissent un budget insuffisant pour générer ce séjour.';
      notifyListeners();
      return false;
    }

    final items = <PackTimelineItem>[];
    final transportPrice = _transportPrice();
    final accommodationPrice = (journeyBudget * 0.30).round();
    final includeMealsAndActivities =
        !(momentType == PackMomentType.group && groupHasOwnProgram);
    final mealsPrice = includeMealsAndActivities && !mealsAtHotel
        ? (journeyBudget * 0.24).round()
        : 0;
    final mandatoryTotal = transportPrice + accommodationPrice + mealsPrice;

    if (mandatoryTotal > journeyBudget) {
      errorMessage =
          'Ce budget ne couvre pas le transport, l’hébergement et les repas obligatoires.';
      notifyListeners();
      return false;
    }

    items.add(_transportItem(transportPrice));
    items.add(
      PackTimelineItem(
        id: 'hotel',
        day: 1,
        timeLabel: 'Séjour',
        title: _accommodationTitle(),
        subtitle:
            '$durationDays jour${durationDays > 1 ? 's' : ''} à $destination',
        category: PackTimelineCategory.accommodation,
        price: accommodationPrice,
        mandatory: true,
        alternatives: <PackTimelineAlternative>[
          PackTimelineAlternative(
            title: 'Hôtel partenaire Confort',
            subtitle: 'Chambre optimisée pour le budget',
            price: (accommodationPrice * 0.82).round(),
          ),
          PackTimelineAlternative(
            title: 'Hôtel partenaire Premium',
            subtitle: 'Standing supérieur et services inclus',
            price: math.min(
              journeyBudget - transportPrice - mealsPrice,
              (accommodationPrice * 1.12).round(),
            ),
          ),
        ],
      ),
    );

    if (includeMealsAndActivities) {
      _addMandatoryMeals(items, mealsPrice);
      final remaining =
          journeyBudget - items.fold<int>(0, (sum, item) => sum + item.price);
      _addMomentActivities(items, math.max(0, remaining));
    }

    final builtPlan = PackJourneyPlan(
      destination: destination,
      vehicleLabel: _vehicleLabel(),
      items: items,
      maxBudget: maxBudget,
      existingCartTotal: existingCartTotal,
    );

    if (builtPlan.total > maxBudget) {
      errorMessage =
          'La proposition dépasse le budget. Augmentez le budget ou réduisez la durée.';
      notifyListeners();
      return false;
    }

    plan = builtPlan;
    CartModel.setBudgetLimit(maxBudget, label: 'Budget max global');
    _syncPlanToCart();
    notifyListeners();
    return true;
  }

  bool replaceItem(
    String itemId,
    PackTimelineAlternative alternative,
  ) {
    final currentPlan = plan;
    if (currentPlan == null) return false;
    final index = currentPlan.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return false;

    final current = currentPlan.items[index];
    final projected = currentPlan.total - current.price + alternative.price;
    if (projected > maxBudget) {
      noticeMessage =
          'Ce remplacement dépasserait le budget de ${CartModel.formatCurrency(projected - maxBudget)}.';
      notifyListeners();
      return false;
    }

    final updatedItems = List<PackTimelineItem>.from(currentPlan.items)
      ..[index] = current.copyWithAlternative(alternative);
    plan = PackJourneyPlan(
      destination: currentPlan.destination,
      vehicleLabel: currentPlan.vehicleLabel,
      items: updatedItems,
      maxBudget: currentPlan.maxBudget,
      existingCartTotal: currentPlan.existingCartTotal,
    );
    noticeMessage = 'Le budget a été recalculé.';
    _syncPlanToCart();
    notifyListeners();
    return true;
  }

  int _transportPrice() {
    if (transportMode == PackTransportMode.personal) return 0;
    if (transportMode == PackTransportMode.external) return 35000;

    final base = switch (fleetOption) {
      DriftFleetOption.dropOff => 30000,
      DriftFleetOption.customDisposal => 28000 * disposalDays,
      DriftFleetOption.returnPickup => 55000,
    };
    final capacityMultiplier = switch (_vehicleLabel()) {
      'Minivan VIP' => 1.35,
      'Autocar 30 places ou plus' => 2.2,
      'Grand SUV / Van familial' => 1.25,
      _ => 1.0,
    };
    return (base * capacityMultiplier).round();
  }

  String _vehicleLabel() {
    if (transportMode == PackTransportMode.personal) {
      return 'Véhicule personnel';
    }
    if (momentType == PackMomentType.family) {
      return 'Grand SUV / Van familial';
    }
    if (momentType == PackMomentType.group) {
      if (groupSize <= 4) return 'Berline / SUV';
      if (groupSize <= 15) return 'Minivan VIP';
      return 'Autocar 30 places ou plus';
    }
    if (momentType == PackMomentType.business) {
      return 'Berline avec chauffeur dédié';
    }
    return 'Berline premium';
  }

  PackTimelineItem _transportItem(int price) {
    final subtitle = switch (transportMode) {
      PackTransportMode.personal => 'Aucun frais de véhicule appliqué',
      PackTransportMode.external =>
        'Dépôt à la gare puis accueil chauffeur à l’arrivée',
      PackTransportMode.driftFleet => switch (fleetOption) {
          DriftFleetOption.dropOff =>
            'Trajet aller simple avec chauffeur obligatoire',
          DriftFleetOption.customDisposal =>
            '$disposalDays jour${disposalDays > 1 ? 's' : ''} de mise à disposition${withoutDriver ? ', sans chauffeur' : ', avec chauffeur'}',
          DriftFleetOption.returnPickup =>
            'Dépôt initial et récupération le jour du retour',
        },
    };

    return PackTimelineItem(
      id: 'transport',
      day: 1,
      timeLabel: 'Départ',
      title: _vehicleLabel(),
      subtitle: subtitle,
      category: PackTimelineCategory.transport,
      price: price,
      mandatory: true,
      alternatives: transportMode == PackTransportMode.personal
          ? const <PackTimelineAlternative>[
              PackTimelineAlternative(
                title: 'Véhicule personnel',
                subtitle: 'Conserver cette option sans frais',
                price: 0,
              ),
            ]
          : <PackTimelineAlternative>[
              PackTimelineAlternative(
                title: _vehicleLabel(),
                subtitle: 'Formule économique avec prise en charge Drift',
                price: (price * 0.85).round(),
              ),
            ],
    );
  }

  String _accommodationTitle() {
    if (momentType == PackMomentType.group) {
      return 'Hébergement de groupe';
    }
    if (momentType == PackMomentType.couple) {
      return 'Suite élégante pour deux';
    }
    if (momentType == PackMomentType.business) {
      return 'Hôtel business calme';
    }
    return 'Hébergement familial';
  }

  void _addMandatoryMeals(
    List<PackTimelineItem> items,
    int totalMealBudget,
  ) {
    final perDay =
        durationDays == 0 ? 0 : (totalMealBudget / durationDays).round();
    final breakfast = mealsAtHotel ? 0 : (perDay * 0.25).round();
    final lunch = mealsAtHotel ? 0 : (perDay * 0.35).round();
    final dinner = mealsAtHotel ? 0 : perDay - breakfast - lunch;

    for (var day = 1; day <= durationDays; day++) {
      items.addAll(<PackTimelineItem>[
        _mealItem(day, '09h00', 'Petit-déjeuner', breakfast),
        _mealItem(day, '12h00', 'Déjeuner', lunch),
        _mealItem(day, '19h30', 'Dîner', dinner),
      ]);
    }
  }

  PackTimelineItem _mealItem(
    int day,
    String time,
    String label,
    int price,
  ) {
    final title = mealsAtHotel ? '$label à l’hôtel' : label;
    return PackTimelineItem(
      id: 'meal-$day-$time',
      day: day,
      timeLabel: time,
      title: title,
      subtitle: mealsAtHotel
          ? 'Inclus dans la formule d’hébergement'
          : 'Adresse partenaire proche de votre parcours',
      category: PackTimelineCategory.meal,
      price: price,
      mandatory: true,
      alternatives: mealsAtHotel
          ? <PackTimelineAlternative>[
              PackTimelineAlternative(
                title: '$label à l’hôtel',
                subtitle: 'Autre formule incluse dans l’hébergement',
                price: 0,
              ),
            ]
          : <PackTimelineAlternative>[
              PackTimelineAlternative(
                title: '$label local',
                subtitle: 'Cuisine ivoirienne partenaire',
                price: (price * 0.82).round(),
              ),
              PackTimelineAlternative(
                title: '$label premium',
                subtitle: 'Cadre haut de gamme',
                price: (price * 1.08).round(),
              ),
            ],
    );
  }

  void _addMomentActivities(
    List<PackTimelineItem> items,
    int availableBudget,
  ) {
    if (availableBudget <= 0) return;
    final dayCount = math.max(1, durationDays);
    final unit = math.max(0, (availableBudget / (dayCount * 2)).floor());

    for (var day = 1; day <= dayCount; day++) {
      switch (momentType) {
        case PackMomentType.family:
          items.addAll(<PackTimelineItem>[
            _activity(
              id: 'family-child-$day',
              day: day,
              time: '15h00',
              title: 'Parc et jeux surveillés',
              subtitle:
                  'Activité adaptée aux enfants (${childrenAges.join(', ')} ans)',
              track: 'Enfants',
              price: unit,
            ),
            _activity(
              id: 'family-parent-$day',
              day: day,
              time: '15h00',
              title: 'Détente Spa ou cinéma',
              subtitle: 'Temps libre parents, en parallèle',
              track: 'Parents',
              price: unit,
            ),
          ]);
        case PackMomentType.group:
          items.add(
            _activity(
              id: 'group-$day',
              day: day,
              time: '15h00',
              title: 'Expérience collective à $destination',
              subtitle: '$groupSize participants',
              track: 'Groupe',
              price: unit * 2,
            ),
          );
        case PackMomentType.couple:
          items.addAll(<PackTimelineItem>[
            _activity(
              id: 'couple-$day',
              day: day,
              time: '17h30',
              title: 'Escapade élégante à deux',
              subtitle: 'Parcours fluide, sans logistique lourde',
              track: 'Couple',
              price: unit,
              hidden: secretSurprise,
            ),
            _activity(
              id: 'couple-lounge-$day',
              day: day,
              time: '20h30',
              title: 'Lounge sélect pour deux',
              subtitle: 'Réservation instantanée, cadre feutré',
              track: 'Couple',
              price: unit,
              hidden: secretSurprise,
            ),
          ]);
        case PackMomentType.business:
          items.addAll(<PackTimelineItem>[
            PackTimelineItem(
              id: 'meeting-$day',
              day: day,
              timeLabel: meetingSchedule.isEmpty ? 'Réunion' : meetingSchedule,
              title: 'Créneau de réunion bloqué',
              subtitle: 'Chauffeur dédié en attente',
              category: PackTimelineCategory.meeting,
              price: 0,
              track: 'Affaires',
              mandatory: true,
              alternatives: const <PackTimelineAlternative>[
                PackTimelineAlternative(
                  title: 'Créneau de réunion ajusté',
                  subtitle: 'Conserver le chauffeur dédié en attente',
                  price: 0,
                ),
              ],
            ),
            _activity(
              id: 'business-$day',
              day: day,
              time: '16h00',
              title: 'Session Golf ou rendez-vous calme',
              subtitle: 'Temps libre organisé autour des réunions',
              track: 'Affaires',
              price: unit * 2,
            ),
          ]);
      }
    }
  }

  PackTimelineItem _activity({
    required String id,
    required int day,
    required String time,
    required String title,
    required String subtitle,
    required String track,
    required int price,
    bool hidden = false,
  }) {
    return PackTimelineItem(
      id: id,
      day: day,
      timeLabel: time,
      title: title,
      subtitle: subtitle,
      category: PackTimelineCategory.activity,
      price: price,
      track: track,
      hiddenFromCompanion: hidden,
      alternatives: <PackTimelineAlternative>[
        PackTimelineAlternative(
          title: 'Alternative locale',
          subtitle: 'Expérience proche et budget optimisé',
          price: (price * 0.75).round(),
        ),
        PackTimelineAlternative(
          title: 'Alternative premium',
          subtitle: 'Expérience exclusive partenaire',
          price: (price * 1.12).round(),
        ),
      ],
    );
  }

  void _syncPlanToCart() {
    final currentPlan = plan;
    if (currentPlan == null) return;
    final items = currentPlan.items
        .where((item) => item.price > 0)
        .map(
          (item) => CartItem(
            id: 'pack:${item.id}',
            type: switch (item.category) {
              PackTimelineCategory.transport => 'chauffeur',
              PackTimelineCategory.accommodation => 'hotel',
              PackTimelineCategory.meal => 'restaurant',
              _ => 'activity',
            },
            name: item.title,
            subtitle: 'Jour ${item.day} · ${item.timeLabel} · ${item.track}',
            priceDisplay: CartModel.formatCurrency(item.price),
            priceValue: item.price,
            color: _categoryColor(item.category),
            icon: _categoryIcon(item.category),
            groupKey: cartGroupKey,
            partnerCity: destination,
            metadata: <String, dynamic>{
              'day': item.day,
              'time': item.timeLabel,
              'track': item.track,
              'hiddenFromCompanion': item.hiddenFromCompanion,
              'mandatory': item.mandatory,
            },
          ),
        )
        .toList(growable: false);
    CartModel.syncGroup(cartGroupKey, items);
  }

  Color _categoryColor(PackTimelineCategory category) => switch (category) {
        PackTimelineCategory.transport => AppColors.gradientBlue,
        PackTimelineCategory.accommodation => const Color(0xFF00A878),
        PackTimelineCategory.meal => AppColors.orange,
        PackTimelineCategory.activity => const Color(0xFF8B5CF6),
        PackTimelineCategory.meeting => const Color(0xFF374151),
      };

  IconData _categoryIcon(PackTimelineCategory category) => switch (category) {
        PackTimelineCategory.transport => Icons.directions_car_outlined,
        PackTimelineCategory.accommodation => Icons.hotel_outlined,
        PackTimelineCategory.meal => Icons.restaurant_outlined,
        PackTimelineCategory.activity => Icons.local_activity_outlined,
        PackTimelineCategory.meeting => Icons.business_center_outlined,
      };
}
