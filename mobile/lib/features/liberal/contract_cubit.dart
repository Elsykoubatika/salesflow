import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'contract_api.dart';
import 'contract_model.dart';

abstract class ContractState extends Equatable {
  const ContractState();
  @override
  List<Object?> get props => [];
}

class ContractInitial extends ContractState {
  const ContractInitial();
}

class ContractLoading extends ContractState {
  const ContractLoading();
}

class ContractLoaded extends ContractState {
  final List<ContractListItem> items;
  final int total;
  const ContractLoaded({required this.items, required this.total});
  @override
  List<Object?> get props => [items, total];
}

class ContractError extends ContractState {
  final String message;
  const ContractError(this.message);
  @override
  List<Object?> get props => [message];
}

class ContractCubit extends Cubit<ContractState> {
  ContractCubit({ContractApi? api})
      : _api = api ?? ContractApi(),
        super(const ContractInitial());

  final ContractApi _api;

  Future<void> load() async {
    emit(const ContractLoading());
    try {
      final r = await _api.list();
      emit(ContractLoaded(items: r.items, total: r.total));
    } catch (e) {
      emit(ContractError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createContract({
    required String clientId,
    required String engagementType,
    String? notes,
  }) async {
    await _api.create(
      clientId: clientId,
      engagementType: engagementType,
      notes: notes,
    );
    await load();
  }
}
