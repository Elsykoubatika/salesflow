import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'project_api.dart';
import 'project_model.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();
  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {
  const ProjectInitial();
}

class ProjectLoading extends ProjectState {
  const ProjectLoading();
}

class ProjectLoaded extends ProjectState {
  final List<ProjectListItem> items;
  final int total;
  const ProjectLoaded({required this.items, required this.total});
  @override
  List<Object?> get props => [items, total];
}

class ProjectError extends ProjectState {
  final String message;
  const ProjectError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProjectCubit extends Cubit<ProjectState> {
  ProjectCubit({ProjectApi? api})
      : _api = api ?? ProjectApi(),
        super(const ProjectInitial());

  final ProjectApi _api;

  Future<void> load() async {
    emit(const ProjectLoading());
    try {
      final r = await _api.list();
      emit(ProjectLoaded(items: r.items, total: r.total));
    } catch (e) {
      emit(ProjectError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => load();

  Future<void> createProject({
    required String clientId,
    required String projectName,
    String? description,
    String? projectType,
    required DateTime startDate,
    required DateTime endDate,
    double budgetAmount = 0,
  }) async {
    await _api.create(
      clientId: clientId,
      projectName: projectName,
      description: description,
      projectType: projectType,
      startDate: startDate,
      endDate: endDate,
      budgetAmount: budgetAmount,
    );
    await load();
  }
}
