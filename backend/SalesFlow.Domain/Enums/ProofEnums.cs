namespace SalesFlow.Domain.Enums;

/// <summary>Opérateur Mobile Money utilisé pour la transaction.</summary>
public enum MobileMoneyOperator
{
    Other = 0,
    MtnMomo = 1,
    AirtelMoney = 2
}

/// <summary>État d'une preuve dans le coffre-fort.</summary>
public enum ProofStatus
{
    /// <summary>En attente de validation manuelle par le marchand.</summary>
    Pending = 0,

    /// <summary>Validée et associée à une transaction.</summary>
    Validated = 1,

    /// <summary>Marquée en erreur (montant incohérent, doublon, etc.).</summary>
    Error = 2
}
