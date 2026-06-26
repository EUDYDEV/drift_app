enum PackMomentType {
  family,
  group,
  couple,
  business,
}

extension PackMomentTypeLabel on PackMomentType {
  String get label => switch (this) {
        PackMomentType.family => 'Vacances en famille',
        PackMomentType.group => 'Sortie / voyage de groupe',
        PackMomentType.couple => 'Premier rendez-vous / couple',
        PackMomentType.business => 'Voyage d’affaires',
      };
}

enum PackTransportMode {
  driftFleet,
  external,
  personal,
}

extension PackTransportModeLabel on PackTransportMode {
  String get label => switch (this) {
        PackTransportMode.driftFleet => 'Flotte Drift',
        PackTransportMode.external => 'Transport commun / externe',
        PackTransportMode.personal => 'Véhicule personnel',
      };
}

enum DriftFleetOption {
  dropOff,
  customDisposal,
  returnPickup,
}

extension DriftFleetOptionLabel on DriftFleetOption {
  String get label => switch (this) {
        DriftFleetOption.dropOff => 'Dépôt / liaison uniquement',
        DriftFleetOption.customDisposal => 'Mise à disposition personnalisée',
        DriftFleetOption.returnPickup =>
          'Dépôt initial + récupération au retour',
      };
}

enum PackTimelineCategory {
  transport,
  accommodation,
  meal,
  activity,
  meeting,
}

class PackTimelineAlternative {
  const PackTimelineAlternative({
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final String title;
  final String subtitle;
  final int price;
}

class PackTimelineItem {
  const PackTimelineItem({
    required this.id,
    required this.day,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    this.track = 'Tous',
    this.mandatory = false,
    this.hiddenFromCompanion = false,
    this.alternatives = const <PackTimelineAlternative>[],
    this.partnerId,
    this.prestationId,
    this.partnerName,
    this.partnerType,
    this.partnerCity,
    this.partnerAddress,
    this.partnerLatitude,
    this.partnerLongitude,
    this.serviceType,
    this.mediaUrls = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final int day;
  final String timeLabel;
  final String title;
  final String subtitle;
  final PackTimelineCategory category;
  final int price;
  final String track;
  final bool mandatory;
  final bool hiddenFromCompanion;
  final List<PackTimelineAlternative> alternatives;
  final String? partnerId;
  final String? prestationId;
  final String? partnerName;
  final String? partnerType;
  final String? partnerCity;
  final String? partnerAddress;
  final double? partnerLatitude;
  final double? partnerLongitude;
  final String? serviceType;
  final List<String> mediaUrls;
  final Map<String, dynamic> metadata;

  PackTimelineItem copyWithAlternative(PackTimelineAlternative alternative) {
    return PackTimelineItem(
      id: id,
      day: day,
      timeLabel: timeLabel,
      title: alternative.title,
      subtitle: alternative.subtitle,
      category: category,
      price: alternative.price,
      track: track,
      mandatory: mandatory,
      hiddenFromCompanion: hiddenFromCompanion,
      alternatives: alternatives,
      partnerId: partnerId,
      prestationId: prestationId,
      partnerName: partnerName,
      partnerType: partnerType,
      partnerCity: partnerCity,
      partnerAddress: partnerAddress,
      partnerLatitude: partnerLatitude,
      partnerLongitude: partnerLongitude,
      serviceType: serviceType,
      mediaUrls: mediaUrls,
      metadata: metadata,
    );
  }
}

class PackJourneyPlan {
  const PackJourneyPlan({
    required this.destination,
    required this.vehicleLabel,
    required this.items,
    required this.maxBudget,
    this.existingCartTotal = 0,
  });

  final String destination;
  final String vehicleLabel;
  final List<PackTimelineItem> items;
  final int maxBudget;
  final int existingCartTotal;

  int get journeyTotal => items.fold(0, (sum, item) => sum + item.price);
  int get total => existingCartTotal + journeyTotal;
  int get remaining => maxBudget - total;
}
