import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../models/hotel_model.dart';
import '../models/pack_journey_model.dart';
import '../models/partner_catalog_prestation.dart';
import '../models/room_model.dart';
import '../theme/app_colors.dart';

class PackJourneyController extends ChangeNotifier {
  static const String cartGroupKey = 'drift-generated-pack';

  String destination = '';
  int maxBudget = 0;
  int durationDays = 1;
  int durationHours = 0;
  PackMomentType momentType = PackMomentType.family;
  PackJourneyPlan? plan;
  String? errorMessage;
  String? noticeMessage;

  int get totalTravelHours => durationDays * 24 + durationHours;

  void clearPlan() {
    plan = null;
    errorMessage = null;
    noticeMessage = null;
    CartModel.syncGroup(cartGroupKey, const <CartItem>[]);
    notifyListeners();
  }

  bool applySequentialPlan({
    required String destination,
    required int durationDays,
    required int durationHours,
    required PackMomentType momentType,
    required int maxBudget,
    required String vehicleLabel,
    required List<PackTimelineItem> items,
  }) {
    errorMessage = null;
    noticeMessage = null;

    final normalizedDestination = destination.trim();
    if (normalizedDestination.isEmpty) {
      errorMessage = 'Renseignez une destination.';
      notifyListeners();
      return false;
    }

    if (items.isEmpty) {
      errorMessage = 'Aucune prestation reelle n a ete selectionnee.';
      notifyListeners();
      return false;
    }

    final existingCartTotal = CartModel.itemsOutsideGroup(cartGroupKey)
        .fold<int>(0, (sum, item) => sum + item.priceValue);
    final builtPlan = PackJourneyPlan(
      destination: normalizedDestination,
      vehicleLabel: vehicleLabel,
      items: items,
      maxBudget: maxBudget,
      existingCartTotal: existingCartTotal,
    );

    if (maxBudget > 0 && builtPlan.total > maxBudget) {
      errorMessage =
          'Le pack depasse le budget max de ${CartModel.formatCurrency(builtPlan.total - maxBudget)}.';
      notifyListeners();
      return false;
    }

    this.destination = normalizedDestination;
    this.durationDays = durationDays.clamp(1, 30);
    this.durationHours = durationHours.clamp(0, 23);
    this.momentType = momentType;
    this.maxBudget = maxBudget;
    plan = builtPlan;

    CartModel.setBudgetLimit(maxBudget > 0 ? maxBudget : null,
        label: 'Budget max global');
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
    if (maxBudget > 0 && projected > maxBudget) {
      noticeMessage =
          'Ce remplacement depasserait le budget de ${CartModel.formatCurrency(projected - maxBudget)}.';
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
    noticeMessage = 'Le budget a ete recalcule.';
    _syncPlanToCart();
    notifyListeners();
    return true;
  }

  PackTimelineItem hotelRoomItem({
    required Hotel hotel,
    required Room room,
    required int durationDays,
  }) {
    final nights = durationDays.clamp(1, 30);
    final price = room.priceValue * nights;
    return PackTimelineItem(
      id: 'room:${room.id}',
      day: 1,
      timeLabel: 'Sejour',
      title: room.name,
      subtitle: '${hotel.name} - $nights nuit${nights > 1 ? 's' : ''}',
      category: PackTimelineCategory.accommodation,
      price: price,
      mandatory: true,
      partnerId: room.partnerId ?? hotel.partnerId,
      prestationId: room.prestationId ?? room.id,
      partnerName: hotel.name,
      partnerType: 'hotel',
      partnerCity: hotel.city,
      partnerAddress: hotel.address,
      partnerLatitude: hotel.latitude,
      partnerLongitude: hotel.longitude,
      serviceType: 'chambre_hotel',
      mediaUrls: <String>[...room.imageUrls, ...room.video360Urls],
      metadata: <String, dynamic>{
        'roomId': room.id,
        'roomType': room.roomType,
        'roomCapacity': room.capacity,
        'pricingMultiplier': nights,
        'unitPrice': room.priceValue,
        'video360Url': room.virtualTourUrl,
        'hotelHasWifi': hotel.wifiSsid != null,
      },
    );
  }

  PackTimelineItem includedHotelMealItem({
    required int day,
    required String timeLabel,
    required String mealLabel,
    required Hotel hotel,
  }) {
    return PackTimelineItem(
      id: 'hotel-meal:$day:$timeLabel',
      day: day,
      timeLabel: timeLabel,
      title: '$mealLabel a l hotel',
      subtitle: 'Inclus dans la formule du partenaire',
      category: PackTimelineCategory.meal,
      price: 0,
      mandatory: true,
      partnerId: hotel.partnerId ?? hotel.id,
      partnerName: hotel.name,
      partnerType: 'hotel',
      partnerCity: hotel.city,
      partnerAddress: hotel.address,
      partnerLatitude: hotel.latitude,
      partnerLongitude: hotel.longitude,
      serviceType: 'table_resto',
      metadata: const <String, dynamic>{
        'includedInHotelFormula': true,
      },
    );
  }

  PackTimelineItem prestationItem({
    required PartnerCatalogPrestation prestation,
    required PackTimelineCategory category,
    required int day,
    required String timeLabel,
    required String subtitle,
    String track = 'Tous',
    int quantity = 1,
    int? priceOverride,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    final price = priceOverride ?? (prestation.price.round() * safeQuantity);
    return PackTimelineItem(
      id: '${prestation.id}:$day:$timeLabel:${metadata.hashCode}',
      day: day,
      timeLabel: timeLabel,
      title: safeQuantity > 1
          ? '${prestation.name} x$safeQuantity'
          : prestation.name,
      subtitle: subtitle,
      category: category,
      price: price,
      track: track,
      mandatory: category != PackTimelineCategory.activity,
      partnerId: prestation.partnerId,
      prestationId: prestation.id,
      partnerName: prestation.partnerName,
      partnerType: prestation.partnerType,
      partnerCity: prestation.cityHint,
      partnerAddress: prestation.partnerLocation.address,
      partnerLatitude: prestation.partnerLocation.latitude,
      partnerLongitude: prestation.partnerLocation.longitude,
      serviceType: prestation.typeService,
      mediaUrls: prestation.mediaUrls,
      metadata: <String, dynamic>{
        'pricingMultiplier': safeQuantity,
        'unitPrice': prestation.price.round(),
        'capacity': prestation.capacity,
        'cuisineCategory': prestation.cuisineCategory,
        'partnerDetails': prestation.details,
        ...metadata,
      },
    );
  }

  PackTimelineItem meetingItem({
    required int day,
    required String timeLabel,
    required String destination,
  }) {
    return PackTimelineItem(
      id: 'meeting:$day:$timeLabel',
      day: day,
      timeLabel: timeLabel,
      title: 'Creneau professionnel bloque',
      subtitle: destination,
      category: PackTimelineCategory.meeting,
      price: 0,
      track: 'Affaires',
      mandatory: true,
      serviceType: 'ticket_jeu',
      metadata: const <String, dynamic>{
        'userDefinedTimelineBlock': true,
      },
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
            serviceType: item.serviceType ??
                switch (item.category) {
                  PackTimelineCategory.transport => 'location_voiture',
                  PackTimelineCategory.accommodation => 'chambre_hotel',
                  PackTimelineCategory.meal => 'table_resto',
                  PackTimelineCategory.activity => 'ticket_jeu',
                  PackTimelineCategory.meeting => 'ticket_jeu',
                },
            name: item.title,
            subtitle: 'Jour ${item.day} - ${item.timeLabel} - ${item.track}',
            priceDisplay: CartModel.formatCurrency(item.price),
            priceValue: item.price,
            color: _categoryColor(item.category),
            icon: _categoryIcon(item.category),
            groupKey: cartGroupKey,
            partnerId: item.partnerId,
            prestationId: item.prestationId,
            partnerName: item.partnerName,
            partnerType: item.partnerType,
            partnerCity: item.partnerCity ?? currentPlan.destination,
            partnerAddress: item.partnerAddress,
            partnerLatitude: item.partnerLatitude,
            partnerLongitude: item.partnerLongitude,
            metadata: <String, dynamic>{
              'day': item.day,
              'time': item.timeLabel,
              'track': item.track,
              'hiddenFromCompanion': item.hiddenFromCompanion,
              'mandatory': item.mandatory,
              'mediaUrls': item.mediaUrls,
              ...item.metadata,
              if (item.category == PackTimelineCategory.transport)
                'packTimeline': currentPlan.items
                    .map(
                      (timelineItem) => <String, dynamic>{
                        'day': timelineItem.day,
                        'time': timelineItem.timeLabel,
                        'title': timelineItem.title,
                        'subtitle': timelineItem.subtitle,
                        'track': timelineItem.track,
                        'category': timelineItem.category.name,
                      },
                    )
                    .toList(growable: false),
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
