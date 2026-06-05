import 'package:flutter_bloc/flutter_bloc.dart';
import 'deal_api.dart';
import 'deal_model.dart';
import 'deal_state.dart';

class DealCubit extends Cubit<DealState> {
  final DealApi _api;
  DealCubit(this._api) : super(const DealInitial());

  // ─── Listes ──────────────────────────────────────────────────────────────

  /// Charge en parallèle les 3 onglets : Disponibles + Mes deals + Mes gains.
  Future<void> loadLists() async {
    emit(const DealLoading());
    try {
      final results = await Future.wait([
        _api.listAvailable(),
        _api.listMine(),
        _api.getMyEarnings(),
      ]);
      emit(DealListsLoaded(
        available: results[0] as List<DealListItem>,
        mine: results[1] as List<DealListItem>,
        earnings: results[2] as MyEarnings,
      ));
    } catch (e) {
      emit(DealError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshLists() => loadLists();

  // ─── Détail + analytics ──────────────────────────────────────────────────

  Future<void> loadDetail(String dealId) async {
    emit(const DealLoading());
    try {
      final results = await Future.wait([
        _api.getDetail(dealId),
        _api.getAnalytics(dealId),
      ]);
      emit(DealDetailLoaded(
        detail: results[0] as DealDetail,
        analytics: results[1] as DealAnalytics,
      ));
    } catch (e) {
      emit(DealError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshDetail(String dealId) => loadDetail(dealId);

  // ─── Création ────────────────────────────────────────────────────────────

  Future<String> createDeal({
    String? productId,
    required String title,
    String? description,
    required String commissionType,
    double? commissionAmount,
    double? commissionPercent,
    String? conditions,
    int? stockAvailable,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) {
    return _api.create(
      productId: productId,
      title: title,
      description: description,
      commissionType: commissionType,
      commissionAmount: commissionAmount,
      commissionPercent: commissionPercent,
      conditions: conditions,
      stockAvailable: stockAvailable,
      activeFrom: activeFrom,
      activeTo: activeTo,
    );
  }

  // ─── Partage ─────────────────────────────────────────────────────────────

  Future<ShareLink> createShare(String dealId, String channel) {
    return _api.createShare(dealId: dealId, channel: channel);
  }
}
