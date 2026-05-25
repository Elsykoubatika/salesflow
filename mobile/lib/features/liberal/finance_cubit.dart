import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'finance_api.dart';
import 'finance_model.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();
  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

class FinanceLoaded extends FinanceState {
  final List<FinanceAccount> accounts;
  final int total;
  const FinanceLoaded({required this.accounts, required this.total});

  double get totalBalance =>
      accounts.fold(0.0, (sum, a) => sum + a.currentBalance);

  @override
  List<Object?> get props => [accounts, total];
}

class FinanceError extends FinanceState {
  final String message;
  const FinanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({FinanceApi? api})
      : _api = api ?? FinanceApi(),
        super(const FinanceInitial());

  final FinanceApi _api;

  Future<void> load() async {
    emit(const FinanceLoading());
    try {
      final r = await _api.listAccounts();
      emit(FinanceLoaded(accounts: r.items, total: r.total));
    } catch (e) {
      emit(FinanceError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createAccount({
    required String accountName,
    required String accountType,
    double initialBalance = 0,
  }) async {
    await _api.createAccount(
      accountName: accountName,
      accountType: accountType,
      initialBalance: initialBalance,
    );
    await load();
  }

  Future<void> addTransaction(
    String accountId, {
    required String transactionType,
    required double amount,
    required DateTime transactionDate,
    String? description,
  }) async {
    await _api.addTransaction(
      accountId,
      transactionType: transactionType,
      amount: amount,
      transactionDate: transactionDate,
      description: description,
    );
    await load();
  }
}
