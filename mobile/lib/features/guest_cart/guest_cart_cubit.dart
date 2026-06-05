import 'package:flutter_bloc/flutter_bloc.dart';
import '../public_catalog/public_catalog_model.dart';

/// État du panier invité — entièrement en mémoire jusqu'à la validation.
class GuestCartState {
  final List<GuestCartItem> items;
  const GuestCartState(this.items);

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get total =>
      items.fold(0.0, (sum, i) => sum + i.product.price * i.quantity);

  String get currency =>
      items.isNotEmpty ? items.first.product.currency : 'XAF';

  bool get isEmpty => items.isEmpty;
}

/// Panier invité : ajouter, retirer, vider.
///
/// Note : pas persisté entre les sessions. Pour la v1 c'est OK (un visiteur
/// vient, met dans le panier, commande dans la foulée). Pour la v2 on
/// pourrait le sauver en SharedPreferences.
class GuestCartCubit extends Cubit<GuestCartState> {
  GuestCartCubit() : super(const GuestCartState([]));

  void add(PublicProductSummary product, {int quantity = 1}) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + quantity);
    } else {
      items.add(GuestCartItem(product: product, quantity: quantity));
    }
    emit(GuestCartState(items));
  }

  void increment(String productId) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      emit(GuestCartState(items));
    }
  }

  void decrement(String productId) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (items[idx].quantity <= 1) {
      items.removeAt(idx);
    } else {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity - 1);
    }
    emit(GuestCartState(items));
  }

  void remove(String productId) {
    final items = [...state.items]..removeWhere((i) => i.product.id == productId);
    emit(GuestCartState(items));
  }

  void clear() => emit(const GuestCartState([]));
}
