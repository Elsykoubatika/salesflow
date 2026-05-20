import 'package:flutter/material.dart';

import 'sales_order_model.dart';

/// Mappe un statut à sa couleur sémantique et son icône.
class StatusVisual {
  final Color background;
  final Color foreground;
  final IconData icon;

  StatusVisual(this.background, this.foreground, this.icon);

  static StatusVisual of(BuildContext context, SalesOrderStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      SalesOrderStatus.draft => StatusVisual(
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.edit_note,
        ),
      SalesOrderStatus.sent => StatusVisual(
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.send_outlined,
        ),
      SalesOrderStatus.accepted => StatusVisual(
          const Color(0xFFE0F2F1),
          const Color(0xFF00695C),
          Icons.thumb_up_outlined,
        ),
      SalesOrderStatus.delivered => StatusVisual(
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.local_shipping_outlined,
        ),
      SalesOrderStatus.paid => StatusVisual(
          const Color(0xFFC8E6C9),
          const Color(0xFF1B5E20),
          Icons.check_circle_outline,
        ),
      SalesOrderStatus.rejected => StatusVisual(
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          Icons.cancel_outlined,
        ),
      SalesOrderStatus.cancelled => StatusVisual(
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.block,
        ),
    };
  }
}

/// Petit badge coloré qui affiche le statut.
class StatusBadge extends StatelessWidget {
  final SalesOrderStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final v = StatusVisual.of(context, status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: compact ? 12 : 14, color: v.foreground),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: v.foreground,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
