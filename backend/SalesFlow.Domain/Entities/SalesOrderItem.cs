using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Ligne d'un devis/commande. Contient un snapshot du prix et description
/// au moment de la création, indépendant des modifications futures du produit.
/// </summary>
public class SalesOrderItem : BaseEntity
{
    public Guid SalesOrderId { get; set; }
    public SalesOrder? SalesOrder { get; set; }

    /// <summary>
    /// Lien vers un produit du catalogue (optionnel).
    /// Permet une ligne libre — par ex. "main d'œuvre 2h" — sans produit catalogue.
    /// </summary>
    public Guid? ProductId { get; set; }
    public Product? Product { get; set; }

    /// <summary>Description figée — copiée du Product.Name au moment de la création.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>Prix unitaire figé.</summary>
    public decimal UnitPrice { get; set; }

    /// <summary>Quantité (peut être décimale : ex. 2.5 heures, 1.75 m).</summary>
    public decimal Quantity { get; set; } = 1;

    public string? Notes { get; set; }

    public decimal LineTotal => UnitPrice * Quantity;
}
