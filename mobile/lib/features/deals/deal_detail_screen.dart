import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../widgets/brand.dart';
import 'deal_cubit.dart';
import 'deal_model.dart';
import 'deal_state.dart';
import 'deal_share_sheet.dart';

/// Écran de détail d'un deal — l'écran le plus important du module.
/// Affiche les stats agrégées + analytics par canal (la fameuse vue
/// "barres WhatsApp / FB / Instagram / Direct").
class DealDetailScreen extends StatefulWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DealCubit>().loadDetail(widget.dealId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      body: BlocBuilder<DealCubit, DealState>(
        builder: (context, state) {
          return switch (state) {
            DealInitial() ||
            DealLoading() =>
              const Center(child: CircularProgressIndicator()),
            DealError(:final message) => _ErrorView(
                message: message,
                onBack: () => Navigator.of(context).pop(),
              ),
            DealDetailLoaded() => _DetailBody(
                detail: state.detail,
                analytics: state.analytics,
              ),
            DealListsLoaded() => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final DealDetail detail;
  final DealAnalytics analytics;
  const _DetailBody({required this.detail, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(detail: detail),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<DealCubit>().refreshDetail(detail.id),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                _StatsRow(analytics: analytics),
                const SizedBox(height: 10),
                _ChannelChart(analytics: analytics),
                const SizedBox(height: 10),
                if (analytics.myShareCode != null)
                  _MyLinkCard(code: analytics.myShareCode!),
                const SizedBox(height: 10),
                _ShareActions(detail: detail),
                if (detail.description != null &&
                    detail.description!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DescriptionCard(detail: detail),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top bar avec titre du deal + commission ─────────────────────────────────
class _Header extends StatelessWidget {
  final DealDetail detail;
  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DealFlowBrand.green900,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${detail.commissionType} · ${detail.commissionLabel}'
                      '${detail.commissionType == 'CPA' ? ' / vente' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3 mini-stats en haut ────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final DealAnalytics analytics;
  const _StatsRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('fr_FR');
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Clics',
            value: '${analytics.totalClicks}',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _StatCard(
            label: 'Conversions',
            value: '${analytics.totalConversions}',
            valueColor: const Color(0xFF0F6E56),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _StatCard(
            label: 'Gains',
            value: fmt.format(analytics.totalEarned.round()),
            valueColor: DealFlowBrand.green900,
            small: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool small;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 14 : 17,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Graphique horizontal par canal (le cœur du mockup 4) ────────────────────
class _ChannelChart extends StatelessWidget {
  final DealAnalytics analytics;
  const _ChannelChart({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final channels = analytics.byChannel;
    if (channels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(Icons.share_outlined,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Tu n\'as pas encore partagé ce deal.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    final maxClicks =
        channels.map((c) => c.clicks).reduce((a, b) => a > b ? a : b);

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
            'Performance par canal',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 11),
          for (final ch in channels) ...[
            _ChannelRow(channel: ch, maxClicks: maxClicks),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final ChannelMetrics channel;
  final int maxClicks;

  const _ChannelRow({required this.channel, required this.maxClicks});

  @override
  Widget build(BuildContext context) {
    final p = _channelPalette(channel.channel);
    final ratio = maxClicks > 0 ? channel.clicks / maxClicks : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(p.icon, size: 14, color: p.fg),
            const SizedBox(width: 6),
            Text(
              p.label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${channel.clicks} clic${channel.clicks > 1 ? 's' : ''}'
              ' · ${channel.sales} vente${channel.sales > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio.clamp(0.04, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: p.fg,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Carte "Mon lien de partage" (avec copie) ────────────────────────────────
class _MyLinkCard extends StatelessWidget {
  final String code;
  const _MyLinkCard({required this.code});

  @override
  Widget build(BuildContext context) {
    final url = 'https://dealflow.app/d/$code';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF04342C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon lien de partage',
            style: TextStyle(
                fontSize: 10.5, color: Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lien copié dans le presse-papier'),
                      backgroundColor: DealFlowBrand.green700,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child:
                    const Icon(Icons.copy, color: Color(0xFF9FE1CB), size: 17),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Boutons d'action (partager sur WhatsApp / autre canal) ──────────────────
class _ShareActions extends StatelessWidget {
  final DealDetail detail;
  const _ShareActions({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F6E56),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.chat, size: 14),
            label: const Text('WhatsApp',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: () => showDealShareSheet(
              context: context,
              dealId: detail.id,
              dealTitle: detail.title,
              preselectedChannel: 'WhatsApp',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.share, size: 14),
            label: const Text('Autre canal',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: () => showDealShareSheet(
              context: context,
              dealId: detail.id,
              dealTitle: detail.title,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bloc description / conditions ───────────────────────────────────────────
class _DescriptionCard extends StatelessWidget {
  final DealDetail detail;
  const _DescriptionCard({required this.detail});

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
          const Text(
            'Description',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            detail.description ?? '',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          if (detail.conditions != null && detail.conditions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Conditions pour gagner',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              detail.conditions!,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: const Text('Retour')),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers palette par canal ───────────────────────────────────────────────
class _ChannelPalette {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
  const _ChannelPalette(
      {required this.bg,
      required this.fg,
      required this.icon,
      required this.label});
}

_ChannelPalette _channelPalette(String channel) {
  switch (channel) {
    case 'WhatsApp':
      return const _ChannelPalette(
          bg: Color(0xFFE1F5EE),
          fg: Color(0xFF0F6E56),
          icon: Icons.chat,
          label: 'WhatsApp');
    case 'Facebook':
      return const _ChannelPalette(
          bg: Color(0xFFE6F1FB),
          fg: Color(0xFF185FA5),
          icon: Icons.facebook,
          label: 'Facebook');
    case 'Instagram':
      return const _ChannelPalette(
          bg: Color(0xFFFBEAF0),
          fg: Color(0xFF993556),
          icon: Icons.camera_alt_outlined,
          label: 'Instagram');
    case 'Own':
      return const _ChannelPalette(
          bg: Color(0xFFEEEDFE),
          fg: Color(0xFF534AB7),
          icon: Icons.account_circle_outlined,
          label: 'Mon compte');
  }
  return const _ChannelPalette(
      bg: Color(0xFFF1EFE8),
      fg: Color(0xFF444441),
      icon: Icons.link,
      label: 'Lien direct');
}
