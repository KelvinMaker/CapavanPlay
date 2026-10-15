import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _estudiantes = [];
  Map<String, Map<int, double>> _notasPorEstudiante = {};
  List<Map<String, dynamic>> _intentos = [];
  List<Map<String, dynamic>> _autorizaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarResultados();
  }

  Future<void> _cargarResultados() async {
    try {
      // 1. Obtener todos los perfiles que NO sean el docente
      final perfilesResponse = await _supabase
          .from('perfiles')
          .select()
          .neq('identificacion', 'Admin')
          .order('apellidos', ascending: true);

      final List<Map<String, dynamic>> estudiantes = List<Map<String, dynamic>>.from(perfilesResponse);

      // 2. Obtener todos los intentos
      final intentosResponse = await _supabase
          .from('intentos_actividades')
          .select();
          
      final List<Map<String, dynamic>> intentos = List<Map<String, dynamic>>.from(intentosResponse);

      // 3. Obtener autorizaciones de intentos extra
      List<Map<String, dynamic>> autorizaciones = [];
      try {
        final authResponse = await _supabase
            .from('intentos_extra')
            .select();
        autorizaciones = List<Map<String, dynamic>>.from(authResponse);
      } catch (e) {
        debugPrint('Error cargando intentos_extra: $e');
      }

      // 4. Procesar las notas de cada estudiante
      Map<String, Map<int, double>> notas = {};
      
      for (var est in estudiantes) {
        String estId = est['id'];
        notas[estId] = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0};
        
        for (int act = 1; act <= 4; act++) {
          final intentosAct = intentos.where((i) => i['estudiante_id'] == estId && i['actividad_id'] == act).toList();
          if (intentosAct.isEmpty) continue;
          
          final puntajes = intentosAct.map((i) => double.parse(i['puntaje'].toString())).toList();
          if (puntajes.length == 1) {
            notas[estId]![act] = puntajes.first;
          } else if (puntajes.length == 2) {
            notas[estId]![act] = (puntajes[0] + puntajes[1]) / 2;
          } else {
            puntajes.sort((a, b) => b.compareTo(a)); // Descendente
            notas[estId]![act] = (puntajes[0] + puntajes[1]) / 2;
          }
        }
      }

      setState(() {
        _estudiantes = estudiantes;
        _notasPorEstudiante = notas;
        _intentos = intentos;
        _autorizaciones = autorizaciones;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando resultados: $e');
      setState(() => _isLoading = false);
    }
  }

  double _calcularPromedio(String estId) {
    final n = _notasPorEstudiante[estId]!;
    return (n[1]! + n[2]! + n[3]! + n[4]!) / 4;
  }

  Future<void> _toggleCuartoIntento(String estId, int actId, bool habilitar) async {
    try {
      if (habilitar) {
        await _supabase.from('intentos_extra').upsert({
          'estudiante_id': estId,
          'actividad_id': actId,
          'intentos_maximos': 4,
        }, onConflict: 'estudiante_id, actividad_id');

        _autorizaciones.removeWhere((a) => a['estudiante_id'] == estId && a['actividad_id'] == actId);
        _autorizaciones.add({
          'estudiante_id': estId,
          'actividad_id': actId,
          'intentos_maximos': 4,
        });
      } else {
        await _supabase
            .from('intentos_extra')
            .delete()
            .eq('estudiante_id', estId)
            .eq('actividad_id', actId);

        _autorizaciones.removeWhere((a) => a['estudiante_id'] == estId && a['actividad_id'] == actId);
      }
    } catch (e) {
      debugPrint('Error actualizando autorización: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar autorización: $e')),
        );
      }
    }
  }

  void _mostrarGestionIntentos(Map<String, dynamic> est) {
    final String estId = est['id'];
    final String nombreCompleto = '${est['apellidos']} ${est['nombres']}';
    final String doc = est['identificacion'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars, color: Colors.amber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreCompleto,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'ID: $doc • Gestión de 4.º Intento',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: Colors.white24),
                  const Text(
                    'Cada juego permite 3 intentos base. Activa el interruptor para autorizar un 4.º intento a este cadete:',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  _buildActividadSwitch(
                    estId: estId,
                    actividadId: 1,
                    titulo: 'Actividad 1: Calculadora de Cuantías',
                    icono: Icons.calculate,
                    color: const Color(0xFF3B82F6),
                    setModalState: setModalState,
                  ),
                  _buildActividadSwitch(
                    estId: estId,
                    actividadId: 2,
                    titulo: 'Actividad 2: Secuenciador del Proceso',
                    icono: Icons.format_list_numbered,
                    color: const Color(0xFF10B981),
                    setModalState: setModalState,
                  ),
                  _buildActividadSwitch(
                    estId: estId,
                    actividadId: 3,
                    titulo: 'Actividad 3: Matriz Rol del Estado',
                    icono: Icons.account_balance,
                    color: const Color(0xFFF59E0B),
                    setModalState: setModalState,
                  ),
                  _buildActividadSwitch(
                    estId: estId,
                    actividadId: 4,
                    titulo: 'Actividad 4: Trivia Gerencial BI',
                    icono: Icons.psychology,
                    color: const Color(0xFF8B5CF6),
                    setModalState: setModalState,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActividadSwitch({
    required String estId,
    required int actividadId,
    required String titulo,
    required IconData icono,
    required Color color,
    required StateSetter setModalState,
  }) {
    final intentosUsados = _intentos
        .where((i) => i['estudiante_id'] == estId && i['actividad_id'] == actividadId)
        .length;

    final tieneCuarto = _autorizaciones.any(
      (a) => a['estudiante_id'] == estId &&
             a['actividad_id'] == actividadId &&
             (a['intentos_maximos'] ?? 3) > 3,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tieneCuarto ? color : Colors.white12,
          width: tieneCuarto ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Text(
                  'Intentos realizados: $intentosUsados / ${tieneCuarto ? 4 : 3}',
                  style: TextStyle(
                    fontSize: 12,
                    color: tieneCuarto ? Colors.amberAccent : Colors.white60,
                    fontWeight: tieneCuarto ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: tieneCuarto,
            activeColor: color,
            onChanged: (bool value) async {
              await _toggleCuartoIntento(estId, actividadId, value);
              setModalState(() {});
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _descargarCSV() async {
    try {
      // 1. Construir el contenido CSV
      List<String> rows = [];
      // Encabezados
      rows.add("Apellidos,Nombres,Identificacion,Actividad 1,Actividad 2,Actividad 3,Actividad 4,Promedio Total");

      // Datos
      for (var est in _estudiantes) {
        final String estId = est['id'];
        final n = _notasPorEstudiante[estId]!;
        final prom = _calcularPromedio(estId);
        
        final row = [
          est['apellidos'].toString().replaceAll(',', ' '),
          est['nombres'].toString().replaceAll(',', ' '),
          est['identificacion'].toString(),
          n[1]!.toStringAsFixed(1),
          n[2]!.toStringAsFixed(1),
          n[3]!.toStringAsFixed(1),
          n[4]!.toStringAsFixed(1),
          prom.toStringAsFixed(1)
        ];
        rows.add(row.join(','));
      }

      String csvContent = rows.join('\n');

      // 2. Descargar o guardar dependiendo de la plataforma
      if (kIsWeb) {
        // En Web
        final bytes = html.Blob([csvContent], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(bytes);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'Resultados_Estudiantes.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // En Windows/Mac o Móvil
        final file = File('Resultados_Estudiantes.csv');
        await file.writeAsString(csvContent);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Guardado como: ${file.absolute.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Estudiantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar Reporte CSV',
            onPressed: _descargarCSV,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarResultados,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estudiantes.isEmpty
              ? const Center(child: Text('Aún no hay estudiantes registrados.'))
              : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.blue.shade900),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('Apellidos')),
                        DataColumn(label: Text('Nombres')),
                        DataColumn(label: Text('Identificación')),
                        DataColumn(label: Text('Act 1')),
                        DataColumn(label: Text('Act 2')),
                        DataColumn(label: Text('Act 3')),
                        DataColumn(label: Text('Act 4')),
                        DataColumn(label: Text('Promedio')),
                        DataColumn(label: Text('4.º Intento')),
                      ],
                      rows: _estudiantes.map((est) {
                        final String estId = est['id'];
                        final n = _notasPorEstudiante[estId]!;
                        final prom = _calcularPromedio(estId);
                        final tieneExtra = _autorizaciones.any((a) => a['estudiante_id'] == estId && (a['intentos_maximos'] ?? 3) > 3);
                        
                        return DataRow(
                          cells: [
                            DataCell(Text(est['apellidos'])),
                            DataCell(Text(est['nombres'])),
                            DataCell(Text(est['identificacion'])),
                            DataCell(Text(n[1]!.toStringAsFixed(1))),
                            DataCell(Text(n[2]!.toStringAsFixed(1))),
                            DataCell(Text(n[3]!.toStringAsFixed(1))),
                            DataCell(Text(n[4]!.toStringAsFixed(1))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: prom >= 6.0 ? Colors.green.shade800 : Colors.red.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  prom.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tieneExtra ? Colors.amber.shade800 : Colors.blueGrey.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(tieneExtra ? Icons.star : Icons.tune, size: 16, color: tieneExtra ? Colors.amberAccent : Colors.white),
                                label: Text(
                                  tieneExtra ? 'Extra Activo' : 'Gestionar',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _mostrarGestionIntentos(est),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
    );
  }
}
