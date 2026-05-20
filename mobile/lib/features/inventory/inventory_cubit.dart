import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'inventory_api.dart';
import 'inventory_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState { const InventoryInitial(); }
class InventoryLoading extends InventoryState { const InventoryLoading(); }

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  final int total;
  final int lowStockCount;
  final String? activeSearch;
  final bool lowStockOnly;
  final bool activeOnly;

  const InventoryLoaded({
    required this.items,
    required this.total,
    required this.lowStockCount,
    this.activeSearch,
    this.lowStockOnly = false,
    this.activeOnly = true,
  });

  @override
  List<Object?> get props => [items, total, lowStockCount, activeSearch, lowStockOnly, activeOnly];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit({InventoryApi? api}) : _api = api ?? InventoryApi(), super(const InventoryInitial());

  final InventoryApi _api;
  Timer? _searchDebounce;
  bool _lowStockOnly = false;
  bool _activeOnly = true;

  Future<void> load({String? search}) async {
    emit(const InventoryLoading());
    try {
      final response = await _api.list(
        search: search,
        lowStockOnly: _lowStockOnly ? true : null,
        activeOnly: _activeOnly ? true : null,
      );
      emit(InventoryLoaded(
        items: response.items,
        total: response.total,
        lowStockCount: response.lowStockCount,
        activeSearch: search,
        lowStockOnly: _lowStockOnly,
        activeOnly: _activeOnly,
      ));
    } catch (e) {
      emit(InventoryError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      load(search: query.isEmpty ? null : query);
    });
  }

  Future<void> toggleLowStockOnly() async {
    _lowStockOnly = !_lowStockOnly;
    final s = state is InventoryLoaded ? (state as InventoryLoaded).activeSearch : null;
    await load(search: s);
  }

  Future<void> toggleActiveOnly() async {
    _activeOnly = !_activeOnly;
    final s = state is InventoryLoaded ? (state as InventoryLoaded).activeSearch : null;
    await load(search: s);
  }

  Future<void> refresh() async {
    final s = state is InventoryLoaded ? (state as InventoryLoaded).activeSearch : null;
    await load(search: s);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
