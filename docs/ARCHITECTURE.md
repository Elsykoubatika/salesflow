# Architecture — Notes pour l'équipe

## Diagramme des dépendances

```
┌──────────────────┐
│   SalesFlow.API  │  Controllers, Program.cs, Swagger
└────────┬─────────┘
         │ référence
         ▼
┌──────────────────────────┐
│ SalesFlow.Infrastructure │  EF Core, JWT, BCrypt, intégrations externes
└────┬─────────────────────┘
     │ référence
     ▼
┌──────────────────────┐
│ SalesFlow.Application│  Services métier, DTOs, interfaces
└────┬─────────────────┘
     │ référence
     ▼
┌────────────────┐
│ SalesFlow.Domain│  Entités pures, enums, value objects
└────────────────┘
```

**Règle d'or** : les flèches ne vont jamais dans l'autre sens. Si un projet du bas a besoin de quelque chose du haut, on inverse via une **interface** placée dans Application et implémentée dans Infrastructure (Inversion de Dépendance).

Exemple concret dans ce projet :
- `AuthService` (dans Application) a besoin d'envoyer un JWT et de hasher un mot de passe.
- Mais Application ne connaît pas BCrypt ni la lib JWT.
- Donc Application définit `IPasswordHasher` et `IJwtTokenGenerator` (interfaces).
- Infrastructure implémente `BcryptPasswordHasher` et `JwtTokenGenerator`.
- L'injection de dépendances câble le tout au démarrage dans `Program.cs`.

Résultat : on peut tester `AuthService` avec un faux hasher, sans BCrypt. On peut aussi changer BCrypt pour Argon2 sans toucher à la logique métier.

## Pourquoi les Guid pour les Id et pas les int ?

- Sécurité : pas de devinage d'IDs séquentiels (`/api/clients/123` → `/api/clients/124`)
- Génération côté client possible (utile pour offline-first → sync)
- Pas de collision lors d'imports/exports entre environnements
- Coût : 16 octets vs 4 — négligeable à l'échelle du projet

## Pourquoi PostgreSQL et pas SQL Server ou MySQL ?

| Critère | PostgreSQL | SQL Server | MySQL |
|---|---|---|---|
| Licence | gratuite | payante (Express limité) | gratuite |
| JSONB natif | ✅ | ⚠️ moins riche | ⚠️ moins riche |
| Extensions (PostGIS pour géoloc) | ✅ | partiel | partiel |
| Performances complex queries | ✅ | ✅ | ⚠️ |
| Hébergement Azure / AWS / OVH | ✅ partout | Azure ou Windows | partout |

Pour la logistique collaborative (module 5), on aura potentiellement besoin de PostGIS pour les distances géographiques. Cas évident pour Postgres.

## Conventions de nommage adoptées

| Élément | Convention | Exemple |
|---|---|---|
| Classes | PascalCase | `AuthService` |
| Méthodes | PascalCase | `GenerateToken` |
| Variables locales | camelCase | `userId` |
| Champs privés | _camelCase | `_db` |
| Tables SQL | snake_case minuscule | `users`, `clients` |
| Endpoints API | kebab-case | `/api/sales-orders` |
| DTOs | suffix `Request`/`Response` | `RegisterRequest` |
| Interfaces | préfixe `I` | `IAuthService` |

## Tests à écrire en priorité (Phase MVP)

1. **AuthServiceTests** — register / login / email déjà pris / mauvais password
2. **JwtTokenGeneratorTests** — token contient les bons claims, expiration correcte
3. **AuthControllerTests** — codes HTTP corrects, body bien formé

Framework recommandé : **xUnit** + **FluentAssertions** + **Moq** pour les mocks, **Testcontainers** pour les tests d'intégration avec un vrai PostgreSQL jetable.
