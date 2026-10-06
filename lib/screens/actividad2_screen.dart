import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Actividad2Screen extends StatefulWidget {
  const Actividad2Screen({super.key});

  @override
  State<Actividad2Screen> createState() => _Actividad2ScreenState();
}

class _Actividad2ScreenState extends State<Actividad2Screen> {
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;

  // Lista oficial en orden correcto
  final List<String> _ordenCorrecto = [
    'Elaboración del Plan de Compras',
    'Gestión del Presupuesto',
    'Elaboración del Estudio Previo',
    'Expedición del CDP (Certificado de Disponibilidad Presupuestal)',
    'Apertura e Invitación Pública',
    'Presentación, Evaluación de Ofertas y Publicación',
    'Adjudicación del Contrato',
    'Aprobación de Pólizas y Expedición del CRP (Registro Presupuestal)',
    'Ejecución del Contrato e Informe de Supervisión / Actas de Recepción',
    'Pago de Facturas, Liquidación y Fin del Proceso'
  ];

  // Lista que manipulará el estudiante
  late List<String> _itemsActuales;

  @override
  void initState() {
    super.initState();
    // Iniciar con la lista desordenada
    _itemsActuales = List.from(_ordenCorrecto);
    _itemsActuales.shuffle();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _itemsActuales.removeAt(oldIndex);
      _itemsActuales.insert(newIndex, item);
    });
  }

  Future<void> _validarSecuencia() async {
    setState(() => _isSaving = true);
    
    // Calcular el puntaje (1 punto por cada posición correcta)
    double puntaje = 0;
    for (int i = 0; i < _ordenCorrecto.length; i++) {
      if (_itemsActuales[i] == _ordenCorrecto[i]) {
        puntaje += 1.0;
      }
    }

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Consultar intento actual
      final response = await _supabase
          .from('intentos_actividades')
          .select('numero_intento')
          .eq('estudiante_id', userId)
          .eq('actividad_id', 2)
          .order('numero_intento', ascending: false)
          .limit(1);

      int numeroIntento = 1;
      if (response.isNotEmpty) {
        numeroIntento = (response.first['numero_intento'] as int) + 1;
      }

      if (numeroIntento > 3) {
        throw Exception("Has superado el límite de 3 intentos base.");
      }

      // Guardar en Supabase
      await _supabase.from('intentos_actividades').insert({
        'estudiante_id': userId,
        'actividad_id': 2,
        'numero_intento': numeroIntento,
        'puntaje': puntaje,
      });

      if (mounted) {
        _mostrarModalFinal(puntaje);
      }
    } catch (e) {
      debugPrint('Error guardando partida: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _mostrarModalFinal(double puntaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Secuencia Validada!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              puntaje >= 6 ? Icons.check_circle : Icons.warning,
              color: puntaje >= 6 ? Colors.green : Colors.orange,
              size: 80
            ),
            const SizedBox(height: 16),
            Text(
              'Alineaste $puntaje / 10 pasos correctamente.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tus resultados han sido registrados en la plataforma.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(); 
              },
              child: const Text('Volver a la Zona de Juegos'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2. Secuenciador del Proceso'),
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Validando y guardando secuencia...'),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF0F766E).withOpacity(0.2),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF0F766E)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Instrucciones: Mantén presionado y arrastra las tarjetas para ordenarlas cronológicamente desde el paso inicial (arriba) hasta el paso final (abajo).',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                    ),
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _itemsActuales.length,
                      onReorder: _onReorder,
                      buildDefaultDragHandles: false, // Desactivar el "=" feo
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            return Material(
                              color: Colors.transparent,
                              elevation: 12.0 * animation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  // Cambia a un color esmeralda cuando está seleccionado/arrastrándose
                                  color: Color.lerp(Colors.grey.shade900, const Color(0xFF0F766E), animation.value),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.3 * animation.value)),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final item = _itemsActuales[index];
                        return ReorderableDragStartListener(
                          key: ValueKey(item),
                          index: index,
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.grey.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                              ),
                              title: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF0F766E), // Teal oscuro
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'VALIDAR SECUENCIA',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        onPressed: _validarSecuencia,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
