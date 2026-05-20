using SalesFlow.Domain.Enums;

namespace SalesFlow.Domain.Common;

/// <summary>
/// Règles de transition entre statuts d'un SalesOrder.
/// Centralisé ici pour qu'aucune transition invalide ne puisse passer en base.
/// </summary>
public static class SalesOrderStatusMachine
{
    public static bool CanTransition(SalesOrderStatus from, SalesOrderStatus to)
    {
        // Pas de transition vers soi-même
        if (from == to) return false;

        return (from, to) switch
        {
            // Depuis Draft : envoyer ou annuler
            (SalesOrderStatus.Draft, SalesOrderStatus.Sent)      => true,
            (SalesOrderStatus.Draft, SalesOrderStatus.Cancelled) => true,

            // Depuis Sent (devis envoyé) : accepté / refusé / annulé
            (SalesOrderStatus.Sent, SalesOrderStatus.Accepted)  => true,
            (SalesOrderStatus.Sent, SalesOrderStatus.Rejected)  => true,
            (SalesOrderStatus.Sent, SalesOrderStatus.Cancelled) => true,

            // Depuis Accepted : livrer ou annuler
            (SalesOrderStatus.Accepted, SalesOrderStatus.Delivered) => true,
            (SalesOrderStatus.Accepted, SalesOrderStatus.Cancelled) => true,

            // Depuis Delivered : encaisser ou annuler (geste commercial)
            (SalesOrderStatus.Delivered, SalesOrderStatus.Paid)      => true,
            (SalesOrderStatus.Delivered, SalesOrderStatus.Cancelled) => true,

            // Paid / Rejected / Cancelled : statuts terminaux, plus de transition possible
            _ => false
        };
    }

    /// <summary>Liste les statuts autorisés depuis le statut courant (utile pour l'UI).</summary>
    public static IEnumerable<SalesOrderStatus> AllowedFrom(SalesOrderStatus current)
    {
        foreach (SalesOrderStatus s in Enum.GetValues(typeof(SalesOrderStatus)))
        {
            if (CanTransition(current, s)) yield return s;
        }
    }
}
