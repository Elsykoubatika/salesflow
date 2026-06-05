import 'package:flutter/material.dart';
import '../features/sales/sales_list_screen.dart';

/// Onglet « Commandes » du shell principal.
///
/// Pour le Lot 1, on pointe vers SalesOrdersScreen existant. Si tu as
/// renommé/déplacé le fichier (ex. sections/vente/orders/), ajuste l'import.
class OrdersTabScreen extends StatelessWidget {
  const OrdersTabScreen({super.key});

  @override
  Widget build(BuildContext context) => const SalesListScreen();
}
