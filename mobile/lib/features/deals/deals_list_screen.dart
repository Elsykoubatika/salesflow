import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../widgets/brand.dart';
import 'deal_cubit.dart';
import 'deal_model.dart';
import 'deal_state.dart';
import 'deal_detail_screen.dart';
import 'deal_creation_screen.dart';
import 'deal_share_sheet.dart';

/// Écran principal du module Deal — 3 onglets :
///   Disponibles · Mes deals · Mes gains
class DealsListScreen extends StatefulWidget {
  const DealsListScreen({super.key});

  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DealCubit>().loadLists();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      body: Column(
        children: [
          _Header(tabController: _tabCtrl),
          Expanded(
            child: BlocBuilder<DealCubit, DealState>(
              builder: (context, state) {
                return switch (state) {
                  DealInitial() ||
                  DealLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  DealError(:final message) => _ErrorView(
                      message: message,
                      onRetry: () => context.read<DealCubit>().loadLists(),
                    ),
                  DealListsLoaded() => TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _AvailableTab(items: state.available),
                        _MineTab(items: state.mine),
                        _EarningsTab(earnings: state.earnings),
                      ],
                    ),
                  DealDetailLoaded() =>
                    const SizedBox.shrink(), // pas atteignable ici
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar émeraude avec les 3 onglets ─────────────────────────────────────
class _Header extends StatelessWidget {
  final TabController tabController;
  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DealFlowBrand.green900,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Programme d\'affiliation',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        const Text(
                          'Deals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const DealCreationScreen(),
                        ),
                      );
                      if (created == true && context.mounted) {
                        context.read<DealCubit>().refreshLists();
                      }
                    },
                  ),
                ],
              ),
            ),
            TabBar(
              controller: tabController,
              indicatorColor: const Color(0xFF1f9d6b),
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: 'Disponibles'),
                Tab(text: 'Mes deals'),
                Tab(text: 'Mes gains'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onglet 1 : Disponibles (deals des autres à partager) ────────────────────
class _AvailableTab extends StatelessWidget {
  final List<DealListItem> items;
  const _AvailableTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyView(message: 'Aucun deal disponible pour le moment.');
    return RefreshIndicator(
      onRefresh: () => context.read<DealCubit>().refreshLists(),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _DealCard(
          item: items[i],
          showShareButton: true,
        ),
      ),
    );
  }
}

// ─── Onglet 2 : Mes deals (que j'ai créés) ───────────────────────────────────
class _MineTab extends StatelessWidget {
  final List<DealListItem> items;
  const _MineTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyView(
        message: 'Vous n\'avez pas encore créé de deal.',
        actionLabel: 'Créer mon premier deal',
        onAction: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const DealCreationScreen()),
          );
          if (created == true && context.mounted) {
            context.read<DealCubit>().refreshLists();
          }
        },
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<DealCubit>().refreshLists(),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _DealCard(
          item: items[i],
          showShareButton: false,
        ),
      ),
    );
  }
}

// ─── Onglet 3 : Mes gains ────────────────────────────────────────────────────
class _EarningsTab extends StatelessWidget {
  final MyEarnings earnings;
  const _EarningsTab({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('fr_FR');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF04342C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total gagné',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      fmt.format(earnings.totalEarned.round()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      earnings.currency,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniStatCard(label: 'Clics totaux', value: '${earnings.totalClicks}')),
              const SizedBox(width: 8),
              Expanded(child: _MiniStatCard(label: 'Ventes', value: '${earnings.totalSales}')),
              const SizedBox(width: 8),
              Expanded(child: _MiniStatCard(label: 'Liens actifs', value: '${earnings.activeShares}')),
            ],
          ),
          const SizedBox(height: 14),
          if (earnings.activeShares == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.rocket_launch_outlined,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'Aucun lien partagé pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Va dans "Disponibles" et partage un deal pour gagner tes premières commissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ─── Carte d'un deal (utilisée dans les 2 premiers onglets) ──────────────────
class _DealCard extends StatelessWidget {
  final DealListItem item;
  final bool showShareButton;
  const _DealCard({required this.item, required this.showShareButton});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DealDetailScreen(dealId: item.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _categoryIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'par ${item.creatorName}'
                          '${item.activeTo != null ? ' · ${_daysLeft(item.activeTo!)}' : ''}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _CommissionBadge(type: item.commissionType),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.commissionLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DealFlowBrand.green900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.affiliateCount} affilié${item.affiliateCount > 1 ? 's' : ''}'
                      ' · ${item.saleCount} vente${item.saleCount > 1 ? 's' : ''}',
                      style:
                          TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ),
                  if (showShareButton)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: DealFlowBrand.green900,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 6),
                        textStyle: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      icon: const Icon(Icons.share, size: 12),
                      label: const Text('Partager'),
                      onPressed: () => showDealShareSheet(
                        context: context,
                        dealId: item.id,
                        dealTitle: item.title,
                      ),
                    )
                  else
                    _StatusChip(status: item.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon() {
    // Couleur d'arrière-plan déduite du type de commission
    final palette = _commissionColors(item.commissionType);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.local_offer_outlined, size: 26, color: palette.fg),
    );
  }

  String _daysLeft(DateTime end) {
    final days = end.difference(DateTime.now()).inDays;
    if (days < 0) return 'expiré';
    if (days == 0) return 'expire aujourd\'hui';
    return '$days j restants';
  }
}

class _CommissionBadge extends StatelessWidget {
  final String type;
  const _CommissionBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final p = _commissionColors(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'Active' => (const Color(0xFFE1F5EE), const Color(0xFF04342C), 'Actif'),
      'Paused' => (const Color(0xFFFAEEDA), const Color(0xFF412402), 'En pause'),
      'Closed' => (const Color(0xFFF1EFE8), const Color(0xFF444441), 'Clôturé'),
      _ => (const Color(0xFFF1EFE8), const Color(0xFF444441), status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyView({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: DealFlowBrand.green900),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 42),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: DealFlowBrand.green900),
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers couleurs commission ─────────────────────────────────────────────
class _ColorPair {
  final Color bg;
  final Color fg;
  const _ColorPair(this.bg, this.fg);
}

_ColorPair _commissionColors(String type) {
  switch (type) {
    case 'CPC':
      return const _ColorPair(Color(0xFFE6F1FB), Color(0xFF0C447C));
    case 'CPS':
      return const _ColorPair(Color(0xFFEEEDFE), Color(0xFF26215C));
    case 'CPA':
      return const _ColorPair(Color(0xFFE1F5EE), Color(0xFF04342C));
    case 'CPL':
      return const _ColorPair(Color(0xFFFAEEDA), Color(0xFF412402));
  }
  return const _ColorPair(Color(0xFFF1EFE8), Color(0xFF444441));
}
