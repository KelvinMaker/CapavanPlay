import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  // Respuestas del 1 al 5
  int? _q1;
  int? _q2;
  int? _q3;
  int? _q4;
  int? _q5;

  final List<String> _preguntas = [
    "Transferencia: El uso del simulador CapavanPlay me permitió comprender los conceptos de Gestión Administrativa con mayor claridad que las metodologías tradicionales.",
    "Utilidad: Considero que los escenarios interactivos del simulador desarrollan competencias útiles y aplicables a mi futura práctica profesional.",
    "Motivación: La gamificación de las actividades incrementó significativamente mi interés y disposición por aprender los temas del curso.",
    "Usabilidad UX: La interfaz de la aplicación en mi celular resultó ser intuitiva, clara y fácil de navegar sin necesidad de instrucciones adicionales.",
    "Impacto: Recomiendo la integración de este tipo de simuladores basados en Inteligencia Artificial en otras asignaturas de mi formación."
  ];

  Widget _buildLikertQuestion(int index, String question, int? currentValue, Function(int) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${index + 1}. $question",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final value = i + 1;
              final isSelected = currentValue == value;
              return GestureDetector(
                onTap: () => onChanged(value),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade400 : Colors.white30,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Totalmente\nen desacuerdo", style: TextStyle(fontSize: 11, color: Colors.white54)),
              Text("Totalmente\nde acuerdo", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _submitSurvey() async {
    if (_q1 == null || _q2 == null || _q3 == null || _q4 == null || _q5 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, responde todas las preguntas antes de enviar.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('satisfaccion').insert({
        'estudiante_id': userId,
        'q1_transferencia': _q1,
        'q2_utilidad': _q2,
        'q3_motivacion': _q3,
        'q4_usabilidad': _q4,
        'q5_impacto': _q5,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por evaluar la experiencia!')),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      debugPrint('Error enviando encuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar la encuesta. Inténtalo de nuevo.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación de la Experiencia'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "¡Felicidades por completar el simulador!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Por favor, evalúa las siguientes afirmaciones de 1 a 5 para ayudarnos a mejorar.",
              style: TextStyle(fontSize: 15, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildLikertQuestion(0, _preguntas[0], _q1, (v) => setState(() => _q1 = v)),
            _buildLikertQuestion(1, _preguntas[1], _q2, (v) => setState(() => _q2 = v)),
            _buildLikertQuestion(2, _preguntas[2], _q3, (v) => setState(() => _q3 = v)),
            _buildLikertQuestion(3, _preguntas[3], _q4, (v) => setState(() => _q4 = v)),
            _buildLikertQuestion(4, _preguntas[4], _q5, (v) => setState(() => _q5 = v)),
            
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitSurvey,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar Evaluación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
