import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/ride_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  List<dynamic> _rides = [];
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final data = await AuthService().getProfile();
    if (!mounted) return;

    if (data == null) {
      // Pas connecté -> Redirection
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    _loadRides(data);
  }

  void _loadRides(Map<String, dynamic> userData) async {
    final rides = await RideService().getMyRides();
    if (mounted) {
      setState(() {
        _userData = userData;
        _rides = rides;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AuthService().logout();
              if (mounted) {
                navigator.pushReplacementNamed('/login');
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child:
                  CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            ),
            const SizedBox(height: 30),
            Text("Email: ${_userData?['email'] ?? 'Non renseigné'}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Status: Utilisateur vérifié",
                style: TextStyle(color: Colors.green)),
            const Divider(height: 40),
            const Text("Historique de mes trajets",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _rides.isEmpty
                  ? const Center(child: Text("Aucun trajet enregistré"))
                  : ListView.builder(
                      itemCount: _rides.length,
                      itemBuilder: (context, index) {
                        final ride = _rides[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.directions_car),
                            title: Text(ride['title'] ?? 'Trajet sans titre'),
                            subtitle: Text(ride['description'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
