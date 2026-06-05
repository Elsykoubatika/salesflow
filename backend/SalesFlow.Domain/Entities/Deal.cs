namespace SalesFlow.Domain.Entities;

/// <summary>
/// Un Deal = une proposition d'affiliation faite par un vendeur (le créateur).
///
/// Soit attaché à un produit existant du catalogue (ProductId renseigné),
/// soit une "campagne libre" sans produit (ex : "fais venir des clients dans
/// mon magasin").
///
/// Le créateur définit une commission (CPC, CPS, CPA ou CPL) et les
/// conditions pour la gagner. D'autres utilisateurs ("affiliés") peuvent
/// partager le deal via des liens trackés.
/// </summary>
public class Deal
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>Le vendeur qui propose le deal.</summary>
    public Guid CreatorUserId { get; set; }

    /// <summary>Produit lié, optionnel (campagne libre si null).</summary>
    public Guid? ProductId { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>URLs séparées par ';' — kit marketing partageable.</summary>
    public string? ContentImages { get; set; }
    public string? ContentMaterials { get; set; }

    /// <summary>"CPC" | "CPS" | "CPA" | "CPL"</summary>
    public string CommissionType { get; set; } = "CPA";

    /// <summary>Montant fixe en valeur monétaire (si pas un pourcentage).</summary>
    public decimal? CommissionAmount { get; set; }

    /// <summary>Pourcentage du prix de vente (alternative à CommissionAmount).</summary>
    public decimal? CommissionPercent { get; set; }

    public string Currency { get; set; } = "XAF";

    /// <summary>Texte libre décrivant les conditions pour gagner la commission.</summary>
    public string? Conditions { get; set; }

    /// <summary>Stock dédié à l'opération (optionnel).</summary>
    public int? StockAvailable { get; set; }

    public DateTime ActiveFrom { get; set; } = DateTime.UtcNow;
    public DateTime? ActiveTo { get; set; }

    /// <summary>"Draft" | "Active" | "Paused" | "Closed"</summary>
    public string Status { get; set; } = "Active";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime? UpdatedAt { get; set; }
}
