import 'package:equatable/equatable.dart';

import '../models/auth_response.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial — on ne sait pas encore si on a un token valide.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// En cours d'appel API (login, register, vérification...).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// L'utilisateur est connecté.
class AuthAuthenticated extends AuthState {
  final UserProfile user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.userId];
}

/// L'utilisateur n'est pas connecté (token absent ou invalide).
class AuthUnauthenticated extends AuthState {
  /// Message d'erreur optionnel à afficher (ex: après un login échoué).
  final String? message;
  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}
