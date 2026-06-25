import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/pack_journey_controller.dart';
import '../models/cart_model.dart';
import '../models/pack_journey_model.dart';
import '../theme/app_colors.dart';
import 'driving_license_verification_sheet.dart';

class PackConfiguratorPanel extends StatefulWidget {
  const PackConfiguratorPanel({super.key});

  @override
  State<PackConfiguratorPanel> createState() => _PackConfiguratorPanelState();
}

class _PackConfiguratorPanelState extends State<PackConfiguratorPanel> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  final _childrenAgesController = TextEditingController();
  final _meetingController = TextEditingController();
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PackJourneyController>();
    _destinationController.text = controller.destination;
    _budgetController.text = controller.maxBudget.toString();
    _durationController.text = controller.durationDays.toString();
    _childrenAgesController.text = controller.childrenAges.join(', ');
    _meetingController.text = controller.meetingSchedule;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    _childrenAgesController.dispose();
    _meetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PackJourneyController>();
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
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
                            controller.plan == null
                                ? 'Créez votre séjour sur mesure'
                                : '${controller.plan!.destination} · ${CartModel.formatCurrency(controller.plan!.total)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppColors.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.grayText,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFFEEEEF1)),
                    const SizedBox(height: 14),
                    _textField(
                      controller: _destinationController,
                      label: 'Destination',
                      hint: 'Assinie, Yamoussoukro...',
                      icon: Icons.place_outlined,
                      onChanged: controller.updateDestination,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _budgetController,
                            label: 'Budget max global (CFA)',
                            hint: '250000',
                            icon: Icons.account_balance_wallet_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              controller.updateBudget(
                                int.tryParse(value.replaceAll(' ', '')) ?? 0,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            controller: _durationController,
                            label: 'Durée (jours)',
                            hint: '2',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              controller.updateDuration(
                                int.tryParse(value) ?? 1,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionLabel('Type de moment'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PackMomentType>(
                      initialValue: controller.momentType,
                      decoration: _inputDecoration(Icons.auto_awesome_outlined),
                      items: PackMomentType.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) controller.updateMoment(value);
                      },
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('Transport'),
                    const SizedBox(height: 8),
                    RadioGroup<PackTransportMode>(
                      groupValue: controller.transportMode,
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateTransportMode(value);
                        }
                      },
                      child: Column(
                        children: PackTransportMode.values
                            .map(
                              (mode) => RadioListTile<PackTransportMode>(
                                value: mode,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.orange,
                                title: Text(
                                  mode.label,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    if (controller.transportMode ==
                        PackTransportMode.driftFleet)
                      _fleetOptions(controller),
                    if (controller.transportMode == PackTransportMode.external)
                      _infoCard(
                        'Drift organise le dépôt à la gare de départ et un chauffeur vous attend à la gare d’arrivée.',
                      ),
                    if (controller.transportMode == PackTransportMode.personal)
                      _infoCard(
                        'La gestion du transport est masquée et les frais véhicule passent à 0 CFA.',
                      ),
                    const SizedBox(height: 16),
                    _momentFields(controller),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.orange,
                      title: Text(
                        'L’hébergement possède un restaurant',
                        style: _optionStyle(),
                      ),
                      value: controller.hotelHasRestaurant,
                      onChanged: controller.updateHotelRestaurant,
                    ),
                    if (controller.hotelHasRestaurant)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.orange,
                        title: Text(
                          'Prendre les repas à l’hôtel',
                          style: _optionStyle(),
                        ),
                        subtitle: const Text(
                          'Les restaurants externes et leurs frais seront retirés.',
                        ),
                        value: controller.mealsAtHotel,
                        onChanged: (value) =>
                            controller.updateMealsAtHotel(value ?? false),
                      ),
                    if (controller.errorMessage != null)
                      _messageCard(
                        controller.errorMessage!,
                        color: Colors.redAccent,
                      ),
                    if (controller.noticeMessage != null)
                      _messageCard(
                        controller.noticeMessage!,
                        color: AppColors.orange,
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          final generated = controller.generatePlan();
                          if (generated) {
                            setState(() => _expanded = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          'GÉNÉRER MON PACK',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (controller.plan != null) _buildPlan(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _fleetOptions(PackJourneyController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            RadioGroup<DriftFleetOption>(
              groupValue: controller.fleetOption,
              onChanged: (value) {
                if (value != null) controller.updateFleetOption(value);
              },
              child: Column(
                children: DriftFleetOption.values
                    .map(
                      (option) => RadioListTile<DriftFleetOption>(
                        value: option,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.orange,
                        title: Text(option.label, style: _optionStyle()),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            if (controller.fleetOption == DriftFleetOption.customDisposal) ...[
              Row(
                children: [
                  Text('Jours de garde', style: _optionStyle()),
                  const Spacer(),
                  IconButton(
                    onPressed: controller.disposalDays > 1
                        ? () => controller
                            .updateDisposalDays(controller.disposalDays - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${controller.disposalDays}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.disposalDays < controller.durationDays
                        ? () => controller.updateDisposalDays(
                              controller.disposalDays + 1,
                            )
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.orange,
              title: Text('Sans chauffeur', style: _optionStyle()),
              subtitle: Text(
                controller.canUseWithoutDriver
                    ? 'Autorisé : le véhicule est conservé pendant tout le séjour.'
                    : 'Indisponible pour cette formule logistique.',
              ),
              value: controller.withoutDriver,
              onChanged: (value) async {
                final wantsSelfDrive = value ?? false;
                if (wantsSelfDrive) {
                  final verified = await ensureSelfDriveVerification(context);
                  if (!verified || !mounted) return;
                }

                final accepted = controller.updateWithoutDriver(wantsSelfDrive);
                if (!accepted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Un chauffeur Drift est obligatoire pour cette formule.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _momentFields(PackJourneyController controller) {
    return switch (controller.momentType) {
      PackMomentType.family => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _numberStepper(
                    label: 'Adultes',
                    value: controller.adults,
                    onChanged: controller.updateAdults,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _childrenAgesController,
                    label: 'Âges des enfants',
                    hint: '4, 7, 12',
                    icon: Icons.child_care_outlined,
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      controller.updateChildrenAges(
                        value
                            .split(',')
                            .map((part) => int.tryParse(part.trim()))
                            .whereType<int>()
                            .toList(growable: false),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      PackMomentType.group => Column(
          children: [
            _numberStepper(
              label: 'Nombre de personnes',
              value: controller.groupSize,
              onChanged: controller.updateGroupSize,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.orange,
              title: Text(
                'Nous avons déjà notre programme d’activités',
                style: _optionStyle(),
              ),
              subtitle: const Text(
                'Seuls le transport adapté et l’hébergement seront planifiés.',
              ),
              value: controller.groupHasOwnProgram,
              onChanged: (value) =>
                  controller.updateGroupProgram(value ?? false),
            ),
          ],
        ),
      PackMomentType.couple => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.orange,
          title: Text('Surprise Secrète', style: _optionStyle()),
          subtitle: const Text(
            'Certaines lignes seront masquées sur l’écran du conjoint.',
          ),
          value: controller.secretSurprise,
          onChanged: (value) => controller.updateSecretSurprise(value ?? false),
        ),
      PackMomentType.business => _textField(
          controller: _meetingController,
          label: 'Horaires de réunion',
          hint: '09h00 - 12h00',
          icon: Icons.schedule_outlined,
          onChanged: controller.updateMeetingSchedule,
        ),
    };
  }

  Widget _buildPlan(
    BuildContext context,
    PackJourneyController controller,
  ) {
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
            'PARCOURS PROPOSÉ',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.vehicleLabel} · ${CartModel.formatCurrency(plan.remaining)} restant',
            style: GoogleFonts.montserrat(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          ...days.entries.map(
            (entry) =>
                _dayTimeline(context, controller, entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _dayTimeline(
    BuildContext context,
    PackJourneyController controller,
    int day,
    List<PackTimelineItem> items,
  ) {
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
          ...items.map((item) => _timelineItem(context, controller, item)),
        ],
      ),
    );
  }

  Widget _timelineItem(
    BuildContext context,
    PackJourneyController controller,
    PackTimelineItem item,
  ) {
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
            width: 52,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.hiddenFromCompanion
                            ? 'Surprise masquée'
                            : item.title,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.track != 'Tous')
                      Text(
                        item.track,
                        style: GoogleFonts.montserrat(
                          color: AppColors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
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
                Row(
                  children: [
                    Text(
                      CartModel.formatCurrency(item.price),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (item.alternatives.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            _showAlternatives(context, controller, item),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.orange,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Modifier / Remplacer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlternatives(
    BuildContext context,
    PackJourneyController controller,
    PackTimelineItem item,
  ) async {
    final alternative = await showModalBottomSheet<PackTimelineAlternative>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Remplacer ${item.title}',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...item.alternatives.map(
              (candidate) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(candidate.title),
                subtitle: Text(candidate.subtitle),
                trailing: Text(CartModel.formatCurrency(candidate.price)),
                onTap: () => Navigator.pop(sheetContext, candidate),
              ),
            ),
          ],
        ),
      ),
    );
    if (alternative == null || !context.mounted) return;
    final accepted = controller.replaceItem(item.id, alternative);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Prestation remplacée et budget recalculé.'
              : controller.noticeMessage ?? 'Remplacement impossible.',
        ),
      ),
    );
  }

  Widget _numberStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _optionStyle())),
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$value'),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
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

  Widget _infoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: GoogleFonts.montserrat(fontSize: 11)),
    );
  }

  Widget _messageCard(String text, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.darkText,
      ),
    );
  }

  TextStyle _optionStyle() => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      );
}
