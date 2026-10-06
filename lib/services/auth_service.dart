import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Sesion contra el backend FastAPI (POST /api/auth/login).
/// Guarda el JWT en un JSON dentro del directorio de documentos de la app
/// (via path_provider: funciona en Android e iOS sin permisos extra),
/// asi la sesion sobrevive reinicios. Singleton en memoria + disco.
class AuthService {
  static const String _baseUrl = 'https://iot-backend-1-3rru.onrender.com/api';
  static const _kFileName = 'session.json';

  static final AuthService instance = AuthService._();
  AuthService._();

  String? _token;
  String? _correo;
  String? _nombre;
  String? _rol;
  bool _loaded = false;

  String? get token => _token;
  String? get correo => _correo;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<File> _sessionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_kFileName');
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _sessionFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        if (data is Map<String, dynamic>) {
          _token = data['token'] as String?;
          _correo = data['correo'] as String?;
          _nombre = data['nombre_completo'] as String?;
          _rol = data['rol'] as String?;
        }
      }
    } catch (_) {
      // Sesion corrupta o ilegible: se arranca sin sesion.
      _token = null;
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final file = await _sessionFile();
    await file.writeAsString(jsonEncode({
      'token': _token,
      'correo': _correo,
      'nombre_completo': _nombre,
      'rol': _rol,
    }));
  }

  /// Hace login y persiste la sesion. Lanza [AuthException] con mensaje
  /// listo para mostrar en UI.
  Future<void> login(String correo, String password) async {
    late final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw AuthException(
          'No se pudo conectar al servidor. Revisa tu internet.');
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _token = data['token'] as String?;
      _correo = (data['correo'] as String?) ?? correo.trim();
      _nombre = data['nombre_completo'] as String?;
      _rol = data['rol'] as String?;
      if (_token == null || _token!.isEmpty) {
        throw AuthException('El servidor no devolvio token.');
      }
      _loaded = true;
      await _persist();
      return;
    }
    if (res.statusCode == 401) {
      throw AuthException('Correo o contraseña incorrectos.');
    }
    String detail = 'Error del servidor (${res.statusCode}).';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      detail = (data['detail'] ?? data['error'] ?? detail).toString();
    } catch (_) {}
    throw AuthException(detail);
  }

  Future<void> logout() async {
    _token = null;
    _correo = null;
    _nombre = null;
    _rol = null;
    try {
      final file = await _sessionFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
