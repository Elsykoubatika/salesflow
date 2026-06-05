import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/brand.dart';
import '../../api/api_client.dart';
import 'deal_api.dart';
import 'deal_cubit.dart';
import 'deal_model.dart';

/// Affiche le bottom sheet de sélection du canal de partage.
///
/// L'utilisateur choisit WhatsApp / Facebook / Instagram / Mon compte / Lien
/// direct. Le backend crée (ou récupère) le DealShare correspondant et
/// renvoie le lien court. On copie automatiquement + on prépare un message
/// pré-rempli.
Future<void> showDealShareSheet({
  required BuildContext context,
  required String dealId,
  required String dealTitle,
  String? preselectedChannel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DealShareSheet(
      dealId: dealId,
      dealTitle: dealTitle,
      preselectedChannel: preselectedChannel,
    ),
  );
}

class _DealShareSheet extends StatefulWidget {
  final String dealId;
  final String dealTitle;
  final String? preselectedChannel;

  const _DealShareSheet({
    required this.dealId,
    required this.dealTitle,
    this.preselectedChannel,
  });

  @override
  State<_DealShareSheet> createState() => _DealShareSheetState();
}

class _DealShareSheetState extends State<_DealShareSheet> {
  String? _generating;
  ShareLink? _result;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedChannel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generate(widget.preselectedChannel!);
      });
    }
  }

  Future<void> _generate(String channel) async {
    setState(() {
      _generating = channel;
      _result = null;
    });
    try {
      final api = DealApi(context.read<ApiClient>());
      final link = await api.createShare(
        dealId: widget.dealId,
        channel: channel,
      );
      if (!mounted) return;
      setState(() {
        _generating = null;
        _result = link;
      });
      // Copie auto dans le presse-papier
      Clipboard.setData(ClipboardData(text: link.fullUrl));
      // Rafraîchit les analytics
      if (mounted) {
        context.read<DealCubit>().refreshDetail(widget.dealId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Partager ce deal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                widget.dealTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              if (_result == null) ...[
                const Text(
                  'Choisis ton canal',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _ChannelButton(
                  channel: 'WhatsApp',
                  icon: Icons.chat,
                  color: const Color(0xFF0F6E56),
                  bg: const Color(0xFFE1F5EE),
                  loading: _generating == 'WhatsApp',
                  onTap: () => _generate('WhatsApp'),
                ),
                _ChannelButton(
                  channel: 'Facebook',
                  icon: Icons.facebook,
                  color: const Color(0xFF185FA5),
                  bg: const Color(0xFFE6F1FB),
                  loading: _generating == 'Facebook',
                  onTap: () => _generate('Facebook'),
                ),
                _ChannelButton(
                  channel: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  color: const Color(0xFF993556),
                  bg: const Color(0xFFFBEAF0),
                  loading: _generating == 'Instagram',
                  onTap: () => _generate('Instagram'),
                ),
                _ChannelButton(
                  channel: 'Mon compte (Own)',
                  icon: Icons.account_circle_outlined,
                  color: const Color(0xFF534AB7),
                  bg: const Color(0xFFEEEDFE),
                  loading: _generating == 'Own',
                  onTap: () => _generate('Own'),
                ),
                _ChannelButton(
                  channel: 'Lien direct',
                  icon: Icons.link,
                  color: const Color(0xFF444441),
                  bg: const Color(0xFFF1EFE8),
                  loading: _generating == 'Direct',
                  onTap: () => _generate('Direct'),
                ),
              ] else
                _ResultView(result: _result!),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  final String channel;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool loading;
  final VoidCallback onTap;

  const _ChannelButton({
    required this.channel,
    required this.icon,
    required this.color,
    required this.bg,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    channel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HSLColor.fromColor(color)
                          .withLightness(0.18)
                          .toColor(),
                    ),
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final ShareLink result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF0F6E56), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isNew
                      ? 'Lien généré et copié dans le presse-papier !'
                      : 'Lien récupéré (déjà existant pour ce canal)',
                  style: const TextStyle(
                    color: Color(0xFF04342C),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF04342C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Canal : ${result.channel}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                result.fullUrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copier',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.fullUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Lien copié'),
                        backgroundColor: DealFlowBrand.green700,
                        duration: Duration(seconds: 2)),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: DealFlowBrand.green900,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terminé',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
