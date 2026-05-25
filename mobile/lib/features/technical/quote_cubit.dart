import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'quote_api.dart';
import 'quote_model.dart';

abstract class QuoteState extends Equatable {
  const QuoteState();
  @override
  List<Object?> get props => [];
}

class QuoteInitial extends QuoteState {
  const QuoteInitial();
}

class QuoteLoading extends QuoteState {
  const QuoteLoading();
}

class QuoteLoaded extends QuoteState {
  final List<QuoteListItem> items;
  final int total;
  final int acceptedCount;
  const QuoteLoaded({
    required this.items,
    required this.total,
    required this.acceptedCount,
  });
  @override
  List<Object?> get props => [items, total, acceptedCount];
}

class QuoteError extends QuoteState {
  final String message;
  const QuoteError(this.message);
  @override
  List<Object?> get props => [message];
}

class QuoteCubit extends Cubit<QuoteState> {
  QuoteCubit({QuoteApi? api})
      : _api = api ?? QuoteApi(),
        super(const QuoteInitial());

  final QuoteApi _api;

  Future<void> load() async {
    emit(const QuoteLoading());
    try {
      final r = await _api.list();
      emit(QuoteLoaded(
        items: r.items,
        total: r.total,
        acceptedCount: r.acceptedCount,
      ));
    } catch (e) {
      emit(QuoteError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createQuote({
    required String clientId,
    required String title,
    String? description,
    String? serviceLocation,
    required double estimatedHours,
    required double hourlyRate,
  }) async {
    await _api.create(
      clientId: clientId,
      title: title,
      description: description,
      serviceLocation: serviceLocation,
      estimatedHours: estimatedHours,
      hourlyRate: hourlyRate,
    );
    await load();
  }
}
