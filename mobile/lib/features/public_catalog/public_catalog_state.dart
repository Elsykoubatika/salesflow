import 'package:equatable/equatable.dart';
import 'public_catalog_model.dart';

sealed class PublicCatalogState extends Equatable {
  const PublicCatalogState();
  @override
  List<Object?> get props => [];
}

class PublicCatalogInitial extends PublicCatalogState {
  const PublicCatalogInitial();
}

class PublicCatalogLoading extends PublicCatalogState {
  const PublicCatalogLoading();
}

class PublicCatalogLoaded extends PublicCatalogState {
  final List<PublicProductSummary> items;
  final List<CategoryItem> categories;
  final String selectedCategory;
  final String query;
  final int page;
  final int total;
  final bool hasMore;
  final bool loadingMore;

  const PublicCatalogLoaded({
    required this.items,
    required this.categories,
    required this.selectedCategory,
    required this.query,
    required this.page,
    required this.total,
    required this.hasMore,
    this.loadingMore = false,
  });

  PublicCatalogLoaded copyWith({
    List<PublicProductSummary>? items,
    List<CategoryItem>? categories,
    String? selectedCategory,
    String? query,
    int? page,
    int? total,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return PublicCatalogLoaded(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      query: query ?? this.query,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  List<Object?> get props => [
        items, categories, selectedCategory, query, page, hasMore, loadingMore,
      ];
}

class PublicCatalogError extends PublicCatalogState {
  final String message;
  const PublicCatalogError(this.message);
  @override
  List<Object?> get props => [message];
}
