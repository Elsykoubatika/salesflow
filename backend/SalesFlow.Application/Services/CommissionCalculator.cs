using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Services;

/// <summary>
/// Calcule la commission gagnée pour un événement selon le type de Deal.
///
/// Règles :
///   - CPC (Cost Per Click)  : commission par Click event
///   - CPS (Cost Per Share)  : commission par Share event
///   - CPA (Cost Per Action) : commission par Sale event finalisé
///   - CPL (Cost Per Lead)   : commission par Lead event
///
/// Si CommissionPercent est défini, on l'applique au SaleAmount.
/// Sinon on retourne CommissionAmount.
/// </summary>
public static class CommissionCalculator
{
    public static decimal Calculate(Deal deal, DealEvent evt)
    {
        // L'événement ne correspond pas au type de commission → 0
        var typeMatchesEvent = deal.CommissionType switch
        {
            "CPC" => evt.EventType == "Click",
            "CPS" => evt.EventType == "Share",
            "CPA" => evt.EventType == "Sale",
            "CPL" => evt.EventType == "Lead",
            _ => false,
        };
        if (!typeMatchesEvent) return 0m;

        // Pourcentage de la vente (CPA uniquement)
        if (deal.CommissionPercent.HasValue
            && evt.EventType == "Sale"
            && evt.SaleAmount.HasValue)
        {
            return Math.Round(
                evt.SaleAmount.Value * (deal.CommissionPercent.Value / 100m),
                0);
        }

        // Montant fixe
        return deal.CommissionAmount ?? 0m;
    }
}
