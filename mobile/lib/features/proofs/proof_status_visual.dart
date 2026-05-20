import 'package:flutter/material.dart';

import 'proof_model.dart';

/// Couleurs et icônes par statut.
class ProofStatusVisual {
  static Color color(ProofStatus s, ColorScheme scheme) {
    switch (s) {
      case ProofStatus.pending:
        return Colors.orange.shade700;
      case ProofStatus.validated:
        return Colors.green.shade700;
      case ProofStatus.error:
        return scheme.error;
    }
  }

  static IconData icon(ProofStatus s) {
    switch (s) {
      case ProofStatus.pending:
        return Icons.hourglass_top_rounded;
      case ProofStatus.validated:
        return Icons.check_circle_rounded;
      case ProofStatus.error:
        return Icons.error_rounded;
    }
  }
}

class ProofStatusBadge extends StatelessWidget {
  final ProofStatus status;
  const ProofStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ProofStatusVisual.color(status, theme.colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ProofStatusVisual.icon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icône colorée pour l'opérateur Mobile Money.
class OperatorChip extends StatelessWidget {
  final MobileMoneyOperator operator;
  const OperatorChip({super.key, required this.operator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (operator) {
      MobileMoneyOperator.mtnMomo => Colors.amber.shade800,
      MobileMoneyOperator.airtelMoney => Colors.red.shade700,
      MobileMoneyOperator.other => theme.colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        operator.label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
