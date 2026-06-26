import 'package:drift_app/controllers/home_journey_controller.dart';
import 'package:drift_app/controllers/pack_journey_controller.dart';
import 'package:drift_app/models/cart_model.dart';
import 'package:drift_app/models/hotel_model.dart';
import 'package:drift_app/models/location_model.dart';
import 'package:drift_app/models/pack_journey_model.dart';
import 'package:drift_app/models/partner_catalog_prestation.dart';
import 'package:drift_app/models/room_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CartModel.clear();
    CartModel.setBudgetLimit(null);
  });

  test('un plan vide est refusé', () {
    final controller = PackJourneyController();

    final accepted = controller.applySequentialPlan(
      destination: 'Assinie',
      durationDays: 2,
      durationHours: 0,
      momentType: PackMomentType.family,
      maxBudget: 300000,
      vehicleLabel: 'Flotte partenaire',
      items: const <PackTimelineItem>[],
    );

    expect(accepted, isFalse);
    expect(controller.errorMessage, isNotNull);
  });

  test('un plan réel synchronise le panier avec les IDs partenaires', () {
    final controller = PackJourneyController();
    final item = _timelineItem(price: 45000);

    final accepted = controller.applySequentialPlan(
      destination: 'Assinie',
      durationDays: 1,
      durationHours: 0,
      momentType: PackMomentType.couple,
      maxBudget: 100000,
      vehicleLabel: 'Berline partenaire',
      items: <PackTimelineItem>[item],
    );

    expect(accepted, isTrue);
    expect(controller.plan!.total, 45000);
    expect(CartModel.items, hasLength(1));
    expect(CartModel.items.first.prestationId, item.prestationId);
    expect(CartModel.items.first.priceValue, 45000);
  });

  test('le budget max bloque un pack trop cher', () {
    final controller = PackJourneyController();

    final accepted = controller.applySequentialPlan(
      destination: 'Assinie',
      durationDays: 1,
      durationHours: 0,
      momentType: PackMomentType.family,
      maxBudget: 20000,
      vehicleLabel: 'Berline partenaire',
      items: <PackTimelineItem>[_timelineItem(price: 45000)],
    );

    expect(accepted, isFalse);
    expect(CartModel.items, isEmpty);
  });

  test('hotelRoomItem multiplie le tarif réel par la durée', () {
    final controller = PackJourneyController();
    final hotel = Hotel(
      id: 'hotel-1',
      partnerId: 'partner-hotel-1',
      name: 'Hotel Partenaire',
      city: 'Assinie',
      description: 'Catalogue partenaire',
      rating: 4.6,
      reviewCount: 12,
      pricePerNight: 0,
      address: 'Assinie',
      amenities: const <String>[],
    );
    final room = Room(
      id: 'room-1',
      prestationId: 'prestation-room-1',
      partnerId: 'partner-hotel-1',
      roomType: 'Suite',
      capacity: 2,
      price: 60000,
      amenities: const <String>[],
      available: true,
    );

    final item = controller.hotelRoomItem(
      hotel: hotel,
      room: room,
      durationDays: 3,
    );

    expect(item.price, 180000);
    expect(item.prestationId, 'prestation-room-1');
    expect(item.serviceType, 'chambre_hotel');
  });

  test('un remplacement dépassant le budget est refusé', () {
    final controller = PackJourneyController();
    expect(
      controller.applySequentialPlan(
        destination: 'Assinie',
        durationDays: 1,
        durationHours: 0,
        momentType: PackMomentType.couple,
        maxBudget: 50000,
        vehicleLabel: 'Berline partenaire',
        items: <PackTimelineItem>[
          _timelineItem(price: 35000).copyWithAlternative(
            const PackTimelineAlternative(
              title: 'Activité partenaire',
              subtitle: 'Catalogue',
              price: 35000,
            ),
          ),
        ],
      ),
      isTrue,
    );

    final accepted = controller.replaceItem(
      'prestation-test',
      const PackTimelineAlternative(
        title: 'Option hors budget',
        subtitle: 'Test',
        price: 500000,
      ),
    );

    expect(accepted, isFalse);
    expect(controller.noticeMessage, contains('depasserait'));
  });

  test('prestationItem conserve le prix et les métadonnées catalogue', () {
    final controller = PackJourneyController();
    final prestation = PartnerCatalogPrestation(
      id: 'vehicle-1',
      partnerId: 'partner-transport-1',
      partnerName: 'Transport Partenaire',
      partnerType: 'transport',
      partnerIsBoosted: true,
      partnerLocation: AppLocation(
        latitude: 5.35,
        longitude: -4.0,
        address: 'Abidjan',
        city: 'Abidjan',
      ),
      typeService: 'location_voiture',
      name: 'Mini-car 30 places',
      price: 25000,
      cuisineCategory: null,
      capacity: 30,
      isAvailable: true,
      mediaUrls: const <String>['https://cdn.drift.test/minicar.jpg'],
      details: const <String, dynamic>{'city': 'Abidjan'},
    );

    final item = controller.prestationItem(
      prestation: prestation,
      category: PackTimelineCategory.transport,
      day: 1,
      timeLabel: 'Départ',
      subtitle: 'Mise à disposition complète',
      quantity: 2,
    );

    expect(item.price, 50000);
    expect(item.prestationId, 'vehicle-1');
    expect(item.metadata['pricingMultiplier'], 2);
    expect(item.metadata['capacity'], 30);
  });

  test('la destination en attente survit au changement de route', () {
    final controller = HomeJourneyController();
    final destination = AppLocation(
      latitude: 5.12,
      longitude: -3.29,
      address: 'Assinie',
    );

    controller.rememberDestination(destination);
    expect(controller.pendingDestination, same(destination));
    expect(controller.consumeDestination(), same(destination));
    expect(controller.pendingDestination, isNull);
  });
}

PackTimelineItem _timelineItem({required int price}) {
  return PackTimelineItem(
    id: 'prestation-test',
    day: 1,
    timeLabel: '12h00',
    title: 'Prestation partenaire',
    subtitle: 'Catalogue PostgreSQL',
    category: PackTimelineCategory.activity,
    price: price,
    partnerId: 'partner-test',
    prestationId: 'prestation-test',
    partnerName: 'Partenaire Test',
    partnerType: 'loisir',
    partnerCity: 'Assinie',
    partnerAddress: 'Assinie',
    partnerLatitude: 5.12,
    partnerLongitude: -3.29,
    serviceType: 'ticket_jeu',
    mediaUrls: const <String>['https://cdn.drift.test/activity.jpg'],
    metadata: const <String, dynamic>{
      'pricingMultiplier': 1,
      'unitPrice': 45000,
    },
  );
}
