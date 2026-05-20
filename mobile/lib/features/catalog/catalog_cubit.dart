import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'catalog_api.dart';
import 'product_model.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState { const CatalogInitial(); }

class CatalogLoading extends CatalogState { const CatalogLoading(); }

class CatalogLoaded extends CatalogState {
  final List<Product> items;
  final int total;
  final String? activeSearch;
  final bool activeOnly;

  const CatalogLoaded({
    required this.items,
    required this.total,
    this.activeSearch,
    this.activeOnly = true,
  });

  @override
  List<Object?> get props => [items, total, activeSearch, activeOnly];

  CatalogLoaded copyWith({
    List<Product>? items,
    int? total,
    String? activeSearch,
    bool? activeOnly,
  }) {
    return CatalogLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      activeSearch: activeSearch ?? this.activeSearch,
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }
}

class CatalogError extends CatalogState {
  final String message;
  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit({CatalogApi? api}) : _api = api ?? CatalogApi(), super(const CatalogInitial());

  final CatalogApi _api;
  Timer? _searchDebounce;
  bool _activeOnly = true;

  Future<void> load({String? search}) async {
    emit(const CatalogLoading());
    try {
      final response = await _api.list(search: search, activeOnly: _activeOnly);
      emit(CatalogLoaded(
        items: response.items,
        total: response.total,
        activeSearch: search,
        activeOnly: _activeOnly,
      ));
    } catch (e) {
      emit(CatalogError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      load(search: query.isEmpty ? null : query);
    });
  }

  /// Bascule entre "afficher uniquement les actifs" et "tout afficher".
  Future<void> toggleActiveOnly() async {
    _activeOnly = !_activeOnly;
    final currentSearch = state is CatalogLoaded ? (state as CatalogLoaded).activeSearch : null;
    await load(search: currentSearch);
  }

  Future<void> refresh() async {
    final currentSearch = state is CatalogLoaded ? (state as CatalogLoaded).activeSearch : null;
    await load(search: currentSearch);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
