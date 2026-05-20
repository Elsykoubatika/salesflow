using SalesFlow.Domain.Common;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Utilisateur de l'application (vendeur, technicien ou professionnel libéral).
/// </summary>
public class User : BaseEntity
{
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public DomainType DomainType { get; set; } = DomainType.Commerce;
    public bool IsActive { get; set; } = true;

    // Relations - seront étendues lors des prochains modules
    public ICollection<Client> Clients { get; set; } = new List<Client>();
}
