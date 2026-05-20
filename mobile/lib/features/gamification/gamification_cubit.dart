import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GamificationState extends Equatable {
  const GamificationState();
  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

class GamificationLoaded extends GamificationState {
  final int totalPoints;
  final int thisWeekPoints;
  final int clientsCreated;
  final int ordersPaid;

  const GamificationLoaded({
    required this.totalPoints,
    required this.thisWeekPoints,
    required this.clientsCreated,
    required this.ordersPaid,
  });

  @override
  List<Object?> get props => [totalPoints, thisWeekPoints, clientsCreated, ordersPaid];
}

class GamificationCubit extends Cubit<GamificationState> {
  GamificationCubit() : super(const GamificationInitial());

  void load() {
    // Mock data for MVP (in production: fetch from backend)
    emit(const GamificationLoaded(
      totalPoints: 450,
      thisWeekPoints: 120,
      clientsCreated: 12,
      ordersPaid: 35,
    ));
  }

  void addPoints(int points) {
    if (state is GamificationLoaded) {
      final current = state as GamificationLoaded;
      emit(GamificationLoaded(
        totalPoints: current.totalPoints + points,
        thisWeekPoints: current.thisWeekPoints + points,
        clientsCreated: current.clientsCreated,
        ordersPaid: current.ordersPaid,
      ));
    }
  }
}
