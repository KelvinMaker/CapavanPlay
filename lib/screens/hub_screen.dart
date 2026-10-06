import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'actividad1_screen.dart';
import 'actividad2_screen.dart';
import 'actividad3_screen.dart';
import 'actividad4_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _intentos = [];

  @override
  void initState() {
    super.initState();
    _cargarIntentos();
  }

  Future<void> _cargarIntentos() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('intentos_actividades')
          .select()
          .eq('estudiante_id', userId);

      setState(() {
        _intentos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando intentos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calcularNotaActividad(int actividadId) {
    final intentosActividad = _intentos
        .where((i) => i['actividad_id'] == actividadId)
        .map((i) => double.parse(i['puntaje'].toString()))
        .toList();

    if (intentosActividad.isEmpty) return 0.0;
    
    if (intentosActividad.length == 1) {
      return intentosActividad.first;
    } 
    
    if (intentosActividad.length == 2) {
      return (intentosActividad[0] + intentosActividad[1]) / 2;
    }

    intentosActividad.sort((a, b) => b.compareTo(a));
    return (intentosActividad[0] + intentosActividad[1]) / 2;
  }

  double _calcularNotaTotal() {
    double suma = 0;
    for (int i = 1; i <= 4; i++) {
      suma += _calcularNotaActividad(i);
    }
    return suma / 4;
  }

  Widget _buildJuegoCard(
      String titulo, IconData icono, int actividadId, Color bgColor) {
    final nota = _calcularNotaActividad(actividadId);
    
    return Card(
      elevation: 6,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (actividadId == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Actividad1Screen()),
            ).then((_) {
              _cargarIntentos();
            });
          } else if (actividadId == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Actividad2Screen()),
            ).then((_) {
              _cargarIntentos();
            });
          } else if (actividadId == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Actividad3Screen()),
            ).then((_) {
              _cargarIntentos();
            });
          } else if (actividadId == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Actividad4Screen()),
            ).then((_) {
              _cargarIntentos();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Iniciando $titulo...')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                    child: Icon(icono, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nota: ${nota.toStringAsFixed(1)} / 10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Builder(
                  builder: (context) {
                    final cantidad = _intentos.where((i) => i['actividad_id'] == actividadId).length;
                    return Text(
                      cantidad > 3 ? '$cantidad/$cantidad Intentos (Extra)' : '$cantidad/3 Intentos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final notaAcumulada = _calcularNotaTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zona de Juegos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // TARJETA DE NOTA ACUMULADA (FIJA ARRIBA)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'NOTA ACUMULADA TOTAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notaAcumulada.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '/ 10.0',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // GRID DE JUEGOS RESPONSIVO
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Si la pantalla es muy ancha (PC/Tablet), mostramos 4 columnas.
                // Si es celular, respetamos el 2x2.
                int columnas = constraints.maxWidth > 600 ? 4 : 2;
                
                return GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  crossAxisCount: columnas,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85, // Mas rectangulares
                  children: [
                    _buildJuegoCard(
                      'Calculadora de Cuantías',
                      Icons.calculate,
                      1,
                      const Color(0xFF1E3A8A), // Azul muy oscuro (Navy)
                    ),
                    _buildJuegoCard(
                      'Secuenciador del Proceso',
                      Icons.format_list_numbered,
                      2,
                      const Color(0xFF0F766E), // Teal/Verde esmeralda oscuro
                    ),
                    _buildJuegoCard(
                      'Matriz Rol del Estado',
                      Icons.account_balance,
                      3,
                      const Color(0xFFB45309), // Naranja quemado oscuro
                    ),
                    _buildJuegoCard(
                      'Trivia Gerencial BI',
                      Icons.psychology,
                      4,
                      const Color(0xFF6D28D9), // Morado oscuro
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
