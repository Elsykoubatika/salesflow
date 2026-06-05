import 'package:equatable/equatable.dart';
import 'deal_model.dart';

sealed class DealState extends Equatable {
  const DealState();
  @override
  List<Object?> get props => [];
}

class DealInitial extends DealState {
  const DealInitial();
}

class DealLoading extends DealState {
  const DealLoading();
}

/// Onglets de la liste : Disponibles · Mes deals · Mes gains
class DealListsLoaded extends DealState {
  final List<DealListItem> available;
  final List<DealListItem> mine;
  final MyEarnings earnings;

  const DealListsLoaded({
    required this.available,
    required this.mine,
    required this.earnings,
  });

  @override
  List<Object?> get props => [available, mine, earnings];
}

class DealDetailLoaded extends DealState {
  final DealDetail detail;
  final DealAnalytics analytics;
  const DealDetailLoaded({required this.detail, required this.analytics});
  @override
  List<Object?> get props => [detail, analytics];
}

class DealError extends DealState {
  final String message;
  const DealError(this.message);
  @override
  List<Object?> get props => [message];
}
