import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/api_client.dart';

/// Télécharge les PDF de devis depuis l'API et les met en cache
/// dans le dossier temporaire de l'app pour réouverture rapide.
class PdfHelper {
  final Dio _dio = ApiClient().dio;

  /// Télécharge le PDF d'une commande et le sauvegarde dans un fichier local.
  /// Retourne le chemin du fichier prêt à être ouvert ou partagé.
  Future<File> downloadSalesOrderPdf(String orderId, String orderNumber) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/sales-orders/$orderId/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          // L'intercepteur ajoute déjà le Bearer token
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw Exception('Le serveur a renvoyé un PDF vide.');
      }

      // Stockage temporaire (purgé par le système à terme)
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$orderNumber.pdf');
      await file.writeAsBytes(response.data!, flush: true);
      return file;
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Exception _toReadable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de joindre le serveur.');
    }
    if (e.response?.statusCode == 404) return Exception('Document introuvable.');
    if (e.response?.statusCode == 401) return Exception('Session expirée.');
    return Exception('Erreur lors du téléchargement du PDF.');
  }
}
