import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isAuthenticated) {
        auth.getProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: auth.isAuthenticated ? _buildProfileContent(context) : _buildLoginPrompt(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context),
          _buildStats(),
          const SizedBox(height: 20),
          _buildSection('Informations personnelles', [
            _InfoRow(
              Icons.person_outline,
              'Nom complet',
              context.watch<AuthService>().userName.isNotEmpty
                  ? context.watch<AuthService>().userName
                  : 'Utilisateur'),
            _InfoRow(
              Icons.email_outlined,
              'Email',
              context.watch<AuthService>().userEmail.isNotEmpty
                  ? context.watch<AuthService>().userEmail
                  : 'Non renseigné'),
            const _InfoRow(Icons.phone_outlined, 'Téléphone', 'Non renseigné'),
            const _InfoRow(Icons.location_on_outlined, 'Ville', 'Non renseigné'),
          ]),
          const SizedBox(height: 16),
          _buildSection('Préférences', [
            const _InfoRow(Icons.language, 'Langue', 'Français'),
            const _InfoRow(Icons.attach_money, 'Devise', 'FCFA'),
          ]),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.blueViolet,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientBlue.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'MODIFIER MON PROFIL',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 32,
            bottom: 32,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            gradient: AppColors.blueViolet,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon Profil',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connectez-vous pour afficher vos informations personnelles, vos voyages et vos réservations.',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Color(0xFF1E90FF)),
                const SizedBox(height: 24),
                Text(
                  'Accès réservé',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vous devez vous connecter pour voir votre profil. Aucun profil fictif ne sera affiché sans authentification.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: AppColors.grayText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueViolet.colors.first,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'SE CONNECTER',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.blueViolet,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
              const Spacer(),
              Text(
                'Mon Profil',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 54),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.watch<AuthService>().userName.isNotEmpty
                ? context.watch<AuthService>().userName
                : 'Utilisateur',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'MEMBRE PREMIUM',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Paramètres',
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          _stat('12', 'Voyages'),
          _statDivider(),
          _stat('3', 'Chauffeurs'),
          _statDivider(),
          _stat('8', 'Hôtels'),
          _statDivider(),
          _stat('4.9', 'Note'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            label,
            style:
                GoogleFonts.montserrat(fontSize: 10, color: AppColors.grayText),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }

  Widget _buildSection(String title, List<_InfoRow> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: rows.asMap().entries.map((e) {
                final isLast = e.key == rows.length - 1;
                return Column(
                  children: [
                    e.value,
                    if (!isLast)
                      const Divider(
                          height: 1, indent: 54, color: Color(0xFFF0F0F0)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                    fontSize: 10, color: AppColors.lightText),
              ),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.lightText),
        ],
      ),
    );
  }
}
