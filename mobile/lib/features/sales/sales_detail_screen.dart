import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../catalog/format_money.dart';
import 'pdf_helper.dart';
import 'sales_api.dart';
import 'sales_order_model.dart';
import 'status_visual.dart';

class SalesDetailScreen extends StatefulWidget {
  final String orderId;
  const SalesDetailScreen({super.key, required this.orderId});

  @override
  State<SalesDetailScreen> createState() => _SalesDetailScreenState();
}

class _SalesDetailScreenState extends State<SalesDetailScreen> {
  final _api = SalesApi();
  final _pdfHelper = PdfHelper();

  bool _loading = true;
  bool _busy = false;
  SalesOrder? _order;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await _api.getById(widget.orderId);
      if (mounted) {
        setState(() {
        _order = order;
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _doTransition(SalesOrderStatus target) async {
    final needsReason = target == SalesOrderStatus.cancelled || target == SalesOrderStatus.rejected;
    String? reason;
    if (needsReason) {
      reason = await _askReason(target);
      if (reason == null) return;
    }

    setState(() => _busy = true);
    try {
      final updated = await _api.transition(widget.orderId, target, reason: reason);
      if (mounted) {
        setState(() {
        _order = updated;
        _busy = false;
      });
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
        setState(() => _busy = false);
      }
    }
  }

  // ─── PDF ─────────────────────────────────────────────────────────────────

  Future<void> _viewPdf() async {
    if (_order == null) return;
    setState(() => _busy = true);
    try {
      final file = await _pdfHelper.downloadSalesOrderPdf(_order!.id, _order!.orderNumber);
      if (!mounted) return;
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _showError('Impossible d\'ouvrir le PDF (${result.message}). Aucune app PDF installée ?');
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_order == null) return;
    setState(() => _busy = true);
    try {
      final file = await _pdfHelper.downloadSalesOrderPdf(_order!.id, _order!.orderNumber);
      if (!mounted) return;

      final docLabel = _docLabel(_order!.status);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: '${_order!.orderNumber}.pdf')],
        subject: '$docLabel ${_order!.orderNumber}',
        text: 'Voici votre $docLabel ${_order!.orderNumber} de ${formatMoney(_order!.total, _order!.currency)}.',
      );
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _docLabel(SalesOrderStatus s) => switch (s) {
        SalesOrderStatus.draft || SalesOrderStatus.sent => 'Devis',
        SalesOrderStatus.accepted => 'Bon de commande',
        SalesOrderStatus.delivered => 'Facture',
        SalesOrderStatus.paid => 'Facture acquittée',
        _ => 'Document',
      };

  // ─── Helpers UI ──────────────────────────────────────────────────────────

  Future<String?> _askReason(SalesOrderStatus target) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(target == SalesOrderStatus.cancelled ? 'Annuler le document' : 'Marquer comme refusé'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Raison (optionnel)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order?.orderNumber ?? 'Devis'),
        actions: _order == null
            ? null
            : [
                IconButton(
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Voir le PDF',
                  onPressed: _busy ? null : _viewPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Partager le PDF',
                  onPressed: _busy ? null : _sharePdf,
                ),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.tonal(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _buildContent(_order!),
    );
  }

  Widget _buildContent(SalesOrder order) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Créé le ${dateFormat.format(order.createdAt.toLocal())}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),

          const SizedBox(height: 24),

          const _SectionLabel(text: 'CLIENT'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.person_outline),
              title: Text(order.clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 20),

          _SectionLabel(text: 'LIGNES (${order.items.length})'),
          ...order.items.map((item) => Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} × ${formatMoney(item.unitPrice, order.currency)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatMoney(item.lineTotal, order.currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    const Text('Sous-total'),
                    const Spacer(),
                    Text(formatMoney(order.subtotal, order.currency)),
                  ]),
                  if (order.taxAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Text('TVA'),
                      const Spacer(),
                      Text(formatMoney(order.taxAmount, order.currency)),
                    ]),
                  ],
                  const Divider(height: 24),
                  Row(children: [
                    Text('TOTAL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      formatMoney(order.total, order.currency),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel(text: 'NOTES'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(order.notes!),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const _SectionLabel(text: 'HISTORIQUE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimelineRow(label: 'Créé', date: order.createdAt),
                  if (order.sentAt != null) _TimelineRow(label: 'Envoyé', date: order.sentAt!),
                  if (order.acceptedAt != null) _TimelineRow(label: 'Accepté', date: order.acceptedAt!),
                  if (order.deliveredAt != null) _TimelineRow(label: 'Livré', date: order.deliveredAt!),
                  if (order.paidAt != null) _TimelineRow(label: 'Payé', date: order.paidAt!),
                  if (order.cancelledAt != null)
                    _TimelineRow(
                      label: order.status == SalesOrderStatus.rejected ? 'Refusé' : 'Annulé',
                      date: order.cancelledAt!,
                      reason: order.cancellationReason,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (order.allowedNextStatuses.isNotEmpty) ...[
            const _SectionLabel(text: 'ACTIONS'),
            for (final next in order.allowedNextStatuses) _buildTransitionButton(next),
          ],
        ],
      ),
    );
  }

  Widget _buildTransitionButton(SalesOrderStatus target) {
    final isDestructive = target == SalesOrderStatus.cancelled || target == SalesOrderStatus.rejected;
    final action = _actionLabel(target);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: isDestructive
          ? OutlinedButton.icon(
              onPressed: () => _doTransition(target),
              icon: Icon(target == SalesOrderStatus.rejected ? Icons.thumb_down_outlined : Icons.block),
              label: Text(action),
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            )
          : ElevatedButton.icon(
              onPressed: () => _doTransition(target),
              icon: Icon(_iconFor(target)),
              label: Text(action),
            ),
    );
  }

  static String _actionLabel(SalesOrderStatus target) => switch (target) {
        SalesOrderStatus.sent => 'Marquer comme envoyé',
        SalesOrderStatus.accepted => 'Marquer accepté par le client',
        SalesOrderStatus.delivered => 'Marquer livré',
        SalesOrderStatus.paid => 'Marquer payé',
        SalesOrderStatus.rejected => 'Refusé par le client',
        SalesOrderStatus.cancelled => 'Annuler ce document',
        SalesOrderStatus.draft => 'Repasser en brouillon',
      };

  static IconData _iconFor(SalesOrderStatus target) => switch (target) {
        SalesOrderStatus.sent => Icons.send_outlined,
        SalesOrderStatus.accepted => Icons.thumb_up_outlined,
        SalesOrderStatus.delivered => Icons.local_shipping_outlined,
        SalesOrderStatus.paid => Icons.check_circle_outline,
        _ => Icons.arrow_forward,
      };
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final String? reason;

  const _TimelineRow({required this.label, required this.date, this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(
                        text: '  •  ${DateFormat('dd/MM/yyyy à HH:mm').format(date.toLocal())}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (reason != null && reason!.isNotEmpty)
                  Text(reason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
