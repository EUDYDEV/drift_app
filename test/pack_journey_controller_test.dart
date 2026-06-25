import 'package:drift_app/controllers/home_journey_controller.dart';
import 'package:drift_app/controllers/pack_journey_controller.dart';
import 'package:drift_app/models/cart_model.dart';
import 'package:drift_app/models/location_model.dart';
import 'package:drift_app/models/pack_journey_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CartModel.clear();
    CartModel.setBudgetLimit(null);
  });

  test('sans chauffeur est bloqué pour un simple dépôt', () {
    final controller = PackJourneyController()
      ..updateFleetOption(DriftFleetOption.dropOff);

    expect(controller.updateWithoutDriver(true), isFalse);
    expect(controller.withoutDriver, isFalse);
    expect(controller.noticeMessage, isNotNull);
  });

  test('sans chauffeur est autorisé pour toute la durée du séjour', () {
    final controller = PackJourneyController()
      ..updateDuration(4)
      ..updateFleetOption(DriftFleetOption.customDisposal)
      ..updateDisposalDays(4);

    expect(controller.updateWithoutDriver(true), isTrue);
    expect(controller.withoutDriver, isTrue);
  });

  test('un groupe de plus de quinze personnes reçoit un autocar', () {
    final controller = PackJourneyController()
      ..updateMoment(PackMomentType.group)
      ..updateGroupSize(24)
      ..updateBudget(500000);

    expect(controller.generatePlan(), isTrue);
    expect(controller.plan!.vehicleLabel, 'Autocar 30 places ou plus');
    expect(controller.plan!.total, lessThanOrEqualTo(500000));
  });

  test('les trois repas obligatoires sont générés chaque jour', () {
    final controller = PackJourneyController()
      ..updateDuration(3)
      ..updateBudget(400000);

    expect(controller.generatePlan(), isTrue);
    final meals = controller.plan!.items
        .where((item) => item.category == PackTimelineCategory.meal)
        .toList();

    expect(meals, hasLength(9));
    expect(meals.map((item) => item.timeLabel).toSet(),
        containsAll(<String>{'09h00', '12h00', '19h30'}));
  });

  test('les repas hôtel restent dans la timeline sans frais externes', () {
    final controller = PackJourneyController()
      ..updateDuration(2)
      ..updateMealsAtHotel(true)
      ..updateBudget(300000);

    expect(controller.generatePlan(), isTrue);
    final meals = controller.plan!.items
        .where((item) => item.category == PackTimelineCategory.meal);

    expect(meals, hasLength(6));
    expect(meals.every((item) => item.price == 0), isTrue);
    expect(meals.every((item) => item.title.contains('hôtel')), isTrue);
  });

  test('le mode famille génère deux pistes parallèles', () {
    final controller = PackJourneyController()
      ..updateMoment(PackMomentType.family)
      ..updateBudget(350000);

    expect(controller.generatePlan(), isTrue);
    final tracks = controller.plan!.items.map((item) => item.track).toSet();

    expect(tracks, contains('Enfants'));
    expect(tracks, contains('Parents'));
  });

  test('un remplacement dépassant le budget est refusé', () {
    final controller = PackJourneyController()..updateBudget(250000);
    expect(controller.generatePlan(), isTrue);
    final activity = controller.plan!.items.firstWhere(
      (item) => item.category == PackTimelineCategory.activity,
    );

    final accepted = controller.replaceItem(
      activity.id,
      const PackTimelineAlternative(
        title: 'Option hors budget',
        subtitle: 'Test',
        price: 500000,
      ),
    );

    expect(accepted, isFalse);
    expect(controller.noticeMessage, contains('dépasserait'));
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
