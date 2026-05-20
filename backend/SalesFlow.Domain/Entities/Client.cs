using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

/// <summary>
/// Client final du commerçant ou technicien.
/// Référencé par les commandes, devis, rappels, etc.
/// </summary>
public class Client : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string FullName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? Region { get; set; }    // Ex: Talangaï, Poto-Poto - utile pour la logistique collaborative
    public string? Notes { get; set; }
}
