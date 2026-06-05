import 'package:flutter/material.dart';

import '../widgets/brand.dart';

// Modules Vente
import '../features/clients/clients_list_screen.dart';
import '../features/catalog/catalog_list_screen.dart';
import '../features/inventory/inventory_list_screen.dart';
import '../features/sales/sales_list_screen.dart';
import '../features/liberal/liberal_pipeline_screen.dart';
// Modules Management
import '../features/liberal/liberal_contracts_screen.dart';
import '../features/liberal/project_management_screen.dart';
import '../features/liberal/finance_management_screen.dart';

/// Écran « Menu » — 5ème onglet de la bottom nav.
///
/// Regroupe toutes les sections complètes de Vente et de Management,
/// telles que validées dans la maquette.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 6),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(label: 'Vente'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            sliver: SliverToBoxAdapter(
              child: _ModuleTilesGroup(
                tiles: [
                  _ModuleTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Clients',
                    color: DealFlowBrand.green900,
                    onTap: () => _push(context, const ClientsListScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Catalogue',
                    color: DealFlowBrand.green900,
                    onTap: () => _push(context, const CatalogListScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.warehouse_outlined,
                    label: 'Stock',
                    color: DealFlowBrand.green900,
                    onTap: () => _push(context, const InventoryListScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.assignment_outlined,
                    label: 'Commandes',
                    color: DealFlowBrand.green900,
                    onTap: () => _push(context, const SalesListScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Pipeline',
                    color: DealFlowBrand.green900,
                    onTap: () => _push(context, const LiberalPipelineScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Factures',
                    color: DealFlowBrand.green900,
                    onTap: () => _comingSoon(context, 'Factures'),
                  ),
                  _ModuleTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Livraison',
                    color: DealFlowBrand.green900,
                    onTap: () => _comingSoon(context, 'Livraison'),
                  ),
                  _ModuleTile(
                    icon: Icons.payments_outlined,
                    label: 'Paiements',
                    color: DealFlowBrand.green900,
                    onTap: () => _comingSoon(context, 'Paiements'),
                  ),
                  _ModuleTile(
                    icon: Icons.verified_outlined,
                    label: 'Preuves',
                    color: DealFlowBrand.green900,
                    onTap: () => _comingSoon(context, 'Preuves'),
                  ),
                ],
                tint: DealFlowBrand.cream,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 6),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(label: 'Management'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            sliver: SliverToBoxAdapter(
              child: _ModuleTilesGroup(
                tiles: [
                  _ModuleTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Finances',
                    color: const Color(0xFF534AB7),
                    onTap: () =>
                        _push(context, const FinanceManagementScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.handshake_outlined,
                    label: 'Contrats',
                    color: const Color(0xFF534AB7),
                    onTap: () => _push(context, const LiberalContractsScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.folder_open_rounded,
                    label: 'Projets',
                    color: const Color(0xFF534AB7),
                    onTap: () =>
                        _push(context, const ProjectManagementScreen()),
                  ),
                  _ModuleTile(
                    icon: Icons.groups_outlined,
                    label: 'Équipe vente',
                    color: const Color(0xFF534AB7),
                    onTap: () => _comingSoon(context, 'Équipe vente'),
                  ),
                  _ModuleTile(
                    icon: Icons.two_wheeler_outlined,
                    label: 'Livreurs',
                    color: const Color(0xFF534AB7),
                    onTap: () => _comingSoon(context, 'Livreurs'),
                  ),
                  _ModuleTile(
                    icon: Icons.analytics_outlined,
                    label: 'Rapports',
                    color: const Color(0xFF534AB7),
                    onTap: () => _comingSoon(context, 'Rapports'),
                  ),
                ],
                tint: const Color(0xFFEEEDFE),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: DealFlowBrand.green900,
      foregroundColor: Colors.white,
      title: const Text(
        'Menu',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _comingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name — bientôt disponible'),
        backgroundColor: DealFlowBrand.green800,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Label de section ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ─── Groupe de tuiles (Vente ou Management) ─────────────────────────────────
class _ModuleTilesGroup extends StatelessWidget {
  final List<_ModuleTile> tiles;
  final Color tint;

  const _ModuleTilesGroup({required this.tiles, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
        children: tiles.map((t) => t._build(tint)).toList(),
      ),
    );
  }
}

// ─── Tuile module ────────────────────────────────────────────────────────────
class _ModuleTile {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  Widget _build(Color tint) {
    final darkLabel = HSLColor.fromColor(color)
        .withLightness(0.18)
        .toColor(); // titre nettement plus foncé que l'icône
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: darkLabel,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
