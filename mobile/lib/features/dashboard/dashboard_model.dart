import 'package:flutter/material.dart';

typedef RecommendationAction = void Function(BuildContext);

/// Métriques clés pour le dashboard exécutif.
class DashboardMetrics {
  final int totalClients;
  final int activeThisMonth;
  final num revenueThisMonth;
  final num revenueLast30Days;
  final num revenueTrend; // % change vs last month
  
  final int ordersTotal;
  final int ordersPending;
  final int ordersAccepted;
  final int ordersPaid;
  final int ordersOverdue; // Paid dans le futur vs aujourd'hui
  
  final int productsTotal;
  final int productsLowStock; // qty < seuil
  final int productsOutOfStock;
  
  final int proofsTotal;
  final int proofsPending;
  final int proofsValidated;
  final int proofsErrors;

  DashboardMetrics({
    required this.totalClients,
    required this.activeThisMonth,
    required this.revenueThisMonth,
    required this.revenueLast30Days,
    required this.revenueTrend,
    required this.ordersTotal,
    required this.ordersPending,
    required this.ordersAccepted,
    required this.ordersPaid,
    required this.ordersOverdue,
    required this.productsTotal,
    required this.productsLowStock,
    required this.productsOutOfStock,
    required this.proofsTotal,
    required this.proofsPending,
    required this.proofsValidated,
    required this.proofsErrors,
  });

  factory DashboardMetrics.empty() => DashboardMetrics(
    totalClients: 0,
    activeThisMonth: 0,
    revenueThisMonth: 0,
    revenueLast30Days: 0,
    revenueTrend: 0,
    ordersTotal: 0,
    ordersPending: 0,
    ordersAccepted: 0,
    ordersPaid: 0,
    ordersOverdue: 0,
    productsTotal: 0,
    productsLowStock: 0,
    productsOutOfStock: 0,
    proofsTotal: 0,
    proofsPending: 0,
    proofsValidated: 0,
    proofsErrors: 0,
  );
}

/// Recommandations intelligentes basées sur les données.
enum RecommendationSeverity { info, warning, urgent }

class Recommendation {
  final String id;
  final RecommendationSeverity severity;
  final String title;
  final String description;
  final String actionLabel;
  final RecommendationAction? action;

  Recommendation({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.action,
  });
}
