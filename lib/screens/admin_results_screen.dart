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
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _estudiantes = [];
  Map<String, Map<int, double>> _notasPorEstudiante = {};

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

      // 3. Procesar las notas de cada estudiante
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
              : SingleChildScrollView(
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
                      ],
                      rows: _estudiantes.map((est) {
                        final String estId = est['id'];
                        final n = _notasPorEstudiante[estId]!;
                        final prom = _calcularPromedio(estId);
                        
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
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}
