using Microsoft.AspNetCore.Mvc;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    /// <summary>
    /// Endpoint de healthcheck. Aucune authentification requise.
    /// Utile pour : monitoring, load balancers, smoke tests CI/CD.
    /// </summary>
    [HttpGet]
    public IActionResult Get() => Ok(new
    {
        status = "ok",
        timestamp = DateTime.UtcNow,
        service = "SalesFlow Pro Congo API",
        version = "0.1.0"
    });
}
