import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pipeline_api.dart';
import 'pipeline_model.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class PipelineState extends Equatable {
  const PipelineState();
  @override
  List<Object?> get props => [];
}

class PipelineInitial extends PipelineState {
  const PipelineInitial();
}

class PipelineLoading extends PipelineState {
  const PipelineLoading();
}

class PipelineLoaded extends PipelineState {
  final List<ProspectListItem> items;
  final int total;

  const PipelineLoaded({required this.items, required this.total});

  @override
  List<Object?> get props => [items, total];
}

class PipelineError extends PipelineState {
  final String message;
  const PipelineError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────────

class PipelineCubit extends Cubit<PipelineState> {
  PipelineCubit({PipelineApi? api})
      : _api = api ?? PipelineApi(),
        super(const PipelineInitial());

  final PipelineApi _api;

  Future<void> load() async {
    emit(const PipelineLoading());
    try {
      final response = await _api.list();
      emit(PipelineLoaded(items: response.items, total: response.total));
    } catch (e) {
      emit(PipelineError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  /// Crée un prospect puis recharge la liste.
  Future<void> createProspect({
    required String companyName,
    required String contactPerson,
    String? phoneNumber,
    String? email,
    int probability = 0,
  }) async {
    await _api.create(
      companyName: companyName,
      contactPerson: contactPerson,
      phoneNumber: phoneNumber,
      email: email,
      probability: probability,
    );
    await load();
  }

  /// Met à jour la probabilité d'un prospect puis recharge.
  Future<void> updateProbability(String id, int probability) async {
    await _api.updateProbability(id, probability);
    await load();
  }

  /// Ajoute un événement à un prospect.
  Future<void> addEvent(
    String id, {
    required String eventType,
    required DateTime eventDate,
    String? notes,
  }) async {
    await _api.addEvent(
      id,
      eventType: eventType,
      eventDate: eventDate,
      notes: notes,
    );
  }
}
