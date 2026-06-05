import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/brand.dart';
import '../features/dashboard/dashboard_api.dart';
import '../features/dashboard/dashboard_cubit.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../api/api_client.dart';

import '../screens/menu_screen.dart';
import '../screens/catalog_tab_screen.dart';
import '../screens/deals_tab_screen.dart';
import '../screens/orders_tab_screen.dart';

/// Shell principal de l'app après connexion.
///
/// Contient la BottomNavigationBar avec 5 onglets :
/// Dashboard · Catalogue · Deals · Commandes · Menu
///
/// Chaque onglet est conservé dans un IndexedStack pour préserver son état
/// quand on bascule entre les onglets.
class MainShell extends StatefulWidget {
  final ApiClient apiClient;
  final String userInitials;
  final String? userFirstName;

  const MainShell({
    super.key,
    required this.apiClient,
    this.userInitials = 'U',
    this.userFirstName,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0 — Dashboard
          BlocProvider(
            create: (_) => DashboardCubit(DashboardApi(widget.apiClient)),
            child: DashboardScreen(
              userInitials: widget.userInitials,
              userFirstName: widget.userFirstName,
            ),
          ),
          // 1 — Catalogue
          const CatalogTabScreen(),
          // 2 — Deals
          const DealsTabScreen(),
          // 3 — Commandes
          const OrdersTabScreen(),
          // 4 — Menu (l'ancien home_screen renommé)
          const MenuScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom navigation bar — 5 onglets ───────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.pie_chart_outline_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.shopping_bag_outlined, label: 'Catalogue'),
    _NavItem(icon: Icons.rocket_launch_outlined, label: 'Deals'),
    _NavItem(icon: Icons.assignment_outlined, label: 'Commandes'),
    _NavItem(icon: Icons.menu_rounded, label: 'Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _items[i],
                    selected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? DealFlowBrand.green900 : Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
