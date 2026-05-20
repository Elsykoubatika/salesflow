import 'package:flutter/material.dart';

import '../sales/sales_api.dart';
import '../sales/sales_order_model.dart';
import '../sales/status_visual.dart';
import '../catalog/format_money.dart';

/// Bottom sheet pour choisir un devis/commande existant.
/// Retourne un [SalesOrderListItemDto] ou null si annulé.
Future<SalesOrderListItemDto?> pickSalesOrder(BuildContext context) async {
  return showModalBottomSheet<SalesOrderListItemDto>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => _SalesOrderPickerSheet(scrollController: scrollCtrl),
    ),
  );
}

class _SalesOrderPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _SalesOrderPickerSheet({required this.scrollController});

  @override
  State<_SalesOrderPickerSheet> createState() => _SalesOrderPickerSheetState();
}

class _SalesOrderPickerSheetState extends State<_SalesOrderPickerSheet> {
  final SalesApi _api = SalesApi();
  bool _loading = true;
  String? _error;
  List<SalesOrderListItemDto> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _api.list(pageSize: 50);
      if (!mounted) return;
      setState(() {
        _orders = response.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choisir un devis/commande',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Aucun devis disponible'));
    }
    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final o = _orders[i];
        final theme = Theme.of(context);
        return ListTile(
          title: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${o.clientName} · ${formatMoney(o.total, o.currency)}',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: StatusBadge(status: o.status, compact: true),
          onTap: () => Navigator.pop(context, o),
        );
      },
    );
  }
}
