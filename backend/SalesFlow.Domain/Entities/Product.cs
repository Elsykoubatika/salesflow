using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Produit ou service du catalogue, partageable via WhatsApp.
/// </summary>
public class Product : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>Prix unitaire dans la devise du marchand.</summary>
    public decimal Price { get; set; }

    /// <summary>Code ISO devise. Défaut XAF (franc CFA d'Afrique Centrale).</summary>
    public string Currency { get; set; } = "XAF";

    /// <summary>URL de l'image (Azure Blob / S3). Phase ultérieure.</summary>
    public string? ImageUrl { get; set; }

    /// <summary>JSON sérialisé pour variantes (tailles/couleurs). Optionnel.</summary>
    public string? VariantsJson { get; set; }

    /// <summary>Code SKU/référence interne du marchand.</summary>
    public string? Sku { get; set; }

    /// <summary>
    /// Si false, le produit est masqué (rupture, retiré du catalogue)
    /// mais l'historique des commandes est préservé.
    /// </summary>
    public bool IsActive { get; set; } = true;
}
