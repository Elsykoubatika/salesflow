using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Article en stock physique du marchand.
/// La quantité ne se modifie JAMAIS directement — uniquement via InventoryMovement.
/// </summary>
public class InventoryItem : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Sku { get; set; }
    public string? Description { get; set; }

    /// <summary>Unité de mesure : "pcs", "kg", "L", "m", "h"...</summary>
    public string Unit { get; set; } = "pcs";

    /// <summary>Quantité courante en stock. Modifiée via mouvements uniquement.</summary>
    public decimal Quantity { get; set; }

    /// <summary>Seuil d'alerte. Si Quantity ≤ ce seuil, l'article apparaît dans /alerts.</summary>
    public decimal? ReorderThreshold { get; set; }

    /// <summary>Prix d'achat unitaire — base du calcul de rentabilité.</summary>
    public decimal? Cost { get; set; }

    /// <summary>Date du dernier mouvement (positif ou négatif).</summary>
    public DateTime? LastMovementAt { get; set; }

    /// <summary>Lien optionnel vers un produit du catalogue.</summary>
    public Guid? ProductId { get; set; }
    public Product? Product { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<InventoryMovement> Movements { get; set; } = new List<InventoryMovement>();

    public bool IsLowStock => ReorderThreshold.HasValue && Quantity <= ReorderThreshold.Value;
    public decimal? StockValue => Cost.HasValue ? Cost.Value * Quantity : null;
}
