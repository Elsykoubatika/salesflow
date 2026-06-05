import 'package:flutter/material.dart';
import '../features/catalog/catalog_list_screen.dart';

/// Onglet « Catalogue » du shell principal.
///
/// Pour le Lot 1, on réutilise l'écran existant CatalogListScreen, déjà
/// connecté au backend et au catalogue produits du vendeur. Le Lot 2
/// ajoutera la bascule vers le catalogue public (mode invité).
class CatalogTabScreen extends StatelessWidget {
  const CatalogTabScreen({super.key});

  @override
  Widget build(BuildContext context) => const CatalogListScreen();
}
