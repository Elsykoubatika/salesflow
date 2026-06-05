import 'package:equatable/equatable.dart';

/// Réponse complète de GET /api/dashboard/overview.
class DashboardOverview extends Equatable {
  final double todayRevenue;
  final double todayDeltaPercent;
  final int inProgressOrders;
  final double monthRevenue;
  final double monthDeltaPercent;
  final int activeClients;
  final int newClientsThisMonth;
  final List<DailyRevenuePoint> revenueByDay;
  final List<TopProductItem> topProducts;
  final List<DashboardAlert> alerts;
  final String currency;
  final DateTime generatedAt;

  const DashboardOverview({
    required this.todayRevenue,
    required this.todayDeltaPercent,
    required this.inProgressOrders,
    required this.monthRevenue,
    required this.monthDeltaPercent,
    required this.activeClients,
    required this.newClientsThisMonth,
    required this.revenueByDay,
    required this.topProducts,
    required this.alerts,
    required this.currency,
    required this.generatedAt,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      todayRevenue: (json['todayRevenue'] as num? ?? 0).toDouble(),
      todayDeltaPercent: (json['todayDeltaPercent'] as num? ?? 0).toDouble(),
      inProgressOrders: (json['inProgressOrders'] as num? ?? 0).toInt(),
      monthRevenue: (json['monthRevenue'] as num? ?? 0).toDouble(),
      monthDeltaPercent: (json['monthDeltaPercent'] as num? ?? 0).toDouble(),
      activeClients: (json['activeClients'] as num? ?? 0).toInt(),
      newClientsThisMonth: (json['newClientsThisMonth'] as num? ?? 0).toInt(),
      revenueByDay: ((json['revenueByDay'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DailyRevenuePoint.fromJson)
          .toList(),
      topProducts: ((json['topProducts'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TopProductItem.fromJson)
          .toList(),
      alerts: ((json['alerts'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardAlert.fromJson)
          .toList(),
      currency: json['currency'] as String? ?? 'XAF',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        todayRevenue,
        inProgressOrders,
        monthRevenue,
        activeClients,
        revenueByDay,
        topProducts,
        alerts,
        generatedAt,
      ];
}

class DailyRevenuePoint extends Equatable {
  final DateTime date;
  final double amount;
  const DailyRevenuePoint({required this.date, required this.amount});

  factory DailyRevenuePoint.fromJson(Map<String, dynamic> json) {
    return DailyRevenuePoint(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [date, amount];
}

class TopProductItem extends Equatable {
  final String productId;
  final String name;
  final int salesCount;
  final String currency;
  final double unitPrice;

  const TopProductItem({
    required this.productId,
    required this.name,
    required this.salesCount,
    required this.currency,
    required this.unitPrice,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      salesCount: (json['salesCount'] as num? ?? 0).toInt(),
      currency: json['currency'] as String? ?? 'XAF',
      unitPrice: (json['unitPrice'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [productId, name, salesCount, unitPrice];
}

class DashboardAlert extends Equatable {
  final String type;
  final String severity; // info | warning | danger
  final String title;
  final String action;

  const DashboardAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.action,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    return DashboardAlert(
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [type, severity, title, action];
}
