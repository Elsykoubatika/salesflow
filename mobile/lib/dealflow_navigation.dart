import 'package:flutter/material.dart';
import 'features/technical/technical_quote_form.dart';
import 'features/liberal/project_management_screen.dart';
import 'features/liberal/finance_management_screen.dart';

/// DealFlow Pro Congo - Complete Navigation
/// Integrates Commerce, Technical, and Liberal modules

class DealFlowNavigation {
  static const String home = '/';
  static const String commerce_clients = '/commerce/clients';
  static const String commerce_catalog = '/commerce/catalog';
  static const String commerce_sales = '/commerce/sales';
  static const String commerce_inventory = '/commerce/inventory';
  static const String commerce_proofs = '/commerce/proofs';

  static const String technical_quotes = '/technical/quotes';
  static const String technical_interventions = '/technical/interventions';
  static const String technical_maintenance = '/technical/maintenance';
  static const String technical_invoices = '/technical/invoices';

  static const String liberal_projects = '/liberal/projects';
  static const String liberal_contracts = '/liberal/contracts';
  static const String liberal_finance = '/liberal/finance';
  static const String liberal_invoices = '/liberal/invoices';

  static const String settings = '/settings';
}

/// Main menu items for DealFlow - All modules visible (Option C)
class MenuStructure {
  static const List<MenuCategory> allCategories = [
    MenuCategory(
      name: 'Commerce',
      icon: Icons.shopping_cart,
      color: Color(0xFF0A5F44),
      items: [
        MenuItem(label: 'Clients', icon: Icons.people, route: DealFlowNavigation.commerce_clients),
        MenuItem(label: 'Catalogue', icon: Icons.inventory, route: DealFlowNavigation.commerce_catalog),
        MenuItem(label: 'Commandes', icon: Icons.receipt_long, route: DealFlowNavigation.commerce_sales),
        MenuItem(label: 'Stock', icon: Icons.warehouse, route: DealFlowNavigation.commerce_inventory),
        MenuItem(label: 'Coffre-Fort', icon: Icons.security, route: DealFlowNavigation.commerce_proofs),
      ],
    ),
    MenuCategory(
      name: 'Technique',
      icon: Icons.build,
      color: Color(0xFF00838F),
      items: [
        MenuItem(label: 'Devis Technique', icon: Icons.description, route: DealFlowNavigation.technical_quotes),
        MenuItem(label: 'Interventions', icon: Icons.assignment, route: DealFlowNavigation.technical_interventions),
        MenuItem(label: 'Maintenance', icon: Icons.settings, route: DealFlowNavigation.technical_maintenance),
        MenuItem(label: 'Factures', icon: Icons.receipt, route: DealFlowNavigation.technical_invoices),
      ],
    ),
    MenuCategory(
      name: 'Libéral',
      icon: Icons.business_center,
      color: Color(0xFF5E35B1),
      items: [
        MenuItem(label: 'Projets', icon: Icons.folder_open, route: DealFlowNavigation.liberal_projects),
        MenuItem(label: 'Contrats', icon: Icons.description, route: DealFlowNavigation.liberal_contracts),
        MenuItem(label: 'Finances', icon: Icons.trending_up, route: DealFlowNavigation.liberal_finance),
        MenuItem(label: 'Factures', icon: Icons.receipt, route: DealFlowNavigation.liberal_invoices),
      ],
    ),
  ];

  static MenuCategory getCategory(String name) {
    return allCategories.firstWhere(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      orElse: () => allCategories.first,
    );
  }
}

class MenuCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<MenuItem> items;

  const MenuCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class MenuItem {
  final String label;
  final IconData icon;
  final String route;

  const MenuItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Route generator for DealFlow navigation
class DealFlowRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Technical Module
      case DealFlowNavigation.technical_quotes:
        return MaterialPageRoute(builder: (_) => const TechnicalQuoteFormScreen());

      // Liberal Module
      case DealFlowNavigation.liberal_projects:
        return MaterialPageRoute(builder: (_) => const ProjectManagementScreen());

      case DealFlowNavigation.liberal_finance:
        return MaterialPageRoute(builder: (_) => const FinanceManagementScreen());

      // Add other routes as needed
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page not found')),
            body: const Center(child: Text('Route not found')),
          ),
        );
    }
  }
}

/// Home screen showing all modules
class DealFlowHomeScreen extends StatefulWidget {
  const DealFlowHomeScreen({super.key});

  @override
  State<DealFlowHomeScreen> createState() => _DealFlowHomeScreenState();
}

class _DealFlowHomeScreenState extends State<DealFlowHomeScreen> {
  String _selectedDomain = 'All'; // All, Commerce, Technique, Liberal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DealFlow Pro Congo'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Domain selector
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'All', label: Text('Tous')),
                  ButtonSegment(value: 'Commerce', label: Text('Commerce')),
                  ButtonSegment(value: 'Technique', label: Text('Technique')),
                  ButtonSegment(value: 'Liberal', label: Text('Libéral')),
                ],
                selected: {_selectedDomain},
                onSelectionChanged: (s) => setState(() => _selectedDomain = s.first),
              ),
            ),

            // All categories
            ...(MenuStructure.allCategories
                .where((cat) => _selectedDomain == 'All' || cat.name == _selectedDomain)
                .map((category) => _buildCategorySection(category))),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(MenuCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, color: category.color, size: 24),
              const SizedBox(width: 12),
              Text(
                category.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: category.items.length,
            itemBuilder: (ctx, i) {
              final item = category.items[i];
              return Card(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(ctx, item.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: category.color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
