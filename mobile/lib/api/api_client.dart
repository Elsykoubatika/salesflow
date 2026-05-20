import 'package:dio/dio.dart';

import '../auth/secure_storage.dart';

/// Configuration HTTP centrale.
///
/// IMPORTANT — adapter `baseUrl` selon votre environnement :
/// - Émulateur Android   → http://10.0.2.2:5000   (10.0.2.2 = host depuis l'émulateur)
/// - Simulateur iOS      → http://localhost:5000
/// - Téléphone physique  → http://<IP-PC-Wifi>:5000  (ex: http://192.168.1.42:5000)
///
/// On utilise HTTP (port 5000) en dev pour éviter les problèmes de certificat
/// auto-signé HTTPS sur mobile. Production : passer à HTTPS via reverse proxy.
class ApiConfig {
  // Par défaut : émulateur Android
  // À adapter selon votre configuration
  static const String baseUrl = 'http://10.0.2.2:5000';
}

/// Singleton Dio configuré : baseUrl, timeouts, ajout automatique du JWT.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // N'attache pas le token aux endpoints publics
          final isPublic = options.path.contains('/api/auth/login') ||
              options.path.contains('/api/auth/register') ||
              options.path.contains('/api/health');
          if (!isPublic) {
            final token = await SecureStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;
}
