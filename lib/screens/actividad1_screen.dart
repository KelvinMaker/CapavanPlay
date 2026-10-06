import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Actividad1Screen extends StatefulWidget {
  const Actividad1Screen({super.key});

  @override
  State<Actividad1Screen> createState() => _Actividad1ScreenState();
}

class _Actividad1ScreenState extends State<Actividad1Screen> {
  final _supabase = Supabase.instance.client;
  int _currentStep = 0;
  double _puntaje = 0;
  bool _isSaving = false;

  // Variables para las selecciones actuales
  int? _selectedMenor;
  int? _selectedMinima;

  // Definición de los 5 casos (Escenarios)
  final List<Map<String, dynamic>> _casos = [
    {
      'entidad': 'Ministerio de Defensa',
      'presupuesto': '1.500.000',
      'menor_correcta': 1000,
      'minima_correcta': 100,
      'opciones_menor': [1000, 850, 650, 450],
      'opciones_minima': [100, 85, 65, 45],
    },
    {
      'entidad': 'Gobernación Cat. Especial',
      'presupuesto': '950.000',
      'menor_correcta': 850,
      'minima_correcta': 85,
      'opciones_menor': [1000, 850, 650, 280],
      'opciones_minima': [100, 85, 65, 28],
    },
    {
      'entidad': 'Alcaldía Ciudad Intermedia',
      'presupuesto': '550.000',
      'menor_correcta': 650,
      'minima_correcta': 65,
      'opciones_menor': [850, 650, 450, 280],
      'opciones_minima': [85, 65, 45, 28],
    },
    {
      'entidad': 'Escuela Naval de Suboficiales',
      'presupuesto': '220.000',
      'menor_correcta': 1000, // Regla especial MinDefensa
      'minima_correcta': 100, // Regla especial MinDefensa
      'opciones_menor': [1000, 650, 450, 280],
      'opciones_minima': [100, 65, 45, 28],
      'isTrampa': true,
    },
    {
      'entidad': 'Municipio 6.ª Categoría',
      'presupuesto': '75.000',
      'menor_correcta': 280,
      'minima_correcta': 28,
      'opciones_menor': [650, 450, 280, 150],
      'opciones_minima': [65, 45, 28, 15],
    }
  ];

  @override
  void initState() {
    super.initState();
    // Desordenar las opciones para que no siempre estén en la misma posición
    for (var caso in _casos) {
      (caso['opciones_menor'] as List).shuffle();
      (caso['opciones_minima'] as List).shuffle();
    }
  }

  Future<void> _finalizarJuego() async {
    setState(() => _isSaving = true);
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Averiguar el número de intento actual
      final response = await _supabase
          .from('intentos_actividades')
          .select('numero_intento')
          .eq('estudiante_id', userId)
          .eq('actividad_id', 1)
          .order('numero_intento', ascending: false)
          .limit(1);

      int numeroIntento = 1;
      if (response.isNotEmpty) {
        numeroIntento = (response.first['numero_intento'] as int) + 1;
      }

      // Limitar a 3 intentos estricto por ahora (hasta programar el panel del docente)
      if (numeroIntento > 3) {
        throw Exception("Has superado el límite de 3 intentos base.");
      }

      // Guardar intento en la base de datos
      await _supabase.from('intentos_actividades').insert({
        'estudiante_id': userId,
        'actividad_id': 1,
        'numero_intento': numeroIntento,
        'puntaje': _puntaje,
      });

      if (mounted) {
        _mostrarModalFinal(true);
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

  void _mostrarModalFinal(bool exito) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Actividad Completada!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            Text(
              'Tu Puntuación: ${_puntaje.toStringAsFixed(0)} / 10',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tus resultados han sido registrados exitosamente en el sistema de calificaciones.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar modal
                Navigator.of(context).pop(); // Volver al Hub
              },
              child: const Text('Volver a la Zona de Juegos'),
            ),
          )
        ],
      ),
    );
  }

  void _siguientePaso() {
    if (_selectedMenor == null || _selectedMinima == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona ambos topes para continuar.')),
      );
      return;
    }

    // Calcular puntos (1 punto por la menor, 1 punto por la mínima = 2 puntos por caso)
    final casoActual = _casos[_currentStep];
    if (_selectedMenor == casoActual['menor_correcta']) _puntaje += 1.0;
    if (_selectedMinima == casoActual['minima_correcta']) _puntaje += 1.0;

    if (_currentStep < _casos.length - 1) {
      setState(() {
        _currentStep++;
        _selectedMenor = null;
        _selectedMinima = null;
      });
    } else {
      _finalizarJuego();
    }
  }

  void _mostrarTablaAyuda() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tabla CCE - Consulta Rápida', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Recuerda la tabla oficial de Colombia Compra Eficiente (Ley 1150/07):\n'),
              _buildFilaTabla('> 1.200.000 SMLMV', 'Menor: 1.000', 'Mínima: 100'),
              _buildFilaTabla('850.000 a 1.200.000', 'Menor: 850', 'Mínima: 85'),
              _buildFilaTabla('400.000 a 850.000', 'Menor: 650', 'Mínima: 65'),
              _buildFilaTabla('120.000 a 400.000', 'Menor: 450', 'Mínima: 45'),
              _buildFilaTabla('< 120.000 SMLMV', 'Menor: 280', 'Mínima: 28'),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Ojo: Revisa si la entidad tiene alguna regla especial por dependencia.',
                style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  Widget _buildFilaTabla(String p, String menor, String minima) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(p, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text(menor, style: const TextStyle(color: Colors.blue, fontSize: 12))),
          Expanded(child: Text(minima, style: const TextStyle(color: Colors.green, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildOpciones(String titulo, List<int> opciones, int? seleccionActual, Function(int) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: opciones.map((valor) {
            final isSelected = seleccionActual == valor;
            return ChoiceChip(
              label: Text('$valor SMLMV'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(valor);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey.shade800,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final casoActual = _casos[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text('1. Calculadora Estratégica'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _casos.length,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarTablaAyuda,
        backgroundColor: Colors.orange,
        tooltip: 'Tabla CCE',
        child: const Icon(Icons.help_outline, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: _isSaving
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Escenario ${_currentStep + 1} de ${_casos.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 8,
                      color: const Color(0xFF1E3A8A), // Navy Blue
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance, size: 48, color: Colors.white54),
                            const SizedBox(height: 16),
                            Text(
                              casoActual['entidad'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Presupuesto Anual: ${casoActual['presupuesto']} SMLMV',
                                style: const TextStyle(fontSize: 16, color: Colors.orangeAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildOpciones(
                      'SELECCIONA LA MENOR CUANTÍA:',
                      List<int>.from(casoActual['opciones_menor']),
                      _selectedMenor,
                      (val) => setState(() => _selectedMenor = val),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Divider(color: Colors.white24),
                    ),
                    
                    _buildOpciones(
                      'SELECCIONA LA MÍNIMA CUANTÍA (10%):',
                      List<int>.from(casoActual['opciones_minima']),
                      _selectedMinima,
                      (val) => setState(() => _selectedMinima = val),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _siguientePaso,
                      child: Text(
                        _currentStep == _casos.length - 1 ? 'FINALIZAR Y EVALUAR' : 'SIGUIENTE ESCENARIO',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 80), // Espacio para el FAB
                  ],
                ),
              ),
      ),
    );
  }
}
