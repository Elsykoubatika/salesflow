import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'invoice_api.dart';
import 'invoice_model.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceItem> items;
  final int total;
  const InvoiceLoaded({required this.items, required this.total});
  @override
  List<Object?> get props => [items, total];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit({InvoiceApi? api})
      : _api = api ?? InvoiceApi(),
        super(const InvoiceInitial());

  final InvoiceApi _api;

  Future<void> load() async {
    emit(const InvoiceLoading());
    try {
      final r = await _api.list();
      emit(InvoiceLoaded(items: r.items, total: r.total));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createInvoice({
    required String clientId,
    required String description,
    required double actualHours,
    required double hourlyRate,
    double materialsCost = 0,
    double advancePayment = 0,
    String? notes,
  }) async {
    await _api.create(
      clientId: clientId,
      description: description,
      actualHours: actualHours,
      hourlyRate: hourlyRate,
      materialsCost: materialsCost,
      advancePayment: advancePayment,
      notes: notes,
    );
    await load();
  }
}
