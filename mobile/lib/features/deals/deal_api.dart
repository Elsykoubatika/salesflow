import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import 'deal_model.dart';

/// Client API du module Deal.
class DealApi {
  final ApiClient _client;
  DealApi(this._client);

  // ─── Listings ────────────────────────────────────────────────────────────

  Future<List<DealListItem>> listAvailable() async {
    try {
      final r = await _client.dio.get('/api/deals/available');
      final list = r.data as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(DealListItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<DealListItem>> listMine() async {
    try {
      final r = await _client.dio.get('/api/deals/mine');
      final list = r.data as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(DealListItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<MyEarnings> getMyEarnings() async {
    try {
      final r = await _client.dio.get('/api/deals/my-earnings');
      return MyEarnings.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  // ─── Détail / analytics ──────────────────────────────────────────────────

  Future<DealDetail> getDetail(String id) async {
    try {
      final r = await _client.dio.get('/api/deals/$id');
      return DealDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<DealAnalytics> getAnalytics(String id) async {
    try {
      final r = await _client.dio.get('/api/deals/$id/analytics');
      return DealAnalytics.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  // ─── Création ────────────────────────────────────────────────────────────

  Future<String> create({
    String? productId,
    required String title,
    String? description,
    required String commissionType, // CPC | CPS | CPA | CPL
    double? commissionAmount,
    double? commissionPercent,
    String? currency,
    String? conditions,
    int? stockAvailable,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) async {
    try {
      final r = await _client.dio.post('/api/deals', data: {
        if (productId != null) 'productId': productId,
        'title': title,
        if (description != null) 'description': description,
        'commissionType': commissionType,
        if (commissionAmount != null) 'commissionAmount': commissionAmount,
        if (commissionPercent != null) 'commissionPercent': commissionPercent,
        'currency': currency ?? 'XAF',
        if (conditions != null) 'conditions': conditions,
        if (stockAvailable != null) 'stockAvailable': stockAvailable,
        if (activeFrom != null) 'activeFrom': activeFrom.toIso8601String(),
        if (activeTo != null) 'activeTo': activeTo.toIso8601String(),
      });
      return (r.data as Map<String, dynamic>)['id'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        final err = (e.response!.data as Map)['error']?.toString();
        if (err != null) throw Exception(err);
      }
      throw _err(e);
    }
  }

  // ─── Partage ─────────────────────────────────────────────────────────────

  Future<ShareLink> createShare({
    required String dealId,
    required String channel, // WhatsApp | Facebook | Instagram | Direct | Own
  }) async {
    try {
      final r = await _client.dio.post(
        '/api/deals/$dealId/share',
        data: {'channel': channel},
      );
      return ShareLink.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  // ─── Erreurs ─────────────────────────────────────────────────────────────
  Exception _err(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) return Exception('Session expirée. Reconnectez-vous.');
    if (code == 403) return Exception('Accès refusé.');
    if (code == 404) return Exception('Deal introuvable.');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Connexion au serveur impossible.');
    }
    return Exception('Erreur inattendue.');
  }
}
