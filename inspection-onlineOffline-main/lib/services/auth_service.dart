import 'package:app_inspections/services/db_offline.dart';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

enum AuthState { authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  AuthState _authState = AuthState.unauthenticated;
  AuthState get authState => _authState;

  String? _currentUser;
  String? get currentUser => _currentUser;
  bool? _isAdmin;
  bool? get isAdmin => _isAdmin;

  final String _databaseHost =
      'ep-red-wood-a4nzhmfu-pooler.us-east-1.postgres.vercel-storage.com';
  final int _databasePort = 5432;
  final String _databaseName = 'verceldb';
  final String _username = 'default';
  final String _password = 'Iqkc7nFOlR6d';

  final storage = const FlutterSecureStorage();

  Future<PostgreSQLConnection> openConnection() async {
    try {
      final connection = PostgreSQLConnection(
        _databaseHost,
        _databasePort,
        _databaseName,
        username: _username,
        password: _password,
        useSSL: true,
      );

      await connection.open();
      if (kDebugMode) {
        print('BASE CONECTADA');
      }
      return connection;
    } catch (e) {
      if (kDebugMode) {
        print('Error al abrir la conexión: $e');
      }
      rethrow;
    }
  }

  Future<void> closeConnection() async {
    final connection = await openConnection();
    await connection.close();
    if (kDebugMode) {
      print('Conexión a PostgreSQL cerrada');
    }
  }

  // Método para establecer el nombre de usuario actual
  void setCurrentUser(String username, bool isAdmin) {
    _currentUser = username;
    _isAdmin = isAdmin;
    notifyListeners(); // Notificar a los listeners que el estado ha cambiado
  }

  Future<String?> createUser(
      String name, String email, String contrasena) async {
    try {
      final connection = await openConnection();
      await connection.query(
          'INSERT INTO usuarios (nombre, email, password) VALUES (@name, @email, @contrasena)',
          substitutionValues: {
            'name': name,
            'email': email,
            'contrasena': contrasena
          });
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error al registrar usuario: $e');
      }
      return e.toString();
    }
  }

  Future<String?> login(String nomUsu, String contrasena) async {
    try {
      Database database = await DatabaseProvider.openDB();
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT nombre, permiso FROM usuarios WHERE nom_usu = ? AND password = ?',
        [nomUsu, contrasena],
      );
      if (results.isNotEmpty) {
        final nombreCompleto = results[0]['nombre'] as String;
        final isAdminInt = results[0]['permiso'] as int;
        final isAdmin = isAdminInt == 1; // Convertir de int a bool
        setCurrentUser(nombreCompleto, isAdmin);
        _authState = AuthState.authenticated;
        notifyListeners();
        print("ADMIIIN $isAdmin");
        return null;
      } else {
        return 'Credenciales incorrectas';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al iniciar sesión: $e');
      }
      return e.toString();
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    _authState = AuthState.unauthenticated;
    notifyListeners();
    if (kDebugMode) {
      print('Usuario desconectado');
    }
  }
}
