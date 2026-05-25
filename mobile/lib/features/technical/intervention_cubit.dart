import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'intervention_api.dart';
import 'intervention_model.dart';

abstract class InterventionState extends Equatable {
  const InterventionState();
  @override
  List<Object?> get props => [];
}

class InterventionInitial extends InterventionState {
  const InterventionInitial();
}

class InterventionLoading extends InterventionState {
  const InterventionLoading();
}

class InterventionLoaded extends InterventionState {
  final List<InterventionItem> items;
  final int total;
  const InterventionLoaded({required this.items, required this.total});
  @override
  List<Object?> get props => [items, total];
}

class InterventionError extends InterventionState {
  final String message;
  const InterventionError(this.message);
  @override
  List<Object?> get props => [message];
}

class InterventionCubit extends Cubit<InterventionState> {
  InterventionCubit({InterventionApi? api})
      : _api = api ?? InterventionApi(),
        super(const InterventionInitial());

  final InterventionApi _api;

  Future<void> load() async {
    emit(const InterventionLoading());
    try {
      final r = await _api.list();
      emit(InterventionLoaded(items: r.items, total: r.total));
    } catch (e) {
      emit(InterventionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createIntervention({
    required String clientId,
    String? notes,
    required DateTime startTime,
  }) async {
    await _api.create(clientId: clientId, notes: notes, startTime: startTime);
    await load();
  }
}
