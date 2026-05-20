namespace SalesFlow.Domain.Enums;

/// <summary>
/// Raison d'un mouvement de stock. Sert au reporting et à l'audit.
/// </summary>
public enum MovementReason
{
    /// <summary>Réapprovisionnement / livraison fournisseur (entrée).</summary>
    Restock = 1,

    /// <summary>Vente à un client (sortie).</summary>
    Sale = 2,

    /// <summary>Retour client (entrée).</summary>
    Return = 3,

    /// <summary>Ajustement manuel suite à inventaire physique (entrée ou sortie).</summary>
    Adjustment = 4,

    /// <summary>Perte / casse / vol (sortie).</summary>
    Loss = 5,

    /// <summary>État initial à la création de l'article (entrée).</summary>
    InitialStock = 6
}
