import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import 'dashboard_model.dart';

/// Client API pour le Dashboard.
///
/// Endpoint unique : GET /api/dashboard/overview
class DashboardApi {
  final ApiClient _client;
  DashboardApi(this._client);

  Future<DashboardOverview> getOverview() async {
    try {
      final response = await _client.dio.get('/api/dashboard/overview');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Réponse Dashboard invalide.');
      }
      return DashboardOverview.fromJson(data);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  // ─── Erreurs ─────────────────────────────────────────────────────────────
  Exception _err(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) return Exception('Session expirée. Reconnectez-vous.');
    if (code == 403) return Exception('Accès refusé.');
    if (code == 404) return Exception('Dashboard introuvable.');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Connexion au serveur impossible.');
    }
    return Exception('Erreur inattendue lors du chargement du dashboard.');
  }
}
