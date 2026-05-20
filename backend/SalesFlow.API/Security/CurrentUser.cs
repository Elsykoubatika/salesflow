using System.Security.Claims;
using SalesFlow.Application.Common.Security;

namespace SalesFlow.API.Security;

/// <summary>
/// Lit l'identité depuis HttpContext (extraite du JWT par le middleware d'authentification).
/// </summary>
public class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUser(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public bool IsAuthenticated =>
        _httpContextAccessor.HttpContext?.User.Identity?.IsAuthenticated == true;

    public Guid? UserId
    {
        get
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user is null) return null;

            // Le JWT middleware mappe par défaut "sub" → ClaimTypes.NameIdentifier.
            // On cherche les deux par sécurité.
            var raw = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? user.FindFirst("sub")?.Value;

            return Guid.TryParse(raw, out var id) ? id : null;
        }
    }
}
