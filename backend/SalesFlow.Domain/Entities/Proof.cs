using SalesFlow.Domain.Common;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Preuve de paiement Mobile Money (capture d'écran ou SMS).
/// L'image est stockée directement en base (bytea) pour le MVP.
/// Migration vers Azure Blob Storage prévue quand le volume le justifiera.
/// </summary>
public class Proof : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    // ─── Métadonnées de l'image ──────────────────────────────────────────────

    /// <summary>Image binaire (JPEG/PNG). Taille max 5 MB, contrainte au niveau API.</summary>
    public byte[] ImageBytes { get; set; } = Array.Empty<byte>();
    public string ImageContentType { get; set; } = "image/jpeg";
    public int ImageSizeBytes { get; set; }

    // ─── Champs métier saisis manuellement ───────────────────────────────────

    public decimal? Amount { get; set; }
    public string Currency { get; set; } = "XAF";
    public string? TransactionReference { get; set; }
    public MobileMoneyOperator Operator { get; set; } = MobileMoneyOperator.Other;
    public DateTime? TransactionDate { get; set; }
    public string? Notes { get; set; }

    // ─── État + liens ────────────────────────────────────────────────────────

    public ProofStatus Status { get; set; } = ProofStatus.Pending;
    public string? ErrorMessage { get; set; }

    /// <summary>Client associé (optionnel).</summary>
    public Guid? ClientId { get; set; }
    public Client? Client { get; set; }

    /// <summary>Devis/commande associé (optionnel — typiquement la facture qu'on encaisse).</summary>
    public Guid? SalesOrderId { get; set; }
    public SalesOrder? SalesOrder { get; set; }
}
