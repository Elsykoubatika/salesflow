import 'package:equatable/equatable.dart';

/// Item de liste compact (vue grille).
class DealListItem extends Equatable {
  final String id;
  final String title;
  final String creatorName;
  final String commissionType; // CPC | CPS | CPA | CPL
  final String commissionLabel; // ex: "+800 XAF / vente"
  final String status;
  final String? productId;
  final DateTime? activeTo;
  final int affiliateCount;
  final int saleCount;

  const DealListItem({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.commissionType,
    required this.commissionLabel,
    required this.status,
    this.productId,
    this.activeTo,
    required this.affiliateCount,
    required this.saleCount,
  });

  factory DealListItem.fromJson(Map<String, dynamic> json) => DealListItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        creatorName: json['creatorName'] as String? ?? '',
        commissionType: json['commissionType'] as String? ?? 'CPA',
        commissionLabel: json['commissionLabel'] as String? ?? '',
        status: json['status'] as String? ?? 'Active',
        productId: json['productId'] as String?,
        activeTo: json['activeTo'] != null
            ? DateTime.tryParse(json['activeTo'] as String)
            : null,
        affiliateCount: (json['affiliateCount'] as num? ?? 0).toInt(),
        saleCount: (json['saleCount'] as num? ?? 0).toInt(),
      );

  @override
  List<Object?> get props => [id, title, status];
}

/// Détail complet d'un deal.
class DealDetail extends Equatable {
  final String id;
  final String creatorUserId;
  final String creatorName;
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final double? productPrice;
  final String title;
  final String? description;
  final String? contentImages;
  final String? contentMaterials;
  final String commissionType;
  final double? commissionAmount;
  final double? commissionPercent;
  final String currency;
  final String? conditions;
  final int? stockAvailable;
  final DateTime activeFrom;
  final DateTime? activeTo;
  final String status;

  const DealDetail({
    required this.id,
    required this.creatorUserId,
    required this.creatorName,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.productPrice,
    required this.title,
    this.description,
    this.contentImages,
    this.contentMaterials,
    required this.commissionType,
    this.commissionAmount,
    this.commissionPercent,
    required this.currency,
    this.conditions,
    this.stockAvailable,
    required this.activeFrom,
    this.activeTo,
    required this.status,
  });

  factory DealDetail.fromJson(Map<String, dynamic> json) {
    final deal = json['deal'] as Map<String, dynamic>;
    return DealDetail(
      id: deal['id'] as String,
      creatorUserId: deal['creatorUserId'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? '',
      productId: deal['productId'] as String?,
      productName: json['productName'] as String?,
      productImageUrl: json['productImageUrl'] as String?,
      productPrice: (json['productPrice'] as num?)?.toDouble(),
      title: deal['title'] as String? ?? '',
      description: deal['description'] as String?,
      contentImages: deal['contentImages'] as String?,
      contentMaterials: deal['contentMaterials'] as String?,
      commissionType: deal['commissionType'] as String? ?? 'CPA',
      commissionAmount: (deal['commissionAmount'] as num?)?.toDouble(),
      commissionPercent: (deal['commissionPercent'] as num?)?.toDouble(),
      currency: deal['currency'] as String? ?? 'XAF',
      conditions: deal['conditions'] as String?,
      stockAvailable: (deal['stockAvailable'] as num?)?.toInt(),
      activeFrom: DateTime.tryParse(deal['activeFrom'] as String? ?? '') ??
          DateTime.now(),
      activeTo: deal['activeTo'] != null
          ? DateTime.tryParse(deal['activeTo'] as String)
          : null,
      status: deal['status'] as String? ?? 'Active',
    );
  }

  String get commissionLabel {
    if (commissionPercent != null) {
      return '${commissionPercent!.toStringAsFixed(commissionPercent! % 1 == 0 ? 0 : 1)}%';
    }
    return '${commissionAmount?.toStringAsFixed(0) ?? '0'} $currency';
  }

  @override
  List<Object?> get props => [id, title];
}

/// Analytics par canal pour MA part dans un deal donné.
class DealAnalytics extends Equatable {
  final int totalClicks;
  final int totalConversions;
  final double totalEarned;
  final String currency;
  final String? myShareCode;
  final List<ChannelMetrics> byChannel;

  const DealAnalytics({
    required this.totalClicks,
    required this.totalConversions,
    required this.totalEarned,
    required this.currency,
    this.myShareCode,
    required this.byChannel,
  });

  factory DealAnalytics.fromJson(Map<String, dynamic> json) => DealAnalytics(
        totalClicks: (json['totalClicks'] as num? ?? 0).toInt(),
        totalConversions: (json['totalConversions'] as num? ?? 0).toInt(),
        totalEarned: (json['totalEarned'] as num? ?? 0).toDouble(),
        currency: json['currency'] as String? ?? 'XAF',
        myShareCode: json['myShareCode'] as String?,
        byChannel: ((json['byChannel'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChannelMetrics.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props =>
      [totalClicks, totalConversions, totalEarned, byChannel];
}

class ChannelMetrics extends Equatable {
  final String channel;
  final int clicks;
  final int leads;
  final int sales;
  final double earned;

  const ChannelMetrics({
    required this.channel,
    required this.clicks,
    required this.leads,
    required this.sales,
    required this.earned,
  });

  factory ChannelMetrics.fromJson(Map<String, dynamic> json) => ChannelMetrics(
        channel: json['channel'] as String? ?? 'Direct',
        clicks: (json['clicks'] as num? ?? 0).toInt(),
        leads: (json['leads'] as num? ?? 0).toInt(),
        sales: (json['sales'] as num? ?? 0).toInt(),
        earned: (json['earned'] as num? ?? 0).toDouble(),
      );

  @override
  List<Object?> get props => [channel, clicks, sales, earned];
}

/// Mes gains agrégés sur tous les deals que j'ai partagés.
class MyEarnings extends Equatable {
  final double totalEarned;
  final int totalClicks;
  final int totalSales;
  final int activeShares;
  final String currency;

  const MyEarnings({
    required this.totalEarned,
    required this.totalClicks,
    required this.totalSales,
    required this.activeShares,
    required this.currency,
  });

  factory MyEarnings.fromJson(Map<String, dynamic> json) => MyEarnings(
        totalEarned: (json['totalEarned'] as num? ?? 0).toDouble(),
        totalClicks: (json['totalClicks'] as num? ?? 0).toInt(),
        totalSales: (json['totalSales'] as num? ?? 0).toInt(),
        activeShares: (json['activeShares'] as num? ?? 0).toInt(),
        currency: json['currency'] as String? ?? 'XAF',
      );

  @override
  List<Object?> get props =>
      [totalEarned, totalClicks, totalSales, activeShares];
}

/// Réponse à la création d'un lien de partage.
class ShareLink extends Equatable {
  final String shareId;
  final String uniqueCode;
  final String fullUrl;
  final String channel;
  final bool isNew;

  const ShareLink({
    required this.shareId,
    required this.uniqueCode,
    required this.fullUrl,
    required this.channel,
    required this.isNew,
  });

  factory ShareLink.fromJson(Map<String, dynamic> json) => ShareLink(
        shareId: json['shareId'] as String? ?? '',
        uniqueCode: json['uniqueCode'] as String? ?? '',
        fullUrl: json['fullUrl'] as String? ?? '',
        channel: json['channel'] as String? ?? 'Direct',
        isNew: json['isNew'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [shareId, fullUrl];
}
