namespace SalesFlow.Application.Common.Security;

/// <summary>
/// Abstraction de l'utilisateur authentifié.
/// Permet aux services de connaître l'UserId sans dépendre de HttpContext (testable).
/// </summary>
public interface ICurrentUser
{
    Guid? UserId { get; }
    bool IsAuthenticated { get; }
}
