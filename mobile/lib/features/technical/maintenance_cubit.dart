import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'maintenance_api.dart';
import 'maintenance_model.dart';

abstract class MaintenanceState extends Equatable {
  const MaintenanceState();
  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {
  const MaintenanceInitial();
}

class MaintenanceLoading extends MaintenanceState {
  const MaintenanceLoading();
}

class MaintenanceLoaded extends MaintenanceState {
  final List<MaintenanceListItem> items;
  final int total;
  const MaintenanceLoaded({required this.items, required this.total});
  @override
  List<Object?> get props => [items, total];
}

class MaintenanceError extends MaintenanceState {
  final String message;
  const MaintenanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class MaintenanceCubit extends Cubit<MaintenanceState> {
  MaintenanceCubit({MaintenanceApi? api})
      : _api = api ?? MaintenanceApi(),
        super(const MaintenanceInitial());

  final MaintenanceApi _api;

  Future<void> load() async {
    emit(const MaintenanceLoading());
    try {
      final r = await _api.list();
      emit(MaintenanceLoaded(items: r.items, total: r.total));
    } catch (e) {
      emit(MaintenanceError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createPlan({
    required String planName,
    String? description,
    required String frequency,
  }) async {
    await _api.create(
      planName: planName,
      description: description,
      frequency: frequency,
    );
    await load();
  }
}
