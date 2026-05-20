import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'proof_model.dart';
import 'proofs_api.dart';

abstract class ProofsState extends Equatable {
  const ProofsState();
  @override
  List<Object?> get props => [];
}

class ProofsInitial extends ProofsState {
  const ProofsInitial();
}

class ProofsLoading extends ProofsState {
  const ProofsLoading();
}

class ProofsLoaded extends ProofsState {
  final List<Proof> items;
  final int total;
  final int pendingCount;
  final ProofStatus? statusFilter;

  const ProofsLoaded({
    required this.items,
    required this.total,
    required this.pendingCount,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [items, total, pendingCount, statusFilter];

  ProofsLoaded copyWith({
    List<Proof>? items,
    int? total,
    int? pendingCount,
    ProofStatus? statusFilter,
    bool clearFilter = false,
  }) {
    return ProofsLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      pendingCount: pendingCount ?? this.pendingCount,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class ProofsError extends ProofsState {
  final String message;
  const ProofsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProofsCubit extends Cubit<ProofsState> {
  ProofsCubit({ProofsApi? api}) : _api = api ?? ProofsApi(), super(const ProofsInitial());

  final ProofsApi _api;
  ProofStatus? _statusFilter;

  Future<void> load() async {
    emit(const ProofsLoading());
    try {
      final response = await _api.list(status: _statusFilter);
      emit(ProofsLoaded(
        items: response.items,
        total: response.total,
        pendingCount: response.pendingCount,
        statusFilter: _statusFilter,
      ));
    } catch (e) {
      emit(ProofsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> changeFilter(ProofStatus? status) async {
    _statusFilter = status;
    await load();
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete(id);
      await load();
    } catch (e) {
      emit(ProofsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
