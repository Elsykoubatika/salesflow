import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../widgets/brand.dart';
import 'dashboard_cubit.dart';
import 'dashboard_model.dart';
import 'dashboard_state.dart';

/// Écran Dashboard analytique — premier écran après connexion.
///
/// Composé de : top bar émeraude, salutation, KPIs 2×2,
/// graphique revenu 7 jours, top produits, alertes.
class DashboardScreen extends StatefulWidget {
  final String userInitials;
  final String? userFirstName;

  const DashboardScreen({
    super.key,
    this.userInitials = 'U',
    this.userFirstName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Column(
            children: [
              _DashboardHeader(
                initials: widget.userInitials,
                firstName: widget.userFirstName,
              ),
              Expanded(
                child: switch (state) {
                  DashboardInitial() ||
                  DashboardLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  DashboardError(:final message) => _ErrorView(
                      message: message,
                      onRetry: () => context.read<DashboardCubit>().load(),
                    ),
                  DashboardLoaded(:final overview) => RefreshIndicator(
                      onRefresh: () =>
                          context.read<DashboardCubit>().refresh(),
                      child: _DashboardBody(overview: overview),
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Top bar émeraude avec avatar + salutation ────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final String initials;
  final String? firstName;
  const _DashboardHeader({required this.initials, this.firstName});

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingFor(DateTime.now());
    return Container(
      color: DealFlowBrand.green900,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: DealFlowBrand.green500,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      firstName ?? 'Utilisateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const _HeaderIcon(icon: Icons.notifications_outlined),
              const SizedBox(width: 14),
              const _HeaderIcon(icon: Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }

  static String _greetingFor(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: Colors.white, size: 22);
  }
}

// ─── Corps : KPI + graphique + top produits + alertes ────────────────────────
class _DashboardBody extends StatelessWidget {
  final DashboardOverview overview;
  const _DashboardBody({required this.overview});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiGrid(overview: overview),
          const SizedBox(height: 10),
          _RevenueChart(points: overview.revenueByDay),
          const SizedBox(height: 10),
          _TopProducts(products: overview.topProducts),
          if (overview.alerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final alert in overview.alerts) _AlertBanner(alert: alert),
          ],
        ],
      ),
    );
  }
}

// ─── KPI cards 2×2 ────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final DashboardOverview overview;
  const _KpiGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.65,
      children: [
        _KpiCard(
          label: 'Ventes du jour',
          value: _formatMoney(overview.todayRevenue),
          subline: _deltaText(overview.todayDeltaPercent, 'vs hier'),
          sublineColor: _deltaColor(overview.todayDeltaPercent),
        ),
        _KpiCard(
          label: 'Commandes en cours',
          value: '${overview.inProgressOrders}',
          subline: overview.inProgressOrders > 0
              ? 'À traiter aujourd\'hui'
              : 'Aucune en attente',
          sublineColor: const Color(0xFF854F0B),
        ),
        _KpiCard(
          label: 'Revenu (mois)',
          value: _formatMoneyCompact(overview.monthRevenue),
          subline: _deltaText(overview.monthDeltaPercent, 'vs mois préc.'),
          sublineColor: _deltaColor(overview.monthDeltaPercent),
        ),
        _KpiCard(
          label: 'Clients actifs',
          value: '${overview.activeClients}',
          subline: overview.newClientsThisMonth > 0
              ? '${overview.newClientsThisMonth} nouveau${overview.newClientsThisMonth > 1 ? 'x' : ''} ce mois'
              : 'Pas de nouveau client',
          sublineColor: Colors.grey.shade700,
        ),
      ],
    );
  }

  String _deltaText(double pct, String suffix) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}% $suffix';
  }

  Color _deltaColor(double pct) =>
      pct >= 0 ? const Color(0xFF0F6E56) : const Color(0xFFA32D2D);
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subline;
  final Color sublineColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.subline,
    required this.sublineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DealFlowBrand.green900,
              height: 1.1,
            ),
          ),
          Text(
            subline,
            style: TextStyle(
              fontSize: 10.5,
              color: sublineColor,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Graphique revenu 7 derniers jours ───────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<DailyRevenuePoint> points;
  const _RevenueChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenu — 7 derniers jours',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              Text(
                'XAF',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _BarChartPainter(points: points),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points
                .map((p) => SizedBox(
                      width: 30,
                      child: Text(
                        _dayLetter(p.date),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _dayLetter(DateTime d) {
    const letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letters[(d.weekday - 1) % 7];
  }
}

class _BarChartPainter extends CustomPainter {
  final List<DailyRevenuePoint> points;
  _BarChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxValue = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return;

    final barCount = points.length;
    final barWidth = size.width / (barCount * 1.5);
    final gap = (size.width - barWidth * barCount) / (barCount + 1);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final ratio = p.amount / maxValue;
      final barHeight = (size.height - 4) * ratio;
      final x = gap + i * (barWidth + gap);
      final y = size.height - barHeight;

      // Couleur progressive : aujourd'hui est le plus foncé
      final isToday = i == points.length - 1;
      final color = isToday
          ? DealFlowBrand.green900
          : (i == points.length - 2
              ? DealFlowBrand.green600
              : (i >= points.length - 4
                  ? const Color(0xFF5DCAA5)
                  : const Color(0xFF9FE1CB)));

      final paint = Paint()..color = color;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.points != points;
}

// ─── Top produits ────────────────────────────────────────────────────────────
class _TopProducts extends StatelessWidget {
  final List<TopProductItem> products;
  const _TopProducts({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final dotColors = [
      DealFlowBrand.green900,
      DealFlowBrand.green500,
      const Color(0xFF5DCAA5),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top produits du mois',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < products.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColors[i % dotColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      products[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    products[i].salesCount > 0
                        ? '${products[i].salesCount} ventes'
                        : '—',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: DealFlowBrand.green900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Bannière d'alerte ───────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final DashboardAlert alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isWarning = alert.severity == 'warning';
    final isDanger = alert.severity == 'danger';
    final bg = isDanger
        ? const Color(0xFFFCEBEB)
        : isWarning
            ? const Color(0xFFFAEEDA)
            : const Color(0xFFE6F1FB);
    final fg = isDanger
        ? const Color(0xFF791F1F)
        : isWarning
            ? const Color(0xFF412402)
            : const Color(0xFF0C447C);
    final accent = isDanger
        ? const Color(0xFFA32D2D)
        : isWarning
            ? const Color(0xFF854F0B)
            : const Color(0xFF185FA5);

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: accent),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (alert.action.isNotEmpty)
                  Text(
                    alert.action,
                    style: TextStyle(fontSize: 10.5, color: accent),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: accent),
        ],
      ),
    );
  }
}

// ─── Erreur ──────────────────────────────────────────────────────────────────
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
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade400, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: DealFlowBrand.green800,
              ),
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers de format ───────────────────────────────────────────────────────
String _formatMoney(double v) {
  final f = NumberFormat.decimalPattern('fr_FR');
  return f.format(v.round());
}

String _formatMoneyCompact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}
