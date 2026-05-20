import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../clients/clients_api.dart';
import '../inventory/inventory_api.dart';
import '../proofs/proofs_api.dart';
import '../sales/sales_api.dart';
import 'dashboard_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardMetrics metrics;
  final List<Recommendation> recommendations;

  const DashboardLoaded({
    required this.metrics,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [metrics, recommendations];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    ClientsApi? clientsApi,
    SalesApi? salesApi,
    InventoryApi? inventoryApi,
    ProofsApi? proofsApi,
  })  : _clientsApi = clientsApi ?? ClientsApi(),
        _salesApi = salesApi ?? SalesApi(),
        _inventoryApi = inventoryApi ?? InventoryApi(),
        _proofsApi = proofsApi ?? ProofsApi(),
        super(const DashboardInitial());

  final ClientsApi _clientsApi;
  final SalesApi _salesApi;
  final InventoryApi _inventoryApi;
  final ProofsApi _proofsApi;

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      // Lancer toutes les requêtes en parallèle
      final clientsResp = await _clientsApi.list(pageSize: 100);
      final salesResp = await _salesApi.list(pageSize: 100);
      final inventoryResp = await _inventoryApi.list(pageSize: 100);
      final proofsResp = await _proofsApi.list(pageSize: 100);

      // Calculer les métriques
      final metrics = _calculateMetrics(
        clientsResp,
        salesResp,
        inventoryResp,
        proofsResp,
      );

      // Générer les recommandations
      final recommendations = _generateRecommendations(
        metrics,
        inventoryResp,
        salesResp,
        proofsResp,
      );

      emit(DashboardLoaded(metrics: metrics, recommendations: recommendations));
    } catch (e) {
      emit(DashboardError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  DashboardMetrics _calculateMetrics(
    dynamic clientsResp,
    dynamic salesResp,
    dynamic inventoryResp,
    dynamic proofsResp,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    //final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    // Clients
    final clients = clientsResp.items ?? [];
    final totalClients = clients.length;

    // Sales orders
    final orders = salesResp.items ?? [];
    int revenueThisMonth = 0;
    int revenueLast30Days = 0;
    int ordersPending = 0,
        ordersAccepted = 0,
        ordersPaid = 0,
        ordersOverdue = 0;

    for (final order in orders) {
      final amount = (order.total ?? 0) as num;
      final createdAt = order.createdAt as DateTime?;

      if (createdAt != null && createdAt.isAfter(monthStart)) {
        revenueThisMonth += amount.toInt();
      }
      if (createdAt != null &&
          createdAt.isAfter(now.subtract(const Duration(days: 30)))) {
        revenueLast30Days += amount.toInt();
      }

      final status = order.status;
      if (status?.label == 'Brouillon' || status?.label == 'Envoyé') {
        ordersPending++;
      } else if (status?.label == 'Acceptée') {
        ordersAccepted++;
      } else if (status?.label == 'Payée') {
        ordersPaid++;
      }

      // Overdue logic: paidAt devrait être avant today, check si elle existe et est future
      if (order.paidAt == null &&
          order.sentAt != null &&
          DateTime.now().difference(order.sentAt!).inDays > 7) {
        ordersOverdue++;
      }
    }

    final revenueTrend = revenueLast30Days > 0
        ? ((revenueThisMonth - (revenueLast30Days - revenueThisMonth)) /
                revenueLast30Days) *
            100
        : 0;

    // Inventory
    final inventory = inventoryResp.items ?? [];
    final productsTotal = inventory.length;
    int productsLowStock = 0, productsOutOfStock = 0;

    for (final item in inventory) {
      final qty = (item.quantity ?? 0) as num;
      final alertThreshold = (item.alertThreshold ?? 10) as num;

      if (qty == 0) {
        productsOutOfStock++;
      } else if (qty <= alertThreshold) {
        productsLowStock++;
      }
    }

    // Proofs
    final proofs = proofsResp.items ?? [];
    final proofsTotal = proofs.length;
    int proofsPending = 0, proofsValidated = 0, proofsErrors = 0;

    for (final proof in proofs) {
      final status = proof.status;
      if (status?.label == 'En attente') {
        proofsPending++;
      } else if (status?.label == 'Validée') {
        proofsValidated++;
      } else if (status?.label == 'Erreur') {
        proofsErrors++;
      }
    }

    // Active clients this month (ceux avec une commande ce mois)
    final activeClientsThisMonth = <String>{};
    for (final order in orders) {
      if (order.createdAt?.isAfter(monthStart) == true) {
        activeClientsThisMonth.add(order.clientId);
      }
    }

    return DashboardMetrics(
      totalClients: totalClients,
      activeThisMonth: activeClientsThisMonth.length,
      revenueThisMonth: revenueThisMonth,
      revenueLast30Days: revenueLast30Days,
      revenueTrend: revenueTrend,
      ordersTotal: orders.length,
      ordersPending: ordersPending,
      ordersAccepted: ordersAccepted,
      ordersPaid: ordersPaid,
      ordersOverdue: ordersOverdue,
      productsTotal: productsTotal,
      productsLowStock: productsLowStock,
      productsOutOfStock: productsOutOfStock,
      proofsTotal: proofsTotal,
      proofsPending: proofsPending,
      proofsValidated: proofsValidated,
      proofsErrors: proofsErrors,
    );
  }

  List<Recommendation> _generateRecommendations(
    DashboardMetrics metrics,
    dynamic inventoryResp,
    dynamic salesResp,
    dynamic proofsResp,
  ) {
    final recommendations = <Recommendation>[];

    // Urgence 1: Stock critique
    if (metrics.productsOutOfStock > 0) {
      recommendations.add(
        Recommendation(
          id: 'stock-critical',
          severity: RecommendationSeverity.urgent,
          title: '${metrics.productsOutOfStock} produit(s) en rupture',
          description:
              'Des articles n\'ont plus de stock. Réapprovisionner rapidement.',
          actionLabel: 'Voir le stock',
        ),
      );
    }

    // Urgence 2: Preuves de paiement en attente
    if (metrics.proofsPending > 3) {
      recommendations.add(
        Recommendation(
          id: 'proofs-pending',
          severity: RecommendationSeverity.urgent,
          title: '${metrics.proofsPending} preuves en attente de validation',
          description:
              'Validez les preuves de paiement Mobile Money pour clarifier vos encaissements.',
          actionLabel: 'Valider les preuves',
        ),
      );
    }

    // Avertissement: Commandes en retard (>7j sans paiement)
    if (metrics.ordersOverdue > 0) {
      recommendations.add(
        Recommendation(
          id: 'orders-overdue',
          severity: RecommendationSeverity.warning,
          title: '${metrics.ordersOverdue} commande(s) impayée(s) depuis >7j',
          description:
              'Des factures traînent. Relancer les clients non-payants.',
          actionLabel: 'Relancer',
        ),
      );
    }

    // Avertissement: Stock bas
    if (metrics.productsLowStock > 0 && metrics.productsLowStock <= 5) {
      recommendations.add(
        Recommendation(
          id: 'stock-low',
          severity: RecommendationSeverity.warning,
          title: '${metrics.productsLowStock} produit(s) en stock bas',
          description: 'Bientôt rupture. Planifier un réapprovisionnement.',
          actionLabel: 'Voir alertes',
        ),
      );
    }

    // Info: Performance positive
    if (metrics.revenueThisMonth > 0 && metrics.revenueTrend > 10) {
      recommendations.add(
        Recommendation(
          id: 'revenue-growth',
          severity: RecommendationSeverity.info,
          title:
              'Revenue en hausse +${metrics.revenueTrend.toStringAsFixed(0)}%',
          description: 'Bravo ! Vous encaissez plus que le mois dernier.',
          actionLabel: 'Détails',
        ),
      );
    }

    // Info: New clients
    if (metrics.activeThisMonth > metrics.totalClients ~/ 3) {
      recommendations.add(
        Recommendation(
          id: 'active-clients',
          severity: RecommendationSeverity.info,
          title:
              '${metrics.activeThisMonth}/${metrics.totalClients} clients actifs',
          description: 'Bonne clientèle ce mois. Continuez !',
          actionLabel: 'Voir clients',
        ),
      );
    }

    return recommendations;
  }
}
