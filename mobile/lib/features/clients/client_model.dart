/// Représentation d'un client telle que retournée par /api/Clients.
class Client {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? region;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.address,
    this.region,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      region: json['region'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

class ClientListResponse {
  final List<Client> items;
  final int total;
  final int page;
  final int pageSize;

  ClientListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ClientListResponse.fromJson(Map<String, dynamic> json) {
    return ClientListResponse(
      items: (json['items'] as List).map((e) => Client.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}
