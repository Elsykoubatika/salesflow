namespace SalesFlow.Domain.Enums;

/// <summary>
/// Statut d'un devis/commande dans le pipeline de vente.
/// Un même document évolue : Draft (devis brouillon) → Sent (devis envoyé)
///   → Accepted (commande confirmée) → Delivered → Paid.
/// </summary>
public enum SalesOrderStatus
{
    /// <summary>Brouillon — modifiable, pas encore envoyé au client.</summary>
    Draft = 0,

    /// <summary>Envoyé au client en tant que devis. En attente de réponse.</summary>
    Sent = 1,

    /// <summary>Accepté par le client → devient une commande à honorer.</summary>
    Accepted = 2,

    /// <summary>Livré / prestation effectuée. En attente de paiement.</summary>
    Delivered = 3,

    /// <summary>Payé. Étape finale du flux nominal.</summary>
    Paid = 4,

    /// <summary>Refusé par le client (depuis Sent). Terminal.</summary>
    Rejected = 5,

    /// <summary>Annulé (par le marchand ou client). Terminal.</summary>
    Cancelled = 6
}
