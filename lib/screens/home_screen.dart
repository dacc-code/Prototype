import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'camera_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sessionLoading = true;

  @override
  void initState() {
    super.initState();
    AuthService.instance.load().then((_) {
      if (mounted) setState(() => _sessionLoading = false);
    });
  }

  Future<void> _openSession() async {
    if (AuthService.instance.isLoggedIn) {
      final logout = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Sesión activa'),
          content: Text(
              'Conectado como ${AuthService.instance.correo ?? ''}.\n¿Cerrar sesión?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Cerrar sesión')),
          ],
        ),
      );
      if (logout == true) {
        await AuthService.instance.logout();
        setState(() {});
      }
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (ok == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logged = AuthService.instance.isLoggedIn;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Estado de sesion con el backend (necesario para "Enviar al Dashboard").
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_sessionLoading)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      )
                    else
                      TextButton.icon(
                        onPressed: _openSession,
                        icon: Icon(
                          logged ? Icons.cloud_done : Icons.cloud_off,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          logged
                              ? (AuthService.instance.correo ?? 'Conectado')
                              : 'Conectar backend',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Manglares',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Detector de Enfermedades',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Usa inteligencia artificial para detectar enfermedades en manglares en tiempo real',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(30),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CameraScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Iniciar Detección',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _showInfoDialog(context),
                child: const Text(
                  '¿Cómo funciona?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF1B5E20)),
            SizedBox(width: 10),
            Text('¿Cómo funciona?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Conecta tu cuenta del dashboard (arriba a la derecha)'),
            SizedBox(height: 10),
            Text('2. Apunta la cámara hacia una hoja de mangle'),
            SizedBox(height: 10),
            Text('3. La app analizará la imagen con IA en el dispositivo'),
            SizedBox(height: 10),
            Text('4. Pulsa "Enviar al Dashboard" para verla en la web'),
            SizedBox(height: 10),
            Text('5. Sigue las recomendaciones para el tratamiento'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
