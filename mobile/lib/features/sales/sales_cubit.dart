import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sales_api.dart';
import 'sales_order_model.dart';

abstract class SalesState extends Equatable {
  const SalesState();
  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState { const SalesInitial(); }
class SalesLoading extends SalesState { const SalesLoading(); }

class SalesLoaded extends SalesState {
  final List<SalesOrderListItemDto> items;
  final int total;
  final SalesOrderStatus? statusFilter;

  const SalesLoaded({required this.items, required this.total, this.statusFilter});

  @override
  List<Object?> get props => [items, total, statusFilter];
}

class SalesError extends SalesState {
  final String message;
  const SalesError(this.message);

  @override
  List<Object?> get props => [message];
}

class SalesCubit extends Cubit<SalesState> {
  SalesCubit({SalesApi? api}) : _api = api ?? SalesApi(), super(const SalesInitial());

  final SalesApi _api;
  SalesOrderStatus? _statusFilter;

  Future<void> load() async {
    emit(const SalesLoading());
    try {
      final response = await _api.list(status: _statusFilter);
      emit(SalesLoaded(items: response.items, total: response.total, statusFilter: _statusFilter));
    } catch (e) {
      emit(SalesError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> setStatusFilter(SalesOrderStatus? status) async {
    _statusFilter = status;
    await load();
  }

  Future<void> refresh() => load();
}
