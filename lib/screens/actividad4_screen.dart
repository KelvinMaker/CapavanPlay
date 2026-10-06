import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class Actividad4Screen extends StatefulWidget {
  const Actividad4Screen({super.key});

  @override
  State<Actividad4Screen> createState() => _Actividad4ScreenState();
}

class _Actividad4ScreenState extends State<Actividad4Screen> {
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;
  
  List<Map<String, dynamic>> _preguntasSeleccionadas = [];
  int _currentIndex = 0;
  double _puntaje = 0;
  
  Timer? _timer;
  int _tiempoRestante = 30; // 30 segundos por pregunta

  final List<Map<String, dynamic>> _bancoPreguntas = [
    {
      'pregunta': '''¿Cuál es el objetivo principal de aplicar Business Intelligence (BI) en una organización?''',
      'opciones': [
        '''A) Reemplazar a los administradores por computadoras.''',
        '''B) Transformar datos en información clara para tomar mejores decisiones gerenciales.''',
        '''C) Comprar más discos duros y servidores informáticos.''',
        '''D) Guardar documentos físicos en carpetas digitales.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''En la administración moderna, ¿qué significa tomar decisiones "basadas en datos" (*Data-Driven*)?''',
      'opciones': [
        '''A) Decidir únicamente según la intuición de la jefatura.''',
        '''B) Apoyar las estrategias en evidencia y análisis de métricas reales.''',
        '''C) Copiar las decisiones de otras instituciones sin evaluar.''',
        '''D) Esperar a que ocurra un problema crítico para buscar información.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Si los datos brutos son la "materia prima" de la organización, ¿qué representa el Business Intelligence (BI)?''',
      'opciones': [
        '''A) El archivo muerto de la institución.''',
        '''B) El proceso de refinar esa información para generar conocimiento útil.''',
        '''C) El costo administrativo anual.''',
        '''D) Un programa exclusivo para el área de informática.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Si un directivo observa que las metas de gestión bajaron un 15% este mes, ¿qué pregunta busca responder el análisis descriptivo?''',
      'opciones': [
        '''A) "¿Qué ocurrió en la organización durante este período?"''',
        '''B) "¿Qué pasará dentro de 10 años?"''',
        '''C) "¿Por qué existe el mercado global?"''',
        '''D) "¿Cómo programar una aplicación web?"''',
      ],
      'respuesta_correcta': 0
    },
    {
      'pregunta': '''¿Qué beneficio directo obtiene un líder de área al contar con un indicador clave de rendimiento (KPI) bien definido?''',
      'opciones': [
        '''A) Elimina la necesidad de supervisar al personal.''',
        '''B) Mide de forma objetiva si se están alcanzando los objetivos estratégicos.''',
        '''C) Aumenta el presupuesto asignado de forma automática.''',
        '''D) Exime a la entidad de rendir cuentas.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Cuando en gestión se habla de la V de "Volumen" en los datos, nos referimos a:''',
      'opciones': [
        '''A) El nivel de sonido en las reuniones de trabajo.''',
        '''B) La gran cantidad de registros e información que la entidad genera diariamente.''',
        '''C) El precio de los equipos de oficina.''',
        '''D) La cantidad de personal contratado en el área.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''En la gestión de compras y suministros, aplicar la V de "Velocidad" significa:''',
      'opciones': [
        '''A) Que los vehículos de entrega circulen a mayor velocidad.''',
        '''B) Recibir y procesar información a tiempo para reponer inventarios sin afectar la operación.''',
        '''C) Firmar documentos sin leerlos previamente.''',
        '''D) Aumentar la velocidad del internet en la oficina.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Si un informe financiero presenta cifras inconsistentes, errores de digitación y datos duplicados, ¿qué V de la información falló?''',
      'opciones': [
        '''A) Variedad.''',
        '''B) Veracidad (Confiabilidad y calidad de los datos).''',
        '''C) Volumen.''',
        '''D) Velocidad.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''La V de "Variedad" implica que un administrador actual debe tomar decisiones analizando:''',
      'opciones': [
        '''A) Únicamente cifras en hojas de cálculo tradicionales.''',
        '''B) Diversas fuentes como textos, reportes, encuestas, imágenes y tablas de datos.''',
        '''C) Múltiples marcas de computadores.''',
        '''D) Los diferentes cargos de la nómina.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿A qué se refiere la V de "Valor" en la analítica de gestión?''',
      'opciones': [
        '''A) Al costo económico de adquirir un software.''',
        '''B) A la utilidad real que aporta la información para resolver problemas y mejorar procesos.''',
        '''C) Al valor comercial del mobiliario de la oficina.''',
        '''D) Al peso en megabytes de un archivo.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Una tabla de proveedores con NIT, nombre, teléfono y valor contratado en filas y columnas es un ejemplo de:''',
      'opciones': [
        '''A) Datos Estructurados.''',
        '''B) Datos No Estructurados.''',
        '''C) Información confidencial sin clasificar.''',
        '''D) Archivo de audio.''',
      ],
      'respuesta_correcta': 0
    },
    {
      'pregunta': '''Las grabaciones de llamadas de atención al usuario o las fotos de inspección de un equipo son ejemplos de:''',
      'opciones': [
        '''A) Datos Estructurados.''',
        '''B) Datos No Estructurados.''',
        '''C) Tablas estadísticas SQL.''',
        '''D) Fórmulas presupuestales.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿Por qué los datos no estructurados (como opiniones en encuestas abiertas o correos) son valiosos para un administrador?''',
      'opciones': [
        '''A) Porque no ocupan espacio en el sistema.''',
        '''B) Porque revelan percepciones, aspectos cualitativos y detalles que los números solos no muestran.''',
        '''C) Porque se pueden organizar fácilmente a mano.''',
        '''D) Porque carecen de importancia y se pueden ignorar.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿Cuál es el principal riesgo administrativo de tomar decisiones basándose en "datos de mala calidad"?''',
      'opciones': [
        '''A) Que las reuniones duran menos tiempo.''',
        '''B) Generar reprocesos, pérdidas de recursos y decisiones erróneas.''',
        '''C) Que mejora la satisfacción del usuario.''',
        '''D) Que se agota la memoria del equipo informático.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿Qué paso debe realizar un equipo administrativo antes de presentar un informe directivo definitivo?''',
      'opciones': [
        '''A) Ajustar las cifras para que los resultados parezcan favorables.''',
        '''B) Validar, depurar y verificar las fuentes de donde proviene la información.''',
        '''C) Omitir las áreas que tuvieron bajo desempeño.''',
        '''D) Enviar el documento sin revisar los totales.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Un Dashboard o Tablero de Control Gerencial sirve fundamentalmente para:''',
      'opciones': [
        '''A) Reemplazar el archivo físico de carpetas.''',
        '''B) Visualizar de forma gráfica y resumida los indicadores clave de la gestión.''',
        '''C) Imprimir reportes extensos en papel.''',
        '''D) Enviar comunicaciones masivas a los usuarios.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''Si un jefe de departamento hace clic en un gráfico general de presupuesto para ver los gastos detallados de una unidad específica, utiliza la función de:''',
      'opciones': [
        '''A) Formatear la pantalla.''',
        '''B) Profundización o exploración de datos (Drill-Down).''',
        '''C) Borrado de historial.''',
        '''D) Copia de respaldo.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿Qué caracteriza a un Dashboard de gestión realmente efectivo?''',
      'opciones': [
        '''A) Contener decenas de gráficos complejos sin títulos claros.''',
        '''B) Presentar información clara, actualizada e interactiva que facilite la lectura en un vistazo.''',
        '''C) Ocultar los indicadores que estén fuera de la meta.''',
        '''D) Actualizarse únicamente una vez al año.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿Qué ventaja práctica ofrece un tablero dinámico de BI frente a un informe tradicional impreso en PDF?''',
      'opciones': [
        '''A) El informe impreso es más económico de elaborar.''',
        '''B) El tablero dinámico permite filtrar, interactuar y consultar datos actualizados en tiempo real.''',
        '''C) El PDF cambia sus datos de forma automática.''',
        '''D) No existe ninguna ventaja en la gestión diaria.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''En un cuadro de mando administrativo, una alerta visual en rojo sobre un KPI de ejecución presupuestal indica que:''',
      'opciones': [
        '''A) La actividad ha finalizado con éxito.''',
        '''B) El indicador está fuera del rango aceptable y requiere intervención de la jefatura.''',
        '''C) Se ha recibido un incremento presupuestal.''',
        '''D) La aplicación ha dejado de funcionar.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''En la gestión del talento humano, ¿cómo ayuda la analítica de datos a la dirección?''',
      'opciones': [
        '''A) Decidiendo contrataciones de forma automática sin entrevistas.''',
        '''B) Identificando causas de rotación, necesidades de capacitación y clima laboral.''',
        '''C) Eliminando el proceso de evaluación del desempeño.''',
        '''D) Registrando la hora exacta de descanso del personal.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''En la gestión logística y de abastecimiento, un tablero de BI permite a la administración:''',
      'opciones': [
        '''A) Comprar insumos sin revisar especificaciones ni precios.''',
        '''B) Evaluar tiempos de entrega de proveedores y mantener niveles óptimos de inventario.''',
        '''C) Eliminar la necesidad de almacenes e inspecciones.''',
        '''D) Cancelar los contratos de mantenimiento preventivo.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''El análisis predictivo en la gestión de mantenimiento de equipos e instalaciones busca:''',
      'opciones': [
        '''A) Reparar los elementos únicamente cuando sufran una falla total.''',
        '''B) Anticipar posibles fallas basándose en el historial de uso y desgaste para evitar paradas no programadas.''',
        '''C) Ignorar las recomendaciones técnicas de los fabricantes.''',
        '''D) Reemplazar todos los equipos cada tres meses.''',
      ],
      'respuesta_correcta': 1
    },
    {
      'pregunta': '''¿Cuál es el propósito final de integrar la analítica de datos en la gestión administrativa?''',
      'opciones': [
        '''A) Mostrar gráficos atractivos en las presentaciones.''',
        '''B) Alinear la operación diaria con los objetivos estratégicos e institucionales.''',
        '''C) Evitar el uso de tecnologías en los procesos de oficina.''',
        '''D) Delegar la responsabilidad directiva en sistemas informáticos.''',
      ],
      'respuesta_correcta': 1
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarJuego();
  }

  void _iniciarJuego() {
    _bancoPreguntas.shuffle();
    _preguntasSeleccionadas = _bancoPreguntas.take(10).toList();
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _tiempoRestante = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_tiempoRestante > 0) {
        setState(() => _tiempoRestante--);
      } else {
        _responder(-1); // Tiempo agotado
      }
    });
  }

  void _responder(int indexSeleccionado) {
    _timer?.cancel();
    
    if (indexSeleccionado != -1 && indexSeleccionado == _preguntasSeleccionadas[_currentIndex]['respuesta_correcta']) {
      _puntaje += 1.0;
    }

    if (_currentIndex < _preguntasSeleccionadas.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _iniciarTemporizador();
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
          .eq('actividad_id', 4)
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
        'actividad_id': 4,
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
        title: const Text('¡Trivia Finalizada!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _puntaje >= 6 ? Icons.emoji_events : Icons.sentiment_neutral,
              color: _puntaje >= 6 ? Colors.amber : Colors.grey,
              size: 80
            ),
            const SizedBox(height: 16),
            Text(
              'Obtuviste ${_puntaje.toStringAsFixed(0)} / 10 puntos.',
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_preguntasSeleccionadas.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final preguntaActual = _preguntasSeleccionadas[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('4. Trivia Gerencial BI'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _preguntasSeleccionadas.length,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pregunta ${_currentIndex + 1}/10',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _tiempoRestante <= 10 ? Colors.red.withOpacity(0.2) : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _tiempoRestante <= 10 ? Colors.red : Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer, size: 16, color: _tiempoRestante <= 10 ? Colors.red : Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '$_tiempoRestante s',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: _tiempoRestante <= 10 ? Colors.red : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    preguntaActual['pregunta'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const SizedBox(height: 48),
                  ...List.generate((preguntaActual['opciones'] as List).length, (index) {
                    final opcion = preguntaActual['opciones'][index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () => _responder(index),
                        child: Text(
                          opcion,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
