import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_cubit.dart';
import '../widgets/brand.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();

    // Animation d'entrée (logo + texte)
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Animation continue de la barre de chargement
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Vérifie le token dès l'affichage du splash (logique préservée)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.15,
            colors: [
              DealFlowBrand.green700,
              DealFlowBrand.green900,
              DealFlowBrand.green950,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Motif réseau en arrière-plan
            const Positioned.fill(
              child: NetworkPattern(opacity: 0.42),
            ),

            // Logo + wordmark centrés
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RiseFade(
                    controller: _intro,
                    delay: 0.0,
                    child: const InfinityMark(size: 116),
                  ),
                  const SizedBox(height: 26),
                  _RiseFade(
                    controller: _intro,
                    delay: 0.18,
                    child: const DealFlowWordmark(size: 32),
                  ),
                ],
              ),
            ),

            // Barre de chargement + slogan en bas
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _intro,
                  curve: const Interval(0.5, 1.0),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      child: _IndeterminateBar(animation: _loop),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CONNEXION SÉCURISÉE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.2,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      DealFlowBrand.slogan,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animation d'entrée : translation vers le haut + fondu.
class _RiseFade extends StatelessWidget {
  final AnimationController controller;
  final double delay; // 0..1
  final Widget child;

  const _RiseFade({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curved.value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Barre de progression indéterminée — segment qui glisse en boucle.
class _IndeterminateBar extends StatelessWidget {
  final Animation<double> animation;
  const _IndeterminateBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 3,
        color: Colors.white.withValues(alpha: 0.14),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Align(
              alignment: Alignment(-1.0 + 2.6 * animation.value, 0),
              child: FractionallySizedBox(
                widthFactor: 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        DealFlowBrand.green500,
                        DealFlowBrand.mint,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
