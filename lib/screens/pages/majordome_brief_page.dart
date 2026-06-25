import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_preferences_controller.dart';
import '../../theme/app_theme.dart';

class MajordomeBriefPage extends StatefulWidget {
  const MajordomeBriefPage({super.key});

  @override
  State<MajordomeBriefPage> createState() => _MajordomeBriefPageState();
}

class _MajordomeBriefPageState extends State<MajordomeBriefPage> {
  late bool _enabled;
  late int _temperature;
  late String _drivingStyle;
  late String _soundAmbience;
  late final TextEditingController _instructionsController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final preferences = context.read<AppPreferencesController>();
    _enabled = preferences.majordomeEnabled;
    _temperature = preferences.cabinTemperature;
    _drivingStyle = preferences.drivingStyle;
    _soundAmbience = preferences.soundAmbience;
    _instructionsController = TextEditingController(
      text: preferences.permanentInstructions,
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<AppPreferencesController>().saveMajordomePreferences(
          enabled: _enabled,
          temperature: _temperature,
          style: _drivingStyle,
          ambience: _soundAmbience,
          instructions: _instructionsController.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final french =
        context.read<AppPreferencesController>().languageCode == 'fr';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          french
              ? 'Préférences du Majordome enregistrées.'
              : 'Butler preferences saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferencesController>();
    final french = preferences.languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          french ? 'MODE MAJORDOME' : 'BUTLER MODE',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Card(
            elevation: 0,
            child: SwitchListTile(
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              activeThumbColor: AppTheme.orange,
              secondary: const Icon(
                Icons.auto_awesome,
                color: AppTheme.orange,
              ),
              title: Text(
                french ? 'Activer le Majordome Drift' : 'Enable Drift Butler',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                french
                    ? 'Recommandations IA en temps réel'
                    : 'Real-time AI recommendations',
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle(
            french ? 'Mes Préférences Logistiques' : 'My Logistics Preferences',
          ),
          const SizedBox(height: 14),
          _preferenceCard(
            title: french
                ? 'Température à bord souhaitée'
                : 'Preferred cabin temperature',
            icon: Icons.thermostat_outlined,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <int>[19, 21, 23, 25]
                  .map(
                    (temperature) => ChoiceChip(
                      label: Text('$temperature°C'),
                      selected: _temperature == temperature,
                      selectedColor: AppTheme.orange,
                      labelStyle: TextStyle(
                        color: _temperature == temperature
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) =>
                          setState(() => _temperature = temperature),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          _preferenceCard(
            title: french ? 'Style de conduite' : 'Driving style',
            icon: Icons.speed_outlined,
            child: _choiceWrap(
              <String, String>{
                'calm': french ? 'Calme / Éco' : 'Calm / Eco',
                'standard': 'Standard',
                'dynamic': french ? 'Dynamique' : 'Dynamic',
              },
              selected: _drivingStyle,
              onSelected: (value) => setState(() => _drivingStyle = value),
            ),
          ),
          _preferenceCard(
            title: french ? 'Ambiance sonore' : 'Sound ambience',
            icon: Icons.graphic_eq_outlined,
            child: _choiceWrap(
              <String, String>{
                'silence': french ? 'Silence' : 'Silence',
                'lounge': french ? 'Musique Lounge' : 'Lounge Music',
                'business':
                    french ? 'Actualités / Business' : 'News / Business',
              },
              selected: _soundAmbience,
              onSelected: (value) => setState(() => _soundAmbience = value),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _instructionsController,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: french
                  ? 'Consignes permanentes pour vos trajets'
                  : 'Permanent trip instructions',
              hintText: french
                  ? 'Toujours prévoir une bouteille d’eau, ne pas déranger pendant les appels...'
                  : 'Always provide water, do not disturb during calls...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 72),
                child: Icon(Icons.edit_note_outlined),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                french
                    ? 'Enregistrer les préférences du Majordome'
                    : 'Save Butler preferences',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _preferenceCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.orange, size: 20),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _choiceWrap(
    Map<String, String> options, {
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: options.entries
          .map(
            (entry) => ChoiceChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              selectedColor: AppTheme.orange,
              labelStyle: TextStyle(
                color: selected == entry.key
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) => onSelected(entry.key),
            ),
          )
          .toList(growable: false),
    );
  }
}
