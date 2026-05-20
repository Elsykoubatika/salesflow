using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Common.Interfaces;

/// <summary>
/// Génère un JWT signé pour un utilisateur authentifié.
/// </summary>
public interface IJwtTokenGenerator
{
    string GenerateToken(User user);
}
