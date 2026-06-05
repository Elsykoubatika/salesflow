import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'api/api_client.dart';
import 'auth/auth_cubit.dart';
import 'auth/auth_state.dart';
import 'features/guest_cart/guest_cart_cubit.dart';
import 'theme.dart';
import 'features/public_catalog/public_catalog_api.dart';
import 'features/public_catalog/public_catalog_cubit.dart';
import 'features/public_catalog/public_catalog_screen.dart';
import 'screens/splash_screen.dart';
import 'shell/main_shell.dart';

class DealFlowApp extends StatelessWidget {
  const DealFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiRepositoryProvider(
      providers: [
        // ApiClient partagé entre tous les écrans (publics ET privés)
        RepositoryProvider<ApiClient>.value(value: apiClient),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
          ),
          // Panier invité disponible globalement
          BlocProvider<GuestCartCubit>(
            create: (_) => GuestCartCubit(),
          ),
        ],
        child: MaterialApp(
          title: 'DealFlow Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: _RootRouter(apiClient: apiClient),
        ),
      ),
    );
  }
}

/// Aiguillage selon l'état d'authentification :
///   - AuthInitial / AuthLoading → Splash
///   - AuthUnauthenticated       → Catalogue PUBLIC (mode invité) ← changement clé
///   - AuthAuthenticated         → MainShell (app complète)
///
/// Le bouton « Se connecter » du catalogue public ouvre l'écran LoginScreen
/// qui déclenche `context.read<AuthCubit>().login(...)`. À succès, le state
/// passe à AuthAuthenticated et ce router rebascule automatiquement vers le
/// MainShell. Pas de Navigator manuel à gérer.
class _RootRouter extends StatelessWidget {
  final ApiClient apiClient;
  const _RootRouter({required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthInitial() || AuthLoading() => const SplashScreen(),
          // ─── Mode invité : on entre direct dans le catalogue public ─────
          AuthUnauthenticated() => BlocProvider(
              create: (_) => PublicCatalogCubit(PublicCatalogApi(apiClient)),
              child: const PublicCatalogScreen(),
            ),
          // ─── Mode authentifié : MainShell complet ─────────────────────
          AuthAuthenticated(:final user) => MainShell(
              apiClient: apiClient,
              userFirstName: _firstName(user.fullName),
              userInitials: _initials(user.fullName),
            ),
          _ => const SplashScreen(),
        };
      },
    );
  }

  static String _firstName(String full) {
    final t = full.trim();
    if (t.isEmpty) return 'Utilisateur';
    return t.split(' ').first;
  }

  static String _initials(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
