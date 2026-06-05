import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_api.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardApi _api;
  DashboardCubit(this._api) : super(const DashboardInitial());

  /// Charge l'aperçu complet du dashboard.
  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final overview = await _api.getOverview();
      emit(DashboardLoaded(overview));
    } catch (e) {
      emit(DashboardError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Rafraîchit silencieusement (pour le pull-to-refresh).
  Future<void> refresh() async {
    try {
      final overview = await _api.getOverview();
      emit(DashboardLoaded(overview));
    } catch (e) {
      emit(DashboardError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
