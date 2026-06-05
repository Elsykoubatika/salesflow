namespace SalesFlow.Domain.Entities;

/// <summary>
/// Un partage = quand un affilié décide de partager un Deal sur un canal
/// donné (WhatsApp, Facebook, Instagram, Direct…). Chaque partage a son
/// propre UniqueCode utilisé pour tracker les clics, leads, ventes.
///
/// L'URL générée : https://dealflow.app/d/{UniqueCode}
///
/// (Triplet logique de tracking : Deal × Affilié × Canal)
/// </summary>
public class DealShare
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid DealId { get; set; }

    /// <summary>L'utilisateur qui partage (= l'affilié).</summary>
    public Guid AffiliateUserId { get; set; }

    /// <summary>"WhatsApp" | "Facebook" | "Instagram" | "Direct" | "Own"</summary>
    public string Channel { get; set; } = "Direct";

    /// <summary>Slug court alphanumérique unique (ex : "x7k2m9").</summary>
    public string UniqueCode { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
