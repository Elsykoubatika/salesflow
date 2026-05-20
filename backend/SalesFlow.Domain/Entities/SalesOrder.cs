using SalesFlow.Domain.Common;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Devis / commande / facture — un même document qui évolue dans le pipeline.
/// Le statut détermine s'il est rendu en PDF comme un devis, un BC ou une facture.
/// </summary>
public class SalesOrder : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    /// <summary>Numéro lisible : "SF-2026-0001". Unique par marchand.</summary>
    public string OrderNumber { get; set; } = string.Empty;

    public SalesOrderStatus Status { get; set; } = SalesOrderStatus.Draft;

    public string Currency { get; set; } = "XAF";

    /// <summary>Total HT (somme des lignes). Calculé serveur, jamais accepté du client.</summary>
    public decimal Subtotal { get; set; }

    /// <summary>Montant de TVA. À 0 par défaut (pas de TVA pour micro-marchand).</summary>
    public decimal TaxAmount { get; set; }

    /// <summary>Total TTC (Subtotal + TaxAmount).</summary>
    public decimal Total { get; set; }

    public string? Notes { get; set; }

    /// <summary>Date d'expiration du devis (optionnel).</summary>
    public DateTime? ExpiresAt { get; set; }

    public DateTime? SentAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? CancelledAt { get; set; }

    /// <summary>Raison de refus/annulation, fournie lors de la transition.</summary>
    public string? CancellationReason { get; set; }

    public ICollection<SalesOrderItem> Items { get; set; } = new List<SalesOrderItem>();

    /// <summary>
    /// Recalcule Subtotal / Total à partir des lignes. Appelé avant chaque save.
    /// </summary>
    public void Recalculate()
    {
        Subtotal = Items.Sum(i => i.UnitPrice * i.Quantity);
        Total = Subtotal + TaxAmount;
    }

    public bool IsEditable => Status == SalesOrderStatus.Draft;
    public bool IsTerminal => Status is SalesOrderStatus.Paid
                                       or SalesOrderStatus.Rejected
                                       or SalesOrderStatus.Cancelled;
}
