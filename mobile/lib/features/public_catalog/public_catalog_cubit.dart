import 'package:flutter_bloc/flutter_bloc.dart';
import 'public_catalog_api.dart';
import 'public_catalog_state.dart';

class PublicCatalogCubit extends Cubit<PublicCatalogState> {
  final PublicCatalogApi _api;
  PublicCatalogCubit(this._api) : super(const PublicCatalogInitial());

  /// Chargement initial : catégories + première page.
  Future<void> loadInitial() async {
    emit(const PublicCatalogLoading());
    try {
      final categories = await _api.getCategories();
      final page = await _api.list();
      emit(PublicCatalogLoaded(
        items: page.items,
        categories: categories,
        selectedCategory: 'all',
        query: '',
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ));
    } catch (e) {
      emit(PublicCatalogError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Changement de filtre (catégorie ou recherche).
  Future<void> filter({String? category, String? query}) async {
    final current = state;
    if (current is! PublicCatalogLoaded) return;

    emit(current.copyWith(
      selectedCategory: category ?? current.selectedCategory,
      query: query ?? current.query,
      loadingMore: true,
    ));

    try {
      final page = await _api.list(
        category: category ?? current.selectedCategory,
        query: query ?? current.query,
        page: 1,
      );
      emit(PublicCatalogLoaded(
        items: page.items,
        categories: current.categories,
        selectedCategory: category ?? current.selectedCategory,
        query: query ?? current.query,
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      emit(PublicCatalogError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Charger la page suivante (scroll infini).
  Future<void> loadMore() async {
    final current = state;
    if (current is! PublicCatalogLoaded) return;
    if (!current.hasMore || current.loadingMore) return;

    emit(current.copyWith(loadingMore: true));
    try {
      final next = await _api.list(
        category: current.selectedCategory,
        query: current.query,
        page: current.page + 1,
      );
      emit(current.copyWith(
        items: [...current.items, ...next.items],
        page: next.page,
        hasMore: next.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() => filter();
}
