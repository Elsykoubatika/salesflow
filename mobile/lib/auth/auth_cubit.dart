import 'package:flutter_bloc/flutter_bloc.dart';

import '../api/auth_api.dart';
import '../models/auth_response.dart';
import 'auth_state.dart';
import 'secure_storage.dart';

/// Pilote toute la logique d'authentification de l'app.
///
/// Cycle de vie :
///   AuthInitial (au démarrage)
///   → checkAuthStatus() vérifie le token persisté
///   → si valide : AuthAuthenticated
///   → sinon : AuthUnauthenticated
///
/// L'UI écoute les transitions et navigue en conséquence.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthApi? api})
      : _api = api ?? AuthApi(),
        super(const AuthInitial());

  final AuthApi _api;

  /// Vérifie si un token valide existe en stockage sécurisé.
  /// Appelé au démarrage de l'app par le splash screen.
  Future<void> checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Le token existe — vérifier qu'il est encore valide côté serveur
    try {
      final user = await _api.me();
      emit(AuthAuthenticated(user));
    } catch (_) {
      // Token expiré ou invalide → forcer reconnexion
      await SecureStorage.clearToken();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final response = await _api.login(email: email, password: password);
      await SecureStorage.saveToken(response.token);
      emit(AuthAuthenticated(UserProfile(
        userId: response.userId,
        email: response.email,
        fullName: response.fullName,
      )));
    } catch (e) {
      emit(AuthUnauthenticated(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearToken();
    emit(const AuthUnauthenticated());
  }
}
