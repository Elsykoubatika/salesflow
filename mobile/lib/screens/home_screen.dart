import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../features/catalog/catalog_list_screen.dart';
import '../features/clients/clients_list_screen.dart';
import '../features/inventory/inventory_list_screen.dart';
import '../features/proofs/proofs_list_screen.dart';
import '../features/sales/sales_list_screen.dart';
import '../theme.dart';

// ─── Modules Technique & Libéral ─────────────────────────────────────────────
import '../features/technical/technical_quote_form.dart';
import '../features/technical/technical_invoice_screen.dart';
import '../features/technical/technical_intervention_screen.dart';
import '../features/technical/technical_maintenance_screen.dart';
import '../features/liberal/liberal_pipeline_screen.dart';
import '../features/liberal/liberal_contracts_screen.dart';
import '../features/liberal/project_management_screen.dart';
import '../features/liberal/finance_management_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          backgroundColor: AppTheme.warmBackground,
          body: CustomScrollView(
            slivers: [
              // ─── Hero header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  user: state.user,
                  onLogout: () => _confirmLogout(context),
                ),
              ),

              // ─── COMMERCE ───────────────────────────────────────────────
              _SectionHeader(label: 'Commerce'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _ModuleTile(
                      icon: Icons.people_rounded,
                      title: 'Clients',
                      subtitle: 'Carnet d\'adresses',
                      color: AppTheme.moduleClients,
                      onTap: () => _push(context, const ClientsListScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.shopping_bag_rounded,
                      title: 'Catalogue',
                      subtitle: 'Produits & WhatsApp',
                      color: AppTheme.moduleCatalog,
                      onTap: () => _push(context, const CatalogListScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Commandes',
                      subtitle: 'Pipeline de vente',
                      color: AppTheme.moduleSales,
                      onTap: () => _push(context, const SalesListScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.inventory_2_rounded,
                      title: 'Stock',
                      subtitle: 'Inventaire & alertes',
                      color: AppTheme.moduleStock,
                      onTap: () => _push(context, const InventoryListScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.lock_rounded,
                      title: 'Coffre-Fort',
                      subtitle: 'Preuves Mobile Money',
                      color: AppTheme.moduleProofs,
                      onTap: () => _push(context, const ProofsListScreen()),
                    ),
                  ],
                ),
              ),

              // ─── TECHNIQUE ──────────────────────────────────────────────
              _SectionHeader(label: 'Technique'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _ModuleTile(
                      icon: Icons.calculate_rounded,
                      title: 'Devis Tech',
                      subtitle: 'Calculs intelligents',
                      color: const Color(0xFF00838F),
                      onTap: () => _push(context, const TechnicalQuoteFormScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.build_rounded,
                      title: 'Interventions',
                      subtitle: 'Traçage chantier',
                      color: const Color(0xFF00695C),
                      onTap: () =>
                          _push(context, const TechnicalInterventionsScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.checklist_rounded,
                      title: 'Maintenance',
                      subtitle: 'Checklist appareil',
                      color: const Color(0xFF2E7D32),
                      onTap: () =>
                          _push(context, const TechnicalMaintenanceScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.description_rounded,
                      title: 'Factures Tech',
                      subtitle: 'Durée × Tarif + Matériaux',
                      color: const Color(0xFF0D6B4F),
                      onTap: () => _push(context, const TechnicalInvoiceScreen()),
                    ),
                  ],
                ),
              ),

              // ─── LIBÉRAL ────────────────────────────────────────────────
              _SectionHeader(label: 'Libéral'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _ModuleTile(
                      icon: Icons.trending_up_rounded,
                      title: 'Pipeline',
                      subtitle: 'Prospects → Contrats',
                      color: const Color(0xFF5E35B1),
                      onTap: () => _push(context, const LiberalPipelineScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.handshake_rounded,
                      title: 'Contrats',
                      subtitle: 'Honoraires & Récurrence',
                      color: const Color(0xFF4527A0),
                      onTap: () =>
                          _push(context, const LiberalContractsScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.folder_special_rounded,
                      title: 'Projets',
                      subtitle: 'Gestion A-Z + PDF',
                      color: const Color(0xFF6A1B9A),
                      onTap: () => _push(context, const ProjectManagementScreen()),
                    ),
                    _ModuleTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Finances',
                      subtitle: 'Perso & Famille',
                      color: const Color(0xFF7B1FA2),
                      onTap: () => _push(context, const FinanceManagementScreen()),
                    ),
                  ],
                ),
              ),

              // ─── Footer ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'DealFlow Pro · v1.0',
                      style: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _comingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$module — Connectez le backend pour activer'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez ressaisir votre mot de passe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback onLogout;

  const _HeroHeader({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073D2C), Color(0xFF0D6B4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + Logout
              Row(
                children: [
                  // Logo DealFlow (handshake SVG)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: CustomPaint(
                      painter: _DealFlowLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DealFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.logout_rounded,
                        color: Colors.white.withValues(alpha: 0.8), size: 22),
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Bonjour,',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alternate_email,
                        size: 12, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }
}

// ─── Module Tile ──────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, Color.lerp(color, Colors.black, 0.25)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DealFlow Logo Painter (Handshake + Arrow) ────────────────────────────────

class _DealFlowLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Main handshake line
    canvas.drawLine(Offset(cx - 8, cy + 2), Offset(cx + 8, cy + 2), paint);

    // Left arm up
    canvas.drawLine(Offset(cx - 8, cy + 2), Offset(cx - 12, cy - 3), paint);
    // Right arm up
    canvas.drawLine(Offset(cx + 8, cy + 2), Offset(cx + 12, cy - 3), paint);

    // Left finger
    canvas.drawLine(Offset(cx - 12, cy - 3), Offset(cx - 5, cy - 5), paint);
    // Right finger
    canvas.drawLine(Offset(cx + 12, cy - 3), Offset(cx + 5, cy - 5), paint);

    // Center connection dot
    canvas.drawCircle(Offset(cx, cy - 1), 2.5, fillPaint);

    // Arrow up-right
    canvas.drawLine(Offset(cx + 9, cy - 5), Offset(cx + 14, cy - 10), paint);
    // Arrow head
    canvas.drawLine(Offset(cx + 14, cy - 10), Offset(cx + 11, cy - 10), paint);
    canvas.drawLine(Offset(cx + 14, cy - 10), Offset(cx + 14, cy - 7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
