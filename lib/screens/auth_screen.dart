import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isAdminMode = false;

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAdminMode) {
        // LÓGICA EXCLUSIVA PARA DOCENTE ADMINISTRADOR
        final usuario = _idController.text.trim();
        final password = _passwordController.text.trim();

        if (usuario != 'Admin' || password != 'Admin123*') {
          _showError('Usuario o contraseña de administrador incorrectos.');
          setState(() => _isLoading = false);
          return;
        }

        try {
          // Intentamos iniciar sesión
          await _supabase.auth.signInWithPassword(
            email: 'admin@capavan.app',
            password: 'Admin123*',
          );
        } catch (e) {
          // Si no existe, lo creamos ocultamente la primera vez
          final res = await _supabase.auth.signUp(
            email: 'admin@capavan.app',
            password: 'Admin123*',
          );
          if (res.user != null) {
            await _supabase.from('perfiles').insert({
              'id': res.user!.id,
              'nombres': 'Docente',
              'apellidos': 'Administrador',
              'identificacion': 'Admin',
              'rol': 'docente',
            });
          }
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }

      } else {
        // LÓGICA ORIGINAL PARA ESTUDIANTE
        final identificacion = _idController.text.trim();
        final emailSimulado = '$identificacion@capavan.app';

        if (_isLogin) {
          await _supabase.auth.signInWithPassword(
            email: emailSimulado,
            password: identificacion,
          );
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          final authResponse = await _supabase.auth.signUp(
            email: emailSimulado,
            password: identificacion,
          );
          if (authResponse.user != null) {
            await _supabase.from('perfiles').insert({
              'id': authResponse.user!.id,
              'nombres': _nombresController.text.trim(),
              'apellidos': _apellidosController.text.trim(),
              'identificacion': identificacion,
              'rol': 'estudiante',
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registro exitoso. Bienvenido!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          }
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Ocurrió un error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Selector de Rol Responsivo (Docente / Estudiante)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAdminMode = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isAdminMode ? const Color(0xFF10B981) : Colors.transparent, // Emerald
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.school, color: !_isAdminMode ? Colors.white : Colors.white70, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Estudiante',
                                          style: TextStyle(
                                            color: !_isAdminMode ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAdminMode = true;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isAdminMode ? const Color(0xFF3B82F6) : Colors.transparent, // Blue
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.admin_panel_settings, color: _isAdminMode ? Colors.white : Colors.white70, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Docente',
                                          style: TextStyle(
                                            color: _isAdminMode ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  Text(
                    _isLogin 
                        ? (_isAdminMode ? 'Iniciar Sesión (Docente)' : 'Iniciar Sesión') 
                        : 'Registro de ${_isAdminMode ? 'Docente' : 'Estudiante'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin 
                      ? 'Ingresa tu número de identificación' 
                      : 'Completa tus datos para ingresar por primera vez',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  if (!_isAdminMode && !_isLogin) ...[
                    TextFormField(
                      controller: _nombresController,
                      decoration: const InputDecoration(
                        labelText: 'Nombres Completos',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apellidosController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos Completos',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: _isAdminMode ? 'Usuario' : 'Número de Identificación',
                      prefixIcon: Icon(_isAdminMode ? Icons.admin_panel_settings : Icons.badge),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: _isAdminMode ? TextInputType.text : TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Requerido' : null,
                  ),
                  
                  if (_isAdminMode) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isAdminMode ? Colors.orange.shade700 : colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text((_isLogin || _isAdminMode) ? 'Ingresar' : 'Registrarse', style: const TextStyle(fontSize: 16)),
                  ),
                  
                  if (!_isAdminMode) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? '¿Es tu primera vez? Regístrate aquí'
                            : '¿Ya estás registrado? Inicia sesión',
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
