import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Actividad3Screen extends StatefulWidget {
  const Actividad3Screen({super.key});

  @override
  State<Actividad3Screen> createState() => _Actividad3ScreenState();
}

class _Actividad3ScreenState extends State<Actividad3Screen> {
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;
  int _currentIndex = 0;
  double _puntaje = 0;

  final List<Map<String, dynamic>> _casos = [
    {
      'texto': 'Gestión del gasto público e impuestos para suavizar los ciclos económicos.',
      'pilar_id': 1,
    },
    {
      'texto': 'Medidas para preservar el poder adquisitivo de la moneda.',
      'pilar_id': 1,
    },
    {
      'texto': 'Fomento de condiciones que maximicen la utilización de la fuerza laboral.',
      'pilar_id': 1,
    },
    {
      'texto': 'Corrección de efectos secundarios mediante impuestos o normas.',
      'pilar_id': 2,
    },
    {
      'texto': 'Regulación de monopolios y oligopolios.',
      'pilar_id': 2,
    },
    {
      'texto': 'Protección ante la falta de transparencia en las transacciones.',
      'pilar_id': 2,
    },
    {
      'texto': 'Quienes más tienen, contribuyen proporcionalmente más.',
      'pilar_id': 3,
    },
    {
      'texto': 'Pensiones, subsidios de desempleo y ayudas directas.',
      'pilar_id': 3,
    },
    {
      'texto': 'Gravámenes sobre productos nocivos como el tabaco o emisiones de CO2.',
      'pilar_id': 4,
    },
    {
      'texto': 'Incentivos para el consumo de cultura, deporte y alimentación sana.',
      'pilar_id': 4,
    },
  ];

  final List<Map<String, dynamic>> _pilares = [
    {'id': 1, 'nombre': 'Estabilidad Macroeconómica', 'color': Colors.blue, 'icono': Icons.show_chart},
    {'id': 2, 'nombre': 'Fallos de Mercado', 'color': Colors.red, 'icono': Icons.build},
    {'id': 3, 'nombre': 'Equidad y Distribución', 'color': Colors.green, 'icono': Icons.balance},
    {'id': 4, 'nombre': 'Patrones de Consumo', 'color': Colors.orange, 'icono': Icons.shopping_cart},
  ];

  @override
  void initState() {
    super.initState();
    _casos.shuffle(); // Aleatorizar el orden de las tarjetas
  }

  void _clasificar(int pilarSeleccionado) {
    if (_casos[_currentIndex]['pilar_id'] == pilarSeleccionado) {
      _puntaje += 1.0;
    }

    if (_currentIndex < _casos.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finalizarJuego();
    }
  }

  Future<void> _finalizarJuego() async {
    setState(() => _isSaving = true);
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('intentos_actividades')
          .select('numero_intento')
          .eq('estudiante_id', userId)
          .eq('actividad_id', 3)
          .order('numero_intento', ascending: false)
          .limit(1);

      int numeroIntento = 1;
      if (response.isNotEmpty) {
        numeroIntento = (response.first['numero_intento'] as int) + 1;
      }

      if (numeroIntento > 3) {
        throw Exception("Has superado el límite de 3 intentos base.");
      }

      await _supabase.from('intentos_actividades').insert({
        'estudiante_id': userId,
        'actividad_id': 3,
        'numero_intento': numeroIntento,
        'puntaje': _puntaje,
      });

      if (mounted) {
        _mostrarModalFinal();
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

  void _mostrarModalFinal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Matriz Completada!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _puntaje >= 6 ? Icons.star : Icons.star_half,
              color: Colors.amber,
              size: 80
            ),
            const SizedBox(height: 16),
            Text(
              'Clasificaste ${_puntaje.toStringAsFixed(0)} / 10 casos correctamente.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildPilarDragTarget(Map<String, dynamic> pilar) {
    return DragTarget<int>(
      onAccept: (data) {
        _clasificar(pilar['id']);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return InkWell(
          onTap: () => _clasificar(pilar['id']), // Soporte para Tap Directo
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isHovered ? pilar['color'].withOpacity(0.4) : pilar['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered ? pilar['color'] : pilar['color'].withOpacity(0.5),
                width: isHovered ? 3 : 1,
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    child: Icon(pilar['icono'], color: pilar['color']),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      pilar['nombre'],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final casoActual = _casos[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('3. Matriz Rol del Estado'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _casos.length,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando resultados...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Arrastra la tarjeta (o tócala y luego toca el pilar) hacia su clasificación correcta:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // TARJETA ARRASTRABLE
                  Draggable<int>(
                    data: _currentIndex,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 15)
                          ],
                        ),
                        child: Text(
                          casoActual['texto'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12, style: BorderStyle.solid),
                      ),
                      child: const Text(
                        'Arrastrando...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white30),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Caso ${_currentIndex + 1} de ${_casos.length}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            casoActual['texto'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          const Icon(Icons.touch_app, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // GRID DE LOS 4 PILARES (Responsivo)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildPilarDragTarget(_pilares[0])),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPilarDragTarget(_pilares[1])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildPilarDragTarget(_pilares[2])),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPilarDragTarget(_pilares[3])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
