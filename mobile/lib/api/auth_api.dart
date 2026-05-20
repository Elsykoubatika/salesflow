import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import 'api_client.dart';

/// Façade pour les endpoints d'authentification.
class AuthApi {
  final Dio _dio = ApiClient().dio;

  /// POST /api/auth/login
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  /// POST /api/auth/register
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    int domainType = 1,
  }) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'domainType': domainType,
      });
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  /// GET /api/auth/me - utilise le JWT en mémoire (intercepteur).
  /// Permet de valider qu'un token sauvegardé est encore actif au démarrage.
  Future<UserProfile> me() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  /// Convertit une DioException en message lisible pour l'utilisateur final.
  Exception _toReadable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de joindre le serveur. Vérifiez votre connexion.');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return Exception(data['error'].toString());
      }
      if (e.response!.statusCode == 401) {
        return Exception('Email ou mot de passe incorrect.');
      }
      if (e.response!.statusCode == 400) {
        return Exception('Données invalides. Vérifiez les champs.');
      }
    }
    return Exception('Erreur inattendue. Réessayez.');
  }
}
