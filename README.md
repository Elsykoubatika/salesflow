# SalesFlow Pro Congo

> Application mobile de gestion commerciale et technique pour la République du Congo.
> Phase 0 — Fondations : backend .NET 8 + PostgreSQL + JWT + skeleton Flutter.

---

## 📋 Prérequis

À installer **avant tout** :

| Outil | Version | Lien |
|---|---|---|
| **Visual Studio 2022** | 17.8+ avec workload "ASP.NET et développement web" | https://visualstudio.microsoft.com/fr/downloads/ |
| **.NET 8 SDK** | 8.0.x (inclus dans VS 2022 17.8+) | https://dotnet.microsoft.com/fr-fr/download/dotnet/8.0 |
| **Docker Desktop** | Dernière | https://www.docker.com/products/docker-desktop/ |
| **Git** | Dernière | https://git-scm.com/download/win |
| **Flutter SDK** | 3.24+ (à installer plus tard, pour la partie mobile) | https://docs.flutter.dev/get-started/install/windows |

Vérifier avec PowerShell :
```powershell
dotnet --version    # doit retourner 8.x.x
docker --version
git --version
```

---

## 🚀 Démarrage rapide (10 minutes)

### 1. Cloner / récupérer le projet

Décompresser le ZIP, ou cloner si vous l'avez déjà mis sur Git :
```powershell
cd C:\dev
# si zip : décompresser ici. Sinon :
git clone <votre-repo> salesflow
cd salesflow
```

### 2. Lancer PostgreSQL avec Docker

Dans PowerShell, à la racine du projet :
```powershell
docker compose up -d
```

Cela lance deux conteneurs :
- **postgres** sur le port `5432` (base de données)
- **pgadmin** sur `http://localhost:5050` (interface web optionnelle, login : `admin@salesflow.local` / `admin`)

Vérifier que ça tourne :
```powershell
docker ps
```

### 3. Générer une clé JWT sécurisée

Avant de lancer l'API, il **faut** remplacer la clé JWT par défaut. Dans PowerShell :
```powershell
$key = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
Write-Host $key
```

Copier la chaîne générée, puis ouvrir `backend/SalesFlow.API/appsettings.json` et remplacer la valeur de `Jwt.Key`.

> **⚠️ Important** : ne jamais commit cette clé sur Git en production. Utiliser des variables d'environnement ou Azure Key Vault.

### 4. Ouvrir la solution dans Visual Studio

```powershell
start backend/SalesFlow.sln
```

Visual Studio va restaurer automatiquement les paquets NuGet (~1 minute la première fois).

### 5. Créer la migration EF Core initiale

Dans Visual Studio : **View → Terminal**, ou via PowerShell à la racine `backend/` :

```powershell
# Installer l'outil EF si pas déjà fait (une seule fois sur votre machine)
dotnet tool install --global dotnet-ef

# Créer la migration Initial
dotnet ef migrations add Initial `
  --project SalesFlow.Infrastructure `
  --startup-project SalesFlow.API `
  --output-dir Persistence/Migrations
```

> Pas besoin d'appliquer la migration manuellement : `Program.cs` contient `db.Database.Migrate()` qui le fait automatiquement au démarrage en mode Development.

### 6. Lancer l'API

Dans Visual Studio : **F5** (ou bouton ▶ "https"). Swagger s'ouvre sur `https://localhost:5001/swagger`.

Tester :
1. **GET `/api/health`** → doit retourner `{ status: "ok", ... }`
2. **POST `/api/auth/register`** avec :
   ```json
   {
     "email": "test@cowema.cg",
     "password": "MotDePasse123!",
     "fullName": "Jean Mboungou",
     "phoneNumber": "+242050000000",
     "domainType": 1
   }
   ```
   → reçoit un `token` JWT.
3. **POST `/api/auth/login`** avec le même email/password → reçoit un nouveau `token`.
4. Cliquer **Authorize** en haut de Swagger, coller `Bearer <token>`, puis tester **GET `/api/auth/me`** → doit renvoyer vos infos.

✅ Si ça marche : **fondations OK**, on peut passer à la Phase MVP.

---

## 🏗️ Architecture du projet

```
salesflow/
├── backend/
│   ├── SalesFlow.sln
│   ├── SalesFlow.Domain/           ← Entités métier (User, Client, ...)
│   │   └── (zéro dépendance)
│   ├── SalesFlow.Application/      ← Services, DTOs, interfaces
│   │   └── dépend de Domain
│   ├── SalesFlow.Infrastructure/   ← EF Core, JWT, BCrypt, intégrations
│   │   └── dépend de Application + Domain
│   └── SalesFlow.API/              ← Controllers HTTP, Program.cs
│       └── dépend de Application + Infrastructure
├── docker-compose.yml              ← PostgreSQL + pgAdmin
├── .gitignore
└── README.md
```

**Pourquoi cette séparation (Clean Architecture) ?**
- **Domain** ne connaît rien du reste → les règles métier sont indépendantes de la BDD ou du framework web. Vous pouvez changer EF Core pour Dapper sans toucher à `Domain`.
- **Application** définit *ce que* le système fait via des interfaces. Pas d'accès direct à la BDD.
- **Infrastructure** implémente *comment*, en branchant EF Core, BCrypt, JWT, etc.
- **API** ne fait qu'exposer les endpoints HTTP.

Cette discipline paie cher quand le projet grandit (testabilité, ajout de modules, refactoring).

---

## 🔐 Sécurité — ce qui est déjà en place

| Risque | Mitigation actuelle |
|---|---|
| Mots de passe en clair | BCrypt avec work factor 12 |
| Token volé | JWT signé HMAC-SHA256, expiration 24h |
| Énumération d'utilisateurs | Login renvoie un message générique |
| SQL injection | EF Core (paramètres systématiquement) |
| HTTPS manquant | `UseHttpsRedirection()` + dev cert auto |
| Clé JWT trop courte | Validation au démarrage : doit être ≥ 32 octets |

**À ajouter en Phase MVP** :
- Rate limiting sur `/auth/login` (anti-brute-force)
- Refresh tokens (pour ne pas re-login l'utilisateur tous les jours)
- Validation côté serveur plus stricte (FluentValidation)
- Logging structuré (Serilog)

---

## 📱 Initialisation Flutter (à faire après le backend)

Quand le backend tourne, on peut démarrer la partie mobile :

```powershell
cd C:\dev\salesflow
flutter create --org cg.salesflow --project-name salesflow_mobile mobile
cd mobile
```

Ajouter dans `mobile/pubspec.yaml` (sous `dependencies:`) :

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # State management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # API
  dio: ^5.7.0
  json_annotation: ^4.9.0

  # Local storage (offline-first)
  sqflite: ^2.4.0
  path_provider: ^2.1.5
  flutter_secure_storage: ^9.2.2  # pour stocker le JWT

  # Utils
  intl: ^0.19.0
  freezed_annotation: ^2.4.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
```

Installer :
```powershell
flutter pub get
flutter run    # avec un émulateur ou téléphone Android branché
```

> Pour appeler `http://localhost:5000` depuis l'émulateur Android, utiliser `http://10.0.2.2:5000`. Sur iOS Simulator : `http://localhost:5000` fonctionne. Sur un vrai téléphone : `http://<IP-PC>:5000` (et désactiver HTTPS le temps du dev OU faire confiance au certificat).

Le code Flutter complet (login screen + appel API + stockage JWT sécurisé) sera fourni dans la **Phase MVP**.

---

## 📦 Que fait actuellement le projet ?

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `/api/health` | GET | non | Healthcheck |
| `/api/auth/register` | POST | non | Création de compte |
| `/api/auth/login` | POST | non | Connexion → JWT |
| `/api/auth/me` | GET | **JWT** | Profil de l'utilisateur connecté |

Tables PostgreSQL créées par la migration :
- `users` (id, email, password_hash, full_name, phone_number, domain_type, is_active, timestamps)
- `clients` (id, user_id, full_name, phone_number, email, address, region, notes, timestamps)

`clients` n'est pas encore exposée via l'API — ce sera le premier ajout en Phase MVP.

---

## 🗺️ Prochaines étapes — Phase MVP

Dans l'ordre recommandé (~ 4-6 semaines pour un dev junior) :

1. **CRUD Clients** — endpoints `GET/POST/PUT/DELETE /api/clients`, filtrés par `UserId` du token.
2. **Catalogue produits** + génération de lien WhatsApp (`wa.me/<num>?text=...`).
3. **Devis et commandes** — entités + machine à états (`Brouillon → Envoyé → Accepté → Livré → Payé`).
4. **Génération PDF** — facture/devis avec **QuestPDF** (recommandé sur DinkToPdf : meilleur, plus moderne, license MIT).
5. **Notifications FCM** — enregistrement token + endpoint d'envoi.
6. **Stock basique** — entité Inventory + ajustements + alertes seuil.

À chaque module : créer la branche Git → coder → tester avec Swagger → écrire au moins 2 tests unitaires → merger.

---

## 🆘 Dépannage fréquent

**`Failed to connect to PostgreSQL`**
→ Vérifier que `docker compose up -d` est bien lancé. `docker logs salesflow_postgres` pour les détails.

**`The JWT signing key must be at least 256 bits`**
→ Votre clé dans `appsettings.json` fait moins de 32 caractères. Régénérer avec la commande PowerShell ci-dessus.

**`No project was found` quand on lance `dotnet ef`**
→ Vous n'êtes pas dans le dossier `backend/`. `cd backend` puis recommencer.

**Visual Studio ne voit pas les références entre projets**
→ Clic droit sur la solution → "Rebuild Solution".

**Migration EF échoue avec `Database does not exist`**
→ Normal au premier run. La méthode `db.Database.Migrate()` dans `Program.cs` la crée automatiquement au démarrage. Lancer simplement F5.

---

## 📞 Contact / Notes

Document de spécifications de référence : `Spécifications_Techniques___SalesFlow_Pro_Congo.pdf`
Stack confirmée : ASP.NET Core 8 + Flutter + PostgreSQL.

**Conseil** : initialiser un repo Git **maintenant**, avant d'écrire la moindre ligne de plus. Commits fréquents, branches par feature.

```powershell
cd C:\dev\salesflow
git init
git add .
git commit -m "chore: phase 0 - fondations backend + auth JWT + postgres docker"
```
