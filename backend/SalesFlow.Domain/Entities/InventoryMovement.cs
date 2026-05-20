using SalesFlow.Domain.Common;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Mouvement de stock (entrée ou sortie). Audit trail complet,
/// jamais modifié après création.
/// </summary>
public class InventoryMovement : BaseEntity
{
    public Guid InventoryItemId { get; set; }
    public InventoryItem? InventoryItem { get; set; }

    /// <summary>Variation : positif = entrée, négatif = sortie.</summary>
    public decimal Change { get; set; }

    public MovementReason Reason { get; set; }

    /// <summary>Quantité résultante après application — snapshot pour audit.</summary>
    public decimal ResultingQuantity { get; set; }

    public string? Note { get; set; }

    /// <summary>Pour traçabilité : quel SalesOrder a déclenché ce mouvement (si applicable).</summary>
    public Guid? SalesOrderId { get; set; }
}
