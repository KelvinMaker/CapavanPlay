import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'topics_screen.dart';
import 'auth_screen.dart';
import 'hub_screen.dart';
import 'admin_results_screen.dart';
import 'admin_survey_screen.dart';
import 'hub_screen.dart';
import 'admin_results_screen.dart';
import 'admin_survey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('perfiles')
            .select()
            .eq('id', user.id)
            .single();
        setState(() {
          _userProfile = data;
        });
      } catch (e) {
        debugPrint('Error cargando perfil: $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_userProfile != null) ...[
                  Text(
                    'Hola, ${_userProfile!['nombres']}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Qué te gustaría hacer hoy?',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón 1: ELEGIR TEMA
                  Expanded(
                    child: _MenuCard(
                      title: _userProfile!['rol'] == 'docente' ? 'GESTIÓN DE TEMAS' : 'ELEGIR TEMA',
                      subtitle: _userProfile!['rol'] == 'docente' ? 'Administra y descarga los temas' : 'Reserva tu proyecto académico',
                      icon: Icons.library_books,
                      color: Theme.of(context).colorScheme.primary, // Azul
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TopicsScreen()),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón 2: JUGAR o RESULTADOS
                  Expanded(
                    child: _MenuCard(
                      title: _userProfile!['rol'] == 'docente' ? 'RESULTADOS' : 'JUGAR',
                      subtitle: _userProfile!['rol'] == 'docente' 
                        ? 'Panel de calificaciones y reportes' 
                        : 'Ingresa a la Zona de Juegos',
                      icon: _userProfile!['rol'] == 'docente' ? Icons.admin_panel_settings : Icons.sports_esports,
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () {
                        if (_userProfile!['rol'] == 'docente') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminResultsScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HubScreen()),
                          );
                        }
                      },
                    ),
                  ),

                    if (_userProfile!['rol'] == 'docente') ...[
                      const SizedBox(height: 24),
                      Expanded(
                        child: _MenuCard(
                          title: 'ESTADÍSTICAS UX',
                          subtitle: 'Resultados de la encuesta TAM',
                          icon: Icons.pie_chart,
                          color: Colors.purple.shade600,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminSurveyScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                ] else ...[
                  const Center(child: Text('No se pudo cargar el perfil.')),
                ]
              ],
            ),
          ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.4),
              ],
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Icon(icon, size: 50, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Icon(Icons.arrow_forward_ios, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
