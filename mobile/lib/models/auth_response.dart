/// Réponse de /api/Auth/login et /api/Auth/register.
class AuthResponse {
  final String token;
  final String userId;
  final String email;
  final String fullName;
  final int domainType;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.domainType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      domainType: json['domainType'] as int,
    );
  }
}

/// Profil utilisateur (extrait du JWT côté serveur via /api/Auth/me).
class UserProfile {
  final String userId;
  final String email;
  final String fullName;

  UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: (json['userId'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
    );
  }
}
