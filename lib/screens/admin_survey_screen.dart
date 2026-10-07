import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert' as dart_convert;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminSurveyScreen extends StatefulWidget {
  const AdminSurveyScreen({super.key});

  @override
  State<AdminSurveyScreen> createState() => _AdminSurveyScreenState();
}

class _AdminSurveyScreenState extends State<AdminSurveyScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _encuestas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final response = await _supabase.from('satisfaccion').select();
      setState(() {
        _encuestas = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando encuestas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _descargarCSV() async {
    if (_encuestas.isEmpty) return;

    try {
      // 1. Crear el encabezado del CSV
      String csvData = "ID_Estudiante,Transferencia,Utilidad,Motivacion,Usabilidad,Impacto,Fecha\n";

      // 2. Llenar los datos
      for (var row in _encuestas) {
        final estId = row['estudiante_id'] ?? '';
        final q1 = row['q1_transferencia'] ?? '';
        final q2 = row['q2_utilidad'] ?? '';
        final q3 = row['q3_motivacion'] ?? '';
        final q4 = row['q4_usabilidad'] ?? '';
        final q5 = row['q5_impacto'] ?? '';
        final fecha = row['fecha'] ?? '';
        
        csvData += "$estId,$q1,$q2,$q3,$q4,$q5,$fecha\n";
      }

      if (kIsWeb) {
        // Descarga en Navegador Web
        final bytes = dart_convert.utf8.encode(csvData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'resultados_tam_ux.csv';
        html.document.body?.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        // Descarga en Escritorio/Móvil (Fallback)
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/resultados_tam_ux.csv');
        await file.writeAsString(csvData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archivo guardado en: ${file.path}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error exportando CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al exportar los datos')),
        );
      }
    }
  }

  double _calcularPromedio(String key) {
    if (_encuestas.isEmpty) return 0.0;
    double suma = 0;
    for (var e in _encuestas) {
      suma += (e[key] as num).toDouble();
    }
    return suma / _encuestas.length;
  }

  Widget _buildStatCard(String titulo, String variableKey, IconData icono, Color color) {
    final promedio = _calcularPromedio(variableKey);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: promedio / 5.0,
                  backgroundColor: Colors.white12,
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text(
            promedio.toStringAsFixed(1),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const Text(' /5', style: TextStyle(fontSize: 14, color: Colors.white54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas UX (TAM)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar Excel (CSV)',
            onPressed: _encuestas.isEmpty ? null : _descargarCSV,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Muestra total: ${_encuestas.length} estudiantes evaluados',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStatCard('1. Transferencia (Perceived Learning)', 'q1_transferencia', Icons.school, Colors.green),
            _buildStatCard('2. Utilidad (Perceived Usefulness)', 'q2_utilidad', Icons.work, Colors.blue),
            _buildStatCard('3. Motivación (Engagement)', 'q3_motivacion', Icons.local_fire_department, Colors.orange),
            _buildStatCard('4. Usabilidad UX (Ease of Use)', 'q4_usabilidad', Icons.touch_app, Colors.purple),
            _buildStatCard('5. Impacto Tecnológico (Intention)', 'q5_impacto', Icons.rocket_launch, Colors.teal),
          ],
        ),
      ),
    );
  }
}
