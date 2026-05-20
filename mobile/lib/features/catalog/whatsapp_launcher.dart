import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper pour lancer un lien WhatsApp depuis l'app.
/// L'URL générée par l'API (https://wa.me/...) ouvre WhatsApp s'il est installé,
/// sinon le navigateur web qui propose d'ouvrir l'app.
class WhatsAppLauncher {
  /// Lance l'URL via le système. Throws si l'URL est invalide.
  static Future<bool> launch(String url) async {
    final uri = Uri.parse(url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Copie l'URL dans le presse-papiers — utile pour partager via SMS / email.
  static Future<void> copyToClipboard(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }
}
