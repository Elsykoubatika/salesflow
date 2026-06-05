namespace SalesFlow.Domain.Entities;

/// <summary>
/// Événement déclenché par une interaction avec un lien de partage.
///
/// EventType :
///   - "Click" : quelqu'un a cliqué le lien (déclenche le redirect)
///   - "Lead"  : un contact a été capté (formulaire, demande info…)
///   - "Sale"  : une commande a été passée via ce lien
///   - "Share" : l'affilié a partagé son lien (compté à la création du DealShare)
///
/// Une commission peut être calculée à chaque événement selon le
/// CommissionType du Deal parent.
/// </summary>
public class DealEvent
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid DealShareId { get; set; }

    /// <summary>"Click" | "Lead" | "Sale" | "Share"</summary>
    public string EventType { get; set; } = "Click";

    /// <summary>Si EventType == "Sale" : montant de la vente.</summary>
    public decimal? SaleAmount { get; set; }

    /// <summary>Si EventType == "Sale" : référence de la commande.</summary>
    public Guid? OrderId { get; set; }

    /// <summary>Commission calculée pour cet événement (cache de calcul).</summary>
    public decimal? CommissionEarned { get; set; }

    /// <summary>Hash de l'IP pour anti-fraude basique (dédup clics).</summary>
    public string? IpHash { get; set; }

    /// <summary>User-Agent pour distinguer bot/humain.</summary>
    public string? UserAgent { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
