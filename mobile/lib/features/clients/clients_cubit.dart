import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'client_model.dart';
import 'clients_api.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {
  const ClientsInitial();
}

class ClientsLoading extends ClientsState {
  const ClientsLoading();
}

class ClientsLoaded extends ClientsState {
  final List<Client> items;
  final int total;
  final String? activeSearch;

  const ClientsLoaded({required this.items, required this.total, this.activeSearch});

  @override
  List<Object?> get props => [items, total, activeSearch];
}

class ClientsError extends ClientsState {
  final String message;
  const ClientsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class ClientsCubit extends Cubit<ClientsState> {
  ClientsCubit({ClientsApi? api}) : _api = api ?? ClientsApi(), super(const ClientsInitial());

  final ClientsApi _api;
  Timer? _searchDebounce;

  /// Charge la liste. Appelé au premier affichage et lors du pull-to-refresh.
  Future<void> load({String? search}) async {
    emit(const ClientsLoading());
    try {
      final response = await _api.list(search: search);
      emit(ClientsLoaded(items: response.items, total: response.total, activeSearch: search));
    } catch (e) {
      emit(ClientsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Recherche avec debounce 350 ms — évite un appel API à chaque touche.
  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      load(search: query.isEmpty ? null : query);
    });
  }

  /// Appelé après création/édition pour rafraîchir la liste sans bouger l'UI.
  Future<void> refresh() async {
    final currentSearch = state is ClientsLoaded ? (state as ClientsLoaded).activeSearch : null;
    await load(search: currentSearch);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
