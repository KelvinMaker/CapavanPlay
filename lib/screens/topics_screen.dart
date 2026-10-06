import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isAdmin = false;
  List<dynamic> _temas = [];
  String? _miId;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoadTopics();
  }

  Future<void> _checkRoleAndLoadTopics() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _miId = user.id;
      try {
        final profile = await _supabase
            .from('perfiles')
            .select('rol')
            .eq('id', user.id)
            .single();
            
        _isAdmin = profile['rol'] == 'docente';
      } catch (e) {
        debugPrint('Error obteniendo rol: $e');
      }
    }
    await _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    try {
      // Cargamos temas y hacemos un "join" manual o mediante Foreign Key con perfiles para ver quién reservó
      final response = await _supabase
          .from('temas')
          .select('*, perfiles(nombres, apellidos)')
          .order('id', ascending: true);

      setState(() {
        _temas = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando temas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar temas: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _descargarCSV() async {
    if (_temas.isEmpty) return;

    // Generar contenido CSV
    final buffer = StringBuffer();
    // Añadimos BOM para que Excel detecte UTF-8 correctamente
    buffer.write('\uFEFF');
    buffer.writeln('Identificación,Nombres,Apellidos,Tema Seleccionado');

    for (var tema in _temas) {
      if (tema['estudiante_id'] != null && tema['perfiles'] != null) {
        final p = tema['perfiles'];
        final id = p['identificacion'] ?? '';
        final nombres = p['nombres'] ?? '';
        final apellidos = p['apellidos'] ?? '';
        final titulo = tema['titulo'] ?? '';

        buffer.writeln('"$id","$nombres","$apellidos","$titulo"');
      }
    }

    try {
      final csvString = buffer.toString();
      final fileName = 'Reporte_Temas_Capavanplay.csv';

      if (kIsWeb) {
        // En Web: forzamos la descarga nativa del navegador
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // En Windows/Escritorio: Guardamos directo en Descargas usando dart puro sin plugins
        final userProfile = io.Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloadPath = '$userProfile\\Downloads\\$fileName';
          final file = io.File(downloadPath);
          await file.writeAsString(csvString, encoding: utf8);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Reporte guardado en: Descargas\\$fileName'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      if (mounted && kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte CSV descargado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando CSV: $e');
    }
  }

  Future<void> _reservarTema(int temaId) async {
    if (_miId == null) return;
    
    // Validar si el usuario ya tiene un tema reservado
    final yaTieneTema = _temas.any((t) => t['estudiante_id'] == _miId);
    if (yaTieneTema) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ya tienes un tema reservado. Solo puedes tener uno.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _supabase
          .from('temas')
          .update({'estudiante_id': _miId})
          .eq('id', temaId);
          
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Tema reservado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTopics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reservar: $e')),
      );
    }
  }

  Future<void> _liberarTema(int temaId) async {
    try {
      await _supabase
          .from('temas')
          .update({'estudiante_id': null})
          .eq('id', temaId);
      _loadTopics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al liberar: $e')),
      );
    }
  }

  Future<void> _eliminarTema(int temaId) async {
    try {
      await _supabase
          .from('temas')
          .delete()
          .eq('id', temaId);
      _loadTopics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Future<void> _crearNuevoTema(String titulo) async {
    try {
      await _supabase
          .from('temas')
          .insert({'titulo': titulo});
      _loadTopics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear: $e')),
      );
    }
  }

  void _mostrarDialogoNuevoTema() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Nuevo Tema'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ej. GESTIÓN DEL TIEMPO'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _crearNuevoTema(controller.text.trim().toUpperCase());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Temas'),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Descargar Reporte CSV',
              onPressed: _descargarCSV,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar Tema',
              onPressed: _mostrarDialogoNuevoTema,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTopics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _temas.isEmpty
              ? const Center(child: Text('No hay temas disponibles aún.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _temas.length,
                  itemBuilder: (context, index) {
                    final tema = _temas[index];
                    final isReservado = tema['estudiante_id'] != null;
                    final reservadoPor = isReservado && tema['perfiles'] != null
                        ? '${tema['perfiles']['nombres']} ${tema['perfiles']['apellidos']}'
                        : null;
                    
                    final isMio = tema['estudiante_id'] == _miId;

                    return Card(
                      elevation: isReservado ? 2 : 6,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isReservado 
                          ? Theme.of(context).colorScheme.surface.withOpacity(0.5) 
                          : Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isMio 
                              ? Colors.green 
                              : isReservado 
                                  ? Colors.transparent 
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          tema['titulo'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isReservado ? Colors.grey : Colors.white,
                          ),
                        ),
                        subtitle: isReservado
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock, size: 16, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isMio ? 'Reservado por ti' : 'Reservado por: $reservadoPor',
                                        style: TextStyle(
                                          color: isMio ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Libre para reservar', style: TextStyle(color: Colors.greenAccent)),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isReservado && !_isAdmin)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _reservarTema(tema['id']),
                                child: const Text('Reservar'),
                              ),
                            if (isReservado && (_isAdmin || isMio))
                              IconButton(
                                icon: const Icon(Icons.lock_open, color: Colors.green),
                                tooltip: 'Liberar Tema',
                                onPressed: () => _liberarTema(tema['id']),
                              ),
                            if (_isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Eliminar Tema',
                                onPressed: () => _eliminarTema(tema['id']),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
