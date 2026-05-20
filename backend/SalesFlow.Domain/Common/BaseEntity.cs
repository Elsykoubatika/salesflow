namespace SalesFlow.Domain.Common;

/// <summary>
/// Classe de base pour toutes les entités du domaine.
/// Fournit Id (Guid) et timestamps de création/modification.
/// </summary>
public abstract class BaseEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();

    // ✅ Keep ONE set of audit fields
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public string? CreatedBy { get; set; }
    public string? ModifiedBy { get; set; }

    // Remove duplicates - they're confusing and waste database space
    public DateTime CreatedOn { get; set; } = DateTime.UtcNow;
    public DateTime? ModifiedOn { get; set; }
}
