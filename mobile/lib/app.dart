import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/auth_cubit.dart';
import 'auth/auth_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

class DealFlowApp extends StatelessWidget {
  const DealFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: MaterialApp(
        title: 'DealFlow Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return switch (state) {
              AuthInitial() => const SplashScreen(),
              AuthLoading() => const SplashScreen(),
              AuthAuthenticated() => const HomeScreen(),
              _ => const LoginScreen(),
            };
          },
        ),
      ),
    );
  }
}
