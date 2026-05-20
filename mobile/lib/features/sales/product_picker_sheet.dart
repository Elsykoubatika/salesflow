import 'dart:async';
import 'package:flutter/material.dart';

import '../catalog/catalog_api.dart';
import '../catalog/format_money.dart';
import '../catalog/product_model.dart';

/// Bottom sheet pour choisir un produit du catalogue (actifs uniquement).
Future<Product?> pickProduct(BuildContext context) async {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => _ProductPickerSheet(scrollController: scrollController),
    ),
  );
}

class _ProductPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _ProductPickerSheet({required this.scrollController});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _api = CatalogApi();
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  List<Product> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.list(search: search, activeOnly: true, pageSize: 100);
      if (mounted) {
        setState(() {
        _products = response.items;
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(search: value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Sélectionner un produit', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _products.isEmpty
                        ? const Center(child: Text('Aucun produit actif.'))
                        : ListView.separated(
                            controller: widget.scrollController,
                            itemCount: _products.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = _products[index];
                              return ListTile(
                                title: Text(p.name),
                                subtitle: Text(formatMoney(p.price, p.currency)),
                                onTap: () => Navigator.pop(context, p),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
