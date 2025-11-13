import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🌐 URL base
  static const String baseUrl =
      'https://biblioteca-api-production-c839.up.railway.app/api';

  // =====================================================
  // 🔐 TOKEN EN MEMORIA (optimización)
  // =====================================================

  static String? _token;

  /// Inicializa el token al inicio de la app (en main o splash)
  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  /// Devuelve los headers con el token cargado
  static Map<String, String> getHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Guarda y actualiza el token al iniciar sesión
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _token = token;
  }

  /// Elimina el token al cerrar sesión
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _token = null;
  }

  // =====================================================
  // 🔐 AUTENTICACIÓN
  // =====================================================

  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final resp = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final token =
          data['access_token'] ?? data['token'] ?? data['data']?['token'];

      if (token != null) {
        await setToken(token); // ✅ se guarda en memoria y prefs
        return token;
      }
      return null;
    } else {
      debugPrint('❌ Error login: ${resp.body}');
      return null;
    }
  }

  // =====================================================
  // 👥 USUARIOS
  // =====================================================

  static Future<dynamic> getUsuarios({int page = 1}) async {
    final uri = Uri.parse(
      '$baseUrl/usuarios',
    ).replace(queryParameters: {'page': page.toString()});
    final resp = await http.get(uri, headers: getHeaders());
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Error al obtener usuarios: ${resp.body}');
  }

  static Future<bool> createUsuario({
    required String nombre,
    required String apellido,
    required String codigoEstudiante,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/usuarios');
    final response = await http.post(
      url,
      headers: getHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'codigo_estudiante': codigoEstudiante,
        'email': email,
      }),
    );

    debugPrint('🟩 CREATE usuario: ${response.statusCode} → ${response.body}');
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> updateUsuario({
    required String id,
    required String nombre,
    required String apellido,
    required String codigoEstudiante,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/$id');
    final resp = await http.put(
      uri,
      headers: getHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'codigo_estudiante': codigoEstudiante,
        'email': email,
      }),
    );

    debugPrint('🟨 UPDATE usuario: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 200;
  }

  static Future<bool> deleteUsuario(String id) async {
    final uri = Uri.parse('$baseUrl/usuarios/$id');
    final resp = await http.delete(uri, headers: getHeaders());
    debugPrint('🟥 DELETE usuario: ${resp.statusCode}');
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // =====================================================
  // 📚 LIBROS
  // =====================================================

  static Future<dynamic> getLibros({
    int page = 1,
    String? titulo,
    String? autor,
    String? categoria,
    String sort = 'titulo',
    String direction = 'asc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
      if (autor != null && autor.isNotEmpty) 'autor': autor,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      'sort': sort,
      'direction': direction,
    };

    final uri = Uri.parse(
      '$baseUrl/libros',
    ).replace(queryParameters: queryParams);
    final resp = await http.get(uri, headers: getHeaders());

    debugPrint('📘 GET libros → ${resp.statusCode} → ${resp.body}');
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Error al obtener libros: ${resp.body}');
    }
  }

  static Future<bool> createLibro(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/libros');
    final resp = await http.post(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );

    debugPrint('🟢 CREATE libro: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  static Future<bool> updateLibro(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/libros/$id');
    final resp = await http.put(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );

    debugPrint('🟨 UPDATE libro: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 200;
  }

  static Future<bool> deleteLibro(int id) async {
    final uri = Uri.parse('$baseUrl/libros/$id');
    final resp = await http.delete(uri, headers: getHeaders());

    debugPrint('🟥 DELETE libro: ${resp.statusCode}');
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // =====================================================
  // 💼 EMPLEADOS
  // =====================================================

  static Future<Map<String, dynamic>> getEmpleados({int page = 1}) async {
    final uri = Uri.parse(
      '$baseUrl/empleados',
    ).replace(queryParameters: {'page': page.toString()});
    final resp = await http.get(uri, headers: getHeaders());

    debugPrint('👥 GET empleados → ${resp.statusCode} → ${resp.body}');

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      return decoded is List ? {'data': decoded} : decoded;
    } else {
      throw Exception('Error al obtener empleados: ${resp.body}');
    }
  }

  static Future<bool> createEmpleado(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/empleados');
    final resp = await http.post(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );
    debugPrint('🟢 CREATE empleado: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  static Future<bool> updateEmpleado(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/empleados/$id');
    final resp = await http.put(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );
    debugPrint('🟨 UPDATE empleado: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 200;
  }

  static Future<bool> deleteEmpleado(int id) async {
    final uri = Uri.parse('$baseUrl/empleados/$id');
    final resp = await http.delete(uri, headers: getHeaders());
    debugPrint('🟥 DELETE empleado: ${resp.statusCode}');
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // =====================================================
  // 📦 PRÉSTAMOS
  // =====================================================

  static Future<dynamic> getPrestamos({
    int page = 1,
    String? estado,
    String? search,
  }) async {
    final query = {'page': page.toString()};
    if (estado != null && estado.isNotEmpty) query['estado'] = estado;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final uri = Uri.parse('$baseUrl/prestamos').replace(queryParameters: query);
    final resp = await http.get(uri, headers: getHeaders());

    debugPrint('📥 GET préstamos → ${resp.statusCode} → ${resp.body}');

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      return decoded is List ? {'data': decoded} : decoded;
    }

    throw Exception('Error al obtener préstamos: ${resp.body}');
  }

  static Future<bool> createPrestamo(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/prestamos');
    final resp = await http.post(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );

    debugPrint('🟢 CREATE préstamo: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  static Future<bool> devolverPrestamo(int id) async {
    final uri = Uri.parse('$baseUrl/prestamos/$id/devolver');
    final resp = await http.put(uri, headers: getHeaders());
    debugPrint('🔁 DEVOLVER préstamo: ${resp.statusCode} → ${resp.body}');
    return resp.statusCode == 200;
  }

  // =====================================================
  // 📊 DASHBOARD (Reportes con KPIs y gráficos)
  // =====================================================
  static Future<Map<String, dynamic>> getDashboardReport() async {
    try {
      final uri = Uri.parse('$baseUrl/reportes/dashboard');
      final resp = await http.get(uri, headers: getHeaders());

      debugPrint('📊 GET dashboard → ${resp.statusCode} → ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // Validamos que la respuesta contenga las claves esperadas
        if (data is Map<String, dynamic> &&
            data.containsKey('kpis') &&
            data.containsKey('graficos')) {
          return {
            'kpis': data['kpis'] ?? {},
            'graficos': data['graficos'] ?? {},
            'libros_mas_prestados':
                data['lista_libros_mas_prestados']?['original'] ?? [],
          };
        } else {
          throw Exception('Respuesta inesperada del servidor');
        }
      } else if (resp.statusCode == 401) {
        throw Exception('No autorizado. Token inválido o expirado.');
      } else {
        throw Exception('Error ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('❌ Error al obtener dashboard: $e');
      rethrow; // permite manejar el error desde la UI
    }
  }
}
