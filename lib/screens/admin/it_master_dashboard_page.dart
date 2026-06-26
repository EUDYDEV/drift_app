import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/admin_dashboard_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ItMasterDashboardPage extends StatefulWidget {
  const ItMasterDashboardPage({super.key});

  @override
  State<ItMasterDashboardPage> createState() => _ItMasterDashboardPageState();
}

class _ItMasterDashboardPageState extends State<ItMasterDashboardPage> {
  late AdminService _adminService;
  Future<void>? _bootstrapFuture;

  AdminDashboardLayout? _layout;
  AdminSummary? _summary;
  AdminFinanceOverview? _finance;
  List<AdminFeatureFlag> _featureFlags = const <AdminFeatureFlag>[];
  List<AdminMaintenanceMode> _maintenanceModes = const <AdminMaintenanceMode>[];
  List<Map<String, dynamic>> _securityEvents = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _auditLogs = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _crashes = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _capacityAlerts = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _itExpenses = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reviews = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _pricingRules = const <Map<String, dynamic>>[];

  int _selectedTab = 0;
  bool _busy = false;
  String _lastAction = '';

  final _masterKeyController = TextEditingController();
  final _rbacUserController = TextEditingController();
  final _rbacRoleController = TextEditingController(text: 'manager');
  final _rbacPermissionsController = TextEditingController(
    text: 'logs.view,maintenance.manage',
  );
  final _partnerIdController = TextEditingController();
  final _partnerReasonController = TextEditingController();
  final _killUserController = TextEditingController();
  final _killPartnerController = TextEditingController();
  final _killReasonController = TextEditingController(
    text: 'Exclusion immediate depuis le dashboard Drift',
  );
  final _privacyUserController = TextEditingController();
  final _maintenanceScopeController = TextEditingController(text: 'global');
  final _maintenanceValueController = TextEditingController();
  final _maintenanceMessageController = TextEditingController(
    text: 'Drift revient dans quelques minutes.',
  );
  final _expenseProviderController = TextEditingController();
  final _expenseCategoryController = TextEditingController(text: 'serveur');
  final _expenseAmountController = TextEditingController();
  final _reviewIdController = TextEditingController();
  final _pricingNameController = TextEditingController();
  final _pricingServiceController = TextEditingController(text: 'transport');
  final _pricingCityController = TextEditingController(text: 'Abidjan');
  final _pricingCoefficientController = TextEditingController(text: '1.10');
  final _crashIdController = TextEditingController();
  final _impersonateUserController = TextEditingController();
  final _impersonateReasonController = TextEditingController(
    text: 'Reproduction support encadree',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminService = AdminService(authService: context.read<AuthService>());
    _bootstrapFuture ??= _bootstrapIfAllowed();
  }

  @override
  void dispose() {
    _masterKeyController.dispose();
    _rbacUserController.dispose();
    _rbacRoleController.dispose();
    _rbacPermissionsController.dispose();
    _partnerIdController.dispose();
    _partnerReasonController.dispose();
    _killUserController.dispose();
    _killPartnerController.dispose();
    _killReasonController.dispose();
    _privacyUserController.dispose();
    _maintenanceScopeController.dispose();
    _maintenanceValueController.dispose();
    _maintenanceMessageController.dispose();
    _expenseProviderController.dispose();
    _expenseCategoryController.dispose();
    _expenseAmountController.dispose();
    _reviewIdController.dispose();
    _pricingNameController.dispose();
    _pricingServiceController.dispose();
    _pricingCityController.dispose();
    _pricingCoefficientController.dispose();
    _crashIdController.dispose();
    _impersonateUserController.dispose();
    _impersonateReasonController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapIfAllowed() async {
    final auth = context.read<AuthService>();
    await auth.initialize();
    if (!auth.isAdmin) return;
    await _reloadDashboard();
  }

  Future<void> _reloadDashboard() async {
    final results = await Future.wait<dynamic>([
      _adminService.fetchLayout(),
      _adminService.fetchSummary(),
    ]);
    _layout = results[0] as AdminDashboardLayout;
    _summary = results[1] as AdminSummary;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Centre IT Drift',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Rafraichir',
              onPressed: _busy
                  ? null
                  : () => _runAction('Dashboard rafraichi', () async {
                        await _reloadDashboard();
                        return {'ok': true};
                      }),
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            tooltip: 'Se deconnecter',
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              setState(() {
                _layout = null;
                _summary = null;
                _bootstrapFuture = Future.value();
              });
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!auth.isAdmin) {
            return _buildMasterLogin(auth);
          }

          if (snapshot.hasError) {
            return _buildStatePanel(
              icon: Icons.warning_amber_rounded,
              title: 'Acces admin incomplet',
              message: snapshot.error.toString(),
              actionLabel: 'Reessayer',
              onAction: () => setState(() {
                _bootstrapFuture = _bootstrapIfAllowed();
              }),
            );
          }

          final layout = _layout;
          if (layout == null) {
            return _buildStatePanel(
              icon: Icons.settings_applications,
              title: 'Configuration absente',
              message: 'Le backend n a pas encore renvoye de layout admin.',
              actionLabel: 'Recharger',
              onAction: () => setState(() {
                _bootstrapFuture = _bootstrapIfAllowed();
              }),
            );
          }

          return _buildDashboard(layout);
        },
      ),
    );
  }

  Widget _buildMasterLogin(AuthService auth) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 86,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF151119),
                        Color(0xFF321B4F),
                        AppTheme.orange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Cle de secours createur',
                  style: GoogleFonts.montserrat(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez la MASTER_CREATOR_KEY de 64 caracteres pour ouvrir le poste de controle prioritaire.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  'API appelee: ${ApiConfig.baseUrl}/api/admin/master-login',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _masterKeyController,
                  obscureText: true,
                  maxLength: 64,
                  decoration: const InputDecoration(
                    labelText: 'MASTER_CREATOR_KEY',
                    prefixIcon: Icon(Icons.key),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _runAction('Connexion createur', () async {
                            final ok = await _adminService.masterCreatorLogin(
                              _masterKeyController.text.trim(),
                            );
                            if (!ok) {
                              throw AdminUiException(
                                auth.lastAuthError ??
                                    'Cle refusee par le backend.',
                              );
                            }
                            await auth.refreshProfile();
                            await _reloadDashboard();
                            return {'session': 'SUPER_ADMIN'};
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: Text(
                    _busy ? 'Verification...' : 'Ouvrir le dashboard',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_lastAction.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _resultPanel(_lastAction),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(AdminDashboardLayout layout) {
    final allowedTabs = layout.tabs.where(layout.canAccess).toList();
    if (allowedTabs.isEmpty) {
      return _buildStatePanel(
        icon: Icons.lock_outline,
        title: 'Aucun onglet autorise',
        message: 'Le backend a refuse tous les modules pour ce role.',
      );
    }

    final index = _selectedTab.clamp(0, allowedTabs.length - 1);
    final currentTab = allowedTabs[index];

    return Column(
      children: [
        _buildHeader(layout, allowedTabs, index),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _reloadDashboard();
              if (mounted) setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                ...currentTab.components.map(_buildComponent),
                if (_lastAction.isNotEmpty) _resultPanel(_lastAction),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    AdminDashboardLayout layout,
    List<AdminDashboardTab> tabs,
    int selectedIndex,
  ) {
    final summary = _summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF151119), Color(0xFF321B4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            layout.title,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Role: ${layout.role} - ${layout.permissions.length} permissions actives',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (summary != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metric('Clients', summary.users.toString()),
                  _metric('Partenaires', summary.partners.toString()),
                  _metric('Prestations', summary.prestations.toString()),
                  _metric('Alertes', summary.openSecurityEvents.toString()),
                  _metric('Crashs', summary.openCrashes.toString()),
                  _metric('CA brut', _money(summary.grossRevenue)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: i == selectedIndex,
                      selectedColor: AppTheme.orange,
                      labelStyle: TextStyle(
                        color: i == selectedIndex ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                      avatar: Icon(
                        _iconFor(tabs[i].icon),
                        size: 18,
                        color: i == selectedIndex ? Colors.white : null,
                      ),
                      label: Text(tabs[i].label),
                      onSelected: (_) => setState(() => _selectedTab = i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponent(String key) {
    switch (key) {
      case 'rbac_matrix':
        return _rbacMatrixCard();
      case 'partner_onboarding':
        return _partnerOnboardingCard();
      case 'employee_board':
        return _employeeBoardCard();
      case 'kill_switch':
        return _killSwitchCard();
      case 'siem':
        return _listLoaderCard(
          title: 'Moniteur anti-piratage',
          subtitle: 'Requetes suspectes, brute force et bannissements.',
          icon: Icons.radar,
          items: _securityEvents,
          onLoad: () async {
            _securityEvents = await _adminService.fetchSecurityEvents();
          },
        );
      case 'encryption_health':
        return _encryptionHealthCard();
      case 'anonymization':
        return _anonymizationCard();
      case 'pentest':
        return _singleActionCard(
          title: 'Pentest interne',
          subtitle: 'Declenche un diagnostic OWASP non destructif.',
          icon: Icons.bug_report_outlined,
          actionLabel: 'Lancer le scan',
          onAction: () => _adminService.runPentest(),
        );
      case 'github_deploy':
        return _singleActionCard(
          title: 'Deployer la mise a jour',
          subtitle: 'Declenche GitHub Actions via le token serveur.',
          icon: Icons.rocket_launch,
          actionLabel: 'Deployer',
          onAction: () => _adminService.triggerGithubDeploy(),
        );
      case 'feature_flags':
        return _featureFlagsCard();
      case 'maintenance':
        return _maintenanceCard();
      case 'cashflow_chart':
        return _cashflowCard();
      case 'it_expenses':
        return _itExpensesCard();
      case 'reviews':
        return _reviewsCard();
      case 'pricing_rules':
        return _pricingRulesCard();
      case 'live_logs':
        return _listLoaderCard(
          title: 'Flux de logs applicatifs',
          subtitle: 'Derniers evenements inalterables du backend Rust.',
          icon: Icons.terminal,
          items: _auditLogs,
          onLoad: () async {
            _auditLogs = await _adminService.fetchAuditLogs();
          },
        );
      case 'crash_reports':
        return _listLoaderCard(
          title: 'Crashs et erreurs',
          subtitle: 'Rapports Flutter et backend centralises.',
          icon: Icons.error_outline,
          items: _crashes,
          onLoad: () async {
            _crashes = await _adminService.fetchCrashReports();
          },
        );
      case 'shadow_dev':
        return _shadowDevCard();
      case 'impersonation':
        return _impersonationCard();
      case 'predictive_capacity_alerts':
        return _listLoaderCard(
          title: 'Alertes logistiques predictives',
          subtitle: 'Detection de risque de penurie de cars ou chambres.',
          icon: Icons.directions_bus_filled_outlined,
          items: _capacityAlerts,
          onLoad: () async {
            _capacityAlerts = await _adminService.fetchCapacityAlerts();
          },
        );
      default:
        return _adminCard(
          title: key,
          subtitle: 'Composant declare par le backend, rendu generique.',
          icon: Icons.widgets_outlined,
          children: const [Text('Aucune action configuree pour ce module.')],
        );
    }
  }

  Widget _rbacMatrixCard() {
    final permissions = _layout?.permissions.toList() ?? const <String>[];
    return _adminCard(
      title: 'Moteur RBAC dynamique',
      subtitle: 'Associe un role et des permissions granulaires a un compte.',
      icon: Icons.admin_panel_settings,
      children: [
        _textField(_rbacUserController, 'UUID utilisateur'),
        _textField(_rbacRoleController, 'Role dynamique'),
        _textField(
          _rbacPermissionsController,
          'Permissions separees par des virgules',
          maxLines: 2,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: permissions
              .take(18)
              .map((permission) => InputChip(
                    label: Text(permission),
                    onPressed: () {
                      final current = _rbacPermissionsController.text.trim();
                      final next =
                          current.isEmpty ? permission : '$current,$permission';
                      _rbacPermissionsController.text = next;
                    },
                  ))
              .toList(),
        ),
        _actionButton(
          'Enregistrer le role',
          () => _runAction('RBAC mis a jour', () {
            return _adminService.updateUserPermissions(
              userId: _rbacUserController.text.trim(),
              roleKey: _rbacRoleController.text.trim(),
              permissions: _rbacPermissionsController.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(growable: false),
            );
          }),
        ),
      ],
    );
  }

  Widget _partnerOnboardingCard() {
    return _adminCard(
      title: 'Onboarding partenaire',
      subtitle: 'Approuve ou rejette une fiche partenaire existante.',
      icon: Icons.handshake_outlined,
      children: [
        _textField(_partnerIdController, 'UUID partenaire'),
        _textField(_partnerReasonController, 'Motif optionnel'),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                'Approuver',
                () => _runAction('Partenaire approuve', () {
                  return _adminService.reviewPartnerOnboarding(
                    partnerId: _partnerIdController.text.trim(),
                    approved: true,
                    reason: _partnerReasonController.text.trim(),
                  );
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _runAction('Partenaire rejete', () {
                          return _adminService.reviewPartnerOnboarding(
                            partnerId: _partnerIdController.text.trim(),
                            approved: false,
                            reason: _partnerReasonController.text.trim(),
                          );
                        }),
                icon: const Icon(Icons.block),
                label: const Text('Rejeter'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _employeeBoardCard() {
    return _adminCard(
      title: 'Equipe interne E-PROJECT',
      subtitle: 'Vue operationnelle alimentee par les roles et les logs.',
      icon: Icons.groups_2_outlined,
      children: [
        Text(
          'Les collaborateurs sont controles par le moteur RBAC et leurs actions sont journalisees dans les logs immuables.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        _actionButton(
          'Voir les actions recentes',
          () => _runAction('Logs collaborateurs charges', () async {
            _auditLogs = await _adminService.fetchAuditLogs();
            return {'items': _auditLogs.length};
          }),
        ),
      ],
    );
  }

  Widget _killSwitchCard() {
    return _adminCard(
      title: 'Kill-switch et bannissement',
      subtitle:
          'Restreint le compte, revoque les tokens et cache le catalogue.',
      icon: Icons.gpp_bad_outlined,
      danger: true,
      children: [
        _textField(_killUserController, 'UUID utilisateur a exclure'),
        _textField(
          _killPartnerController,
          'UUID partenaire associe optionnel',
        ),
        _textField(_killReasonController, 'Motif', maxLines: 2),
        _dangerButton(
          'Declencher le kill-switch',
          () => _runAction('Kill-switch applique', () {
            return _adminService.killSwitchUser(
              userId: _killUserController.text.trim(),
              partnerId: _emptyToNull(_killPartnerController.text),
              reason: _killReasonController.text.trim(),
            );
          }),
        ),
      ],
    );
  }

  Widget _encryptionHealthCard() {
    return _singleActionCard(
      title: 'Chiffrement documentaire',
      subtitle: 'Controle DOCUMENT_ENCRYPTION_KEY et les documents sensibles.',
      icon: Icons.enhanced_encryption_outlined,
      actionLabel: 'Verifier la sante',
      onAction: () => _adminService.fetchEncryptionHealth(),
    );
  }

  Widget _anonymizationCard() {
    return _adminCard(
      title: 'Droit a l oubli',
      subtitle: 'Anonymise le client sans casser les rapports financiers.',
      icon: Icons.privacy_tip_outlined,
      danger: true,
      children: [
        _textField(_privacyUserController, 'UUID utilisateur'),
        _dangerButton(
          'Anonymiser ce compte',
          () => _runAction('Utilisateur anonymise', () {
            return _adminService.anonymizeUser(
              _privacyUserController.text.trim(),
            );
          }),
        ),
      ],
    );
  }

  Widget _featureFlagsCard() {
    return _adminCard(
      title: 'Feature flags no-code',
      subtitle: 'Active ou coupe des modules sans redeployer.',
      icon: Icons.tune,
      children: [
        _actionButton(
          'Charger les flags',
          () => _runAction('Feature flags charges', () async {
            _featureFlags = await _adminService.fetchFeatureFlags();
            return {'items': _featureFlags.length};
          }),
        ),
        for (final flag in _featureFlags)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: flag.enabled,
            activeThumbColor: AppTheme.orange,
            title: Text(flag.label.isEmpty ? flag.flagKey : flag.label),
            subtitle: Text('${flag.rolloutPercentage}% - ${flag.description}'),
            onChanged: _busy
                ? null
                : (enabled) => _runAction('Flag ${flag.flagKey}', () async {
                      final updated = await _adminService.updateFeatureFlag(
                        flagKey: flag.flagKey,
                        enabled: enabled,
                        rolloutPercentage: flag.rolloutPercentage,
                        audience: flag.audience,
                      );
                      _featureFlags = _featureFlags
                          .map((item) =>
                              item.flagKey == updated.flagKey ? updated : item)
                          .toList(growable: false);
                      return updated.label;
                    }),
          ),
      ],
    );
  }

  Widget _maintenanceCard() {
    return _adminCard(
      title: 'Mode maintenance ciblee',
      subtitle: 'Maintenance globale, ville ou service avec message dedie.',
      icon: Icons.construction_outlined,
      children: [
        _textField(_maintenanceScopeController, 'Scope: global, city, service'),
        _textField(_maintenanceValueController, 'Valeur optionnelle'),
        _textField(_maintenanceMessageController, 'Message client',
            maxLines: 2),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                'Activer',
                () => _saveMaintenance(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _saveMaintenance(false),
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Desactiver'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _actionButton(
          'Charger les modes',
          () => _runAction('Modes maintenance charges', () async {
            _maintenanceModes = await _adminService.fetchMaintenanceModes();
            return {'items': _maintenanceModes.length};
          }),
        ),
        for (final mode in _maintenanceModes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              mode.enabled ? Icons.pause_circle : Icons.check_circle_outline,
              color: mode.enabled ? AppTheme.orange : Colors.green,
            ),
            title: Text('${mode.scopeType} ${mode.scopeValue ?? ''}'.trim()),
            subtitle: Text(mode.message),
          ),
      ],
    );
  }

  Widget _cashflowCard() {
    final finance = _finance;
    return _adminCard(
      title: 'Tresorerie Drift',
      subtitle: 'Revenus, commission E-PROJECT, reversements et couts IT.',
      icon: Icons.pie_chart_outline,
      children: [
        _actionButton(
          'Calculer les flux',
          () => _runAction('Flux financiers calcules', () async {
            _finance = await _adminService.fetchFinanceOverview();
            return {
              'grossRevenue': _finance?.grossRevenue,
              'netEstimated': _finance?.netEstimated,
            };
          }),
        ),
        if (finance != null) ...[
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 4,
                sections: [
                  _pieSection(
                      'E-PROJECT', finance.eprojectCommission, AppTheme.orange),
                  _pieSection('Partenaires', finance.partnerPayouts,
                      const Color(0xFF321B4F)),
                  _pieSection(
                      'Couts IT', finance.itExpenses, const Color(0xFF151119)),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill('CA brut', _money(finance.grossRevenue)),
              _pill('Commission', _money(finance.eprojectCommission)),
              _pill('Reversements', _money(finance.partnerPayouts)),
              _pill('Couts IT', _money(finance.itExpenses)),
              _pill('Net estime', _money(finance.netEstimated)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _itExpensesCard() {
    return _adminCard(
      title: 'Journal des depenses IT',
      subtitle: 'Serveurs, API, Firebase, stockage et outils internes.',
      icon: Icons.receipt_long_outlined,
      children: [
        _textField(_expenseProviderController, 'Fournisseur'),
        _textField(_expenseCategoryController, 'Categorie'),
        _textField(
          _expenseAmountController,
          'Montant FCFA',
          keyboardType: TextInputType.number,
        ),
        _actionButton(
          'Ajouter la depense',
          () => _runAction('Depense IT ajoutee', () {
            return _adminService.createItExpense(
              provider: _expenseProviderController.text.trim(),
              category: _expenseCategoryController.text.trim(),
              amount:
                  double.tryParse(_expenseAmountController.text.trim()) ?? 0,
            );
          }),
        ),
        _actionButton(
          'Charger le journal',
          () => _runAction('Depenses IT chargees', () async {
            _itExpenses = await _adminService.fetchItExpenses();
            return {'items': _itExpenses.length};
          }),
        ),
        _compactList(_itExpenses),
      ],
    );
  }

  Widget _reviewsCard() {
    return _adminCard(
      title: 'Moderation des avis',
      subtitle: 'Centralise les avis clients frauduleux ou injurieux.',
      icon: Icons.rate_review_outlined,
      children: [
        _actionButton(
          'Charger les avis',
          () => _runAction('Avis charges', () async {
            _reviews = await _adminService.fetchReviews();
            return {'items': _reviews.length};
          }),
        ),
        _textField(_reviewIdController, 'UUID avis a masquer'),
        _dangerButton(
          'Masquer cet avis',
          () => _runAction('Avis modere', () {
            return _adminService.moderateReview(
              reviewId: _reviewIdController.text.trim(),
              status: 'hidden',
              reason: 'Moderation depuis le dashboard admin',
            );
          }),
        ),
        _compactList(_reviews),
      ],
    );
  }

  Widget _pricingRulesCard() {
    return _adminCard(
      title: 'Regles tarifaires',
      subtitle: 'Coefficients par ville, service ou periode.',
      icon: Icons.price_change_outlined,
      children: [
        _textField(_pricingNameController, 'Nom de la regle'),
        _textField(_pricingServiceController, 'Service'),
        _textField(_pricingCityController, 'Ville'),
        _textField(
          _pricingCoefficientController,
          'Coefficient',
          keyboardType: TextInputType.number,
        ),
        _actionButton(
          'Creer la regle',
          () => _runAction('Regle tarifaire creee', () {
            return _adminService.createPricingRule(
              name: _pricingNameController.text.trim(),
              serviceType: _pricingServiceController.text.trim(),
              city: _pricingCityController.text.trim(),
              coefficient:
                  double.tryParse(_pricingCoefficientController.text.trim()) ??
                      1,
            );
          }),
        ),
        _actionButton(
          'Charger les regles',
          () => _runAction('Regles tarifaires chargees', () async {
            _pricingRules = await _adminService.fetchPricingRules();
            return {'items': _pricingRules.length};
          }),
        ),
        _compactList(_pricingRules),
      ],
    );
  }

  Widget _shadowDevCard() {
    return _adminCard(
      title: 'Shadow Dev',
      subtitle: 'Genere une suggestion de correctif a partir d un crash.',
      icon: Icons.auto_fix_high,
      children: [
        _textField(_crashIdController, 'UUID crash'),
        _actionButton(
          'Analyser avec Shadow Dev',
          () => _runAction('Suggestion Shadow Dev', () {
            return _adminService.generateShadowDevSuggestion(
              _crashIdController.text.trim(),
            );
          }),
        ),
      ],
    );
  }

  Widget _impersonationCard() {
    return _adminCard(
      title: 'Profil fantome support',
      subtitle: 'Genere un token temporaire de 15 minutes.',
      icon: Icons.theater_comedy_outlined,
      danger: true,
      children: [
        _textField(_impersonateUserController, 'UUID client cible'),
        _textField(_impersonateReasonController, 'Motif support', maxLines: 2),
        _dangerButton(
          'Generer le token fantome',
          () => _runAction('Impersonation demarree', () {
            return _adminService.impersonateUser(
              userId: _impersonateUserController.text.trim(),
              reason: _impersonateReasonController.text.trim(),
            );
          }),
        ),
      ],
    );
  }

  Widget _listLoaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required Future<void> Function() onLoad,
  }) {
    return _adminCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      children: [
        _actionButton(
          'Actualiser',
          () => _runAction(title, () async {
            await onLoad();
            return {'items': items.length};
          }),
        ),
        _compactList(items),
      ],
    );
  }

  Widget _singleActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required Future<dynamic> Function() onAction,
  }) {
    return _adminCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      children: [
        _actionButton(
          actionLabel,
          () => _runAction(title, onAction),
        ),
      ],
    );
  }

  Widget _adminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool danger = false,
  }) {
    final theme = Theme.of(context);
    final accent = danger ? Colors.red : AppTheme.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.bolt),
        label: Text(
          label,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _dangerButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(Icons.warning_amber_rounded),
        label: Text(
          label,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _compactList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Aucune donnee chargee.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: items.take(6).map((item) {
        final title = (item['event_type'] ??
                item['title'] ??
                item['label'] ??
                item['name'] ??
                item['category'] ??
                item['message'] ??
                item['id'] ??
                'Element')
            .toString();
        final subtitle = _compactJson(item);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _resultPanel(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: .25)),
      ),
      child: SelectableText(
        message,
        style: const TextStyle(fontSize: 12, height: 1.35),
      ),
    );
  }

  Widget _buildStatePanel({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppTheme.orange),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              _actionButton(actionLabel, onAction),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value'),
    );
  }

  PieChartSectionData _pieSection(String title, double value, Color color) {
    final normalizedValue = value <= 0 ? 1.0 : value;
    return PieChartSectionData(
      color: color,
      value: normalizedValue,
      title: value <= 0 ? '0' : title,
      radius: 66,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Future<void> _saveMaintenance(bool enabled) {
    return _runAction(
      enabled ? 'Maintenance activee' : 'Maintenance desactivee',
      () {
        return _adminService.upsertMaintenanceMode(
          scopeType: _maintenanceScopeController.text.trim(),
          scopeValue: _emptyToNull(_maintenanceValueController.text),
          enabled: enabled,
          message: _maintenanceMessageController.text.trim(),
        );
      },
    );
  }

  Future<void> _runAction(
    String label,
    Future<dynamic> Function() action,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _lastAction = '';
    });

    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _lastAction = '$label\n${_compactJson(result)}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastAction = 'Erreur: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _compactJson(dynamic value) {
    if (value == null) return 'OK';
    const encoder = JsonEncoder.withIndent('  ');
    final raw = value is String ? value : encoder.convert(value);
    return raw.length > 900 ? '${raw.substring(0, 900)}...' : raw;
  }

  String _money(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final fromEnd = rounded.length - i;
      buffer.write(rounded[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(' ');
    }
    return '${buffer.toString()} FCFA';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'security':
        return Icons.security;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'show_chart':
        return Icons.show_chart;
      case 'terminal':
        return Icons.terminal;
      case 'directions_bus':
        return Icons.directions_bus;
      default:
        return Icons.dashboard_customize_outlined;
    }
  }
}

class AdminUiException implements Exception {
  final String message;

  const AdminUiException(this.message);

  @override
  String toString() => message;
}
