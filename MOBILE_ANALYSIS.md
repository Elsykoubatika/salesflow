# 📱 PHASE 4 - ANALYSE MOBILE (Flutter)

## 📅 Date : 20 mai 2026
## ✨ Statut : CORRECTIONS EN COURS

---

## 🔍 PROBLÈMES IDENTIFIÉS

### 1. ⚠️ IP HARDCODED (IMPORTANT)

**Fichier** : `mobile/lib/api/api_client.dart:15`

```dart
// ❌ AVANT : IP hardcoded
static const String baseUrl = 'http://192.168.1.68:5000';
```

**Problème** :
- IP locale spécifique à une machine développeur
- Non portable entre machines
- Cassera la compilation pour les autres membres de l'équipe
- Impossible de publier en production

**Solution** :
```dart
// ✅ APRÈS : Configuration d'environnement
static String get baseUrl => _getBaseUrl();

static String _getBaseUrl() {
  // À adapter selon votre environnement
  // Développement : http://10.0.2.2:5000 (émulateur Android)
  // Simulateur iOS : http://localhost:5000
  // Téléphone : http://<IP-PC-WiFi>:5000
  return 'http://10.0.2.2:5000'; // Par défaut émulateur Android
}
```

---

### 2. ⚠️ ROUTES API INCOHÉRENTES

**Fichier** : `mobile/lib/api/auth_api.dart`

```dart
// ❌ AVANT : Capitalisé (/api/Auth/login)
final response = await _dio.post('/api/Auth/login', ...);
await _dio.post('/api/Auth/register', ...);
await _dio.get('/api/Auth/me');
```

**Problème** :
- Les routes backend sont en minuscules : `/api/auth/login`
- Les routes mobiles utilisent : `/api/Auth/login` (capitalisé)
- Cela génère des erreurs 404 "endpoint not found"

**Vérification** : Les vraies routes du backend sont :
```
✅ POST   /api/auth/login
✅ POST   /api/auth/register
✅ GET    /api/auth/me
```

**Solution** :
```dart
// ✅ APRÈS : Minuscules pour matcher le backend
final response = await _dio.post('/api/auth/login', ...);
await _dio.post('/api/auth/register', ...);
await _dio.get('/api/auth/me');
```

---

### 3. ✅ POINTS POSITIFS

**Structure bien pensée** :
- ✅ Dio HTTP client configuré
- ✅ Intercepteur pour ajouter automatiquement le JWT
- ✅ SecureStorage pour sauvegarder le token de façon sécurisée
- ✅ Gestion d'état avec BLoC/Cubit
- ✅ Gestion d'erreurs lisible pour l'utilisateur
- ✅ Splashscreen + navigation basée sur l'état d'auth
- ✅ Dépendances bien choisies

---

## 🛠️ CORRECTIONS À APPLIQUER

### Correction 1 : IP flexible (api_client.dart)

```dart
// AVANT
static const String baseUrl = 'http://192.168.1.68:5000';

// APRÈS
static String get baseUrl {
  // TODO: Adapter selon votre environnement
  // - Émulateur Android : http://10.0.2.2:5000
  // - Simulateur iOS : http://localhost:5000
  // - Téléphone physique : http://<IP-PC>:5000
  return 'http://10.0.2.2:5000';
}
```

### Correction 2 : Routes API en minuscules (auth_api.dart)

```dart
// Remplacer tous les
'/api/Auth/login'    → '/api/auth/login'
'/api/Auth/register' → '/api/auth/register'
'/api/Auth/me'       → '/api/auth/me'
```

---

## 📊 CHECKLIST MOBILE

- [x] Dépendances présentes (pubspec.yaml)
- [x] Gestion d'état (BLoC/Cubit)
- [x] HTTP client (Dio)
- [x] Stockage JWT sécurisé
- [ ] IP de développement à adapter
- [ ] Routes API à corriger
- [ ] Tests mobiles (si présents)
- [ ] Android & iOS configuration

---

## ⏱️ TEMPS ESTIMÉ POUR CORRECTION

- IP hardcoded : 2 min
- Routes API : 5 min
- Tests : 10 min
- **Total : ~17 minutes**

---

## 🚀 PROCHAINES ÉTAPES

1. ✅ Appliquer corrections API
2. 🔄 Tester sur émulateur/téléphone
3. 📝 Vérifier logs
4. ✅ Valider navigation auth

---

