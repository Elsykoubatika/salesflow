import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../catalog/format_money.dart';
import 'adjust_inventory_sheet.dart';
import 'inventory_api.dart';
import 'inventory_form_screen.dart';
import 'inventory_model.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String itemId;
  const InventoryDetailScreen({super.key, required this.itemId});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _api = InventoryApi();
  bool _loading = true;
  String? _error;
  InventoryItemDetail? _detail;

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
      final detail = await _api.getById(widget.itemId);
      if (mounted) {
        setState(() {
        _detail = detail;
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

  Future<void> _onAdjust() async {
    if (_detail == null) return;
    final result = await showAdjustStockSheet(context, _detail!.item);
    if (result == true) _load();
  }

  Future<void> _onEdit() async {
    if (_detail == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => InventoryFormScreen(item: _detail!.item)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.item.name ?? 'Article'),
        actions: _detail != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _onEdit,
                  tooltip: 'Modifier',
                ),
              ]
            : null,
      ),
      floatingActionButton: _detail != null && _detail!.item.isActive
          ? FloatingActionButton.extended(
              onPressed: _onAdjust,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Ajuster'),
            )
          : null,
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
              : _buildContent(_detail!),
    );
  }

  Widget _buildContent(InventoryItemDetail detail) {
    final theme = Theme.of(context);
    final item = detail.item;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Carte principale : quantité + statut
        Card(
          color: item.isLowStock
              ? const Color(0xFFFFF4E5)
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (item.isLowStock)
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text(
                        'STOCK SOUS LE SEUIL D\'ALERTE',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatQty(item.quantity),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        item.unit,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (item.reorderThreshold != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Seuil',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            Text(
                              '${_formatQty(item.reorderThreshold!)} ${item.unit}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (item.cost != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Text('Coût unitaire', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      Text(formatMoney(item.cost!, 'XAF')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Valeur du stock',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        formatMoney(item.stockValue ?? 0, 'XAF'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Infos diverses
        if (item.sku != null && item.sku!.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('SKU'),
              subtitle: Text(item.sku!),
            ),
          ),
        if (item.description != null && item.description!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DESCRIPTION',
                      style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(item.description!),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MOUVEMENTS RÉCENTS',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5),
          ),
        ),
        if (detail.recentMovements.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Aucun mouvement enregistré.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final m in detail.recentMovements)
            _MovementTile(movement: m, unit: item.unit),
      ],
    );
  }

  static String _formatQty(num n) {
    if (n == n.truncate()) return n.toInt().toString();
    return n.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

class _MovementTile extends StatelessWidget {
  final InventoryMovement movement;
  final String unit;
  const _MovementTile({required this.movement, required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = movement.change > 0;
    final color = isPositive ? Colors.green[700]! : Colors.red[700]!;
    final sign = isPositive ? '+' : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              radius: 18,
              child: Icon(isPositive ? Icons.add : Icons.remove, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movement.reason.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(movement.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (movement.note != null && movement.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        movement.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${movement.change} $unit',
                  style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  'reste : ${movement.resultingQuantity}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
