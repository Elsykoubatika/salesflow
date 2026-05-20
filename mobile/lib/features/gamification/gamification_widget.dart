import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme.dart';
import 'gamification_cubit.dart';

class GamificationWidget extends StatelessWidget {
  const GamificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GamificationCubit()..load(),
      child: BlocBuilder<GamificationCubit, GamificationState>(
        builder: (context, state) {
          if (state is! GamificationLoaded) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.xafGold.withValues(alpha: 0.15), Colors.transparent],
                begin: Alignment.topLeft,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.xafGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vos points', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text('${state.totalPoints} pts', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.forestGreen)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.xafGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('Cette semaine: +${state.thisWeekPoints}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
