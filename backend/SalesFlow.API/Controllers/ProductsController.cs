using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Catalog.DTOs;
using SalesFlow.Application.Catalog.Services;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IProductService _service;

    public ProductsController(IProductService service)
    {
        _service = service;
    }

    /// <summary>Liste paginée des produits du catalogue.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ProductListResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] bool? activeOnly = null,
        CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, search, activeOnly, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ProductResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _service.GetByIdAsync(id, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    [HttpPost]
    [ProducesResponseType(typeof(ProductResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateProductRequest request, CancellationToken ct)
    {
        var result = await _service.CreateAsync(request, ct);
        if (!result.IsSuccess) return BadRequest(new { error = result.Error });
        return CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ProductResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateProductRequest request, CancellationToken ct)
    {
        var result = await _service.UpdateAsync(id, request, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var result = await _service.DeleteAsync(id, ct);
        return result.IsSuccess ? NoContent() : NotFound(new { error = result.Error });
    }

    /// <summary>
    /// Génère un lien WhatsApp pré-rempli (wa.me) à partager aux clients.
    /// Le lien ouvre WhatsApp avec un message d'intérêt pré-rédigé pour ce produit.
    /// </summary>
    /// <param name="id">Id du produit</param>
    /// <param name="customMessage">Message personnalisé optionnel. Si vide, un message par défaut est généré.</param>
    [HttpGet("{id:guid}/whatsapp-link")]
    [ProducesResponseType(typeof(WhatsAppLinkResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> WhatsAppLink(Guid id, [FromQuery] string? customMessage, CancellationToken ct)
    {
        var result = await _service.GenerateWhatsAppLinkAsync(id, customMessage, ct);
        if (result.IsSuccess) return Ok(result.Value);
        return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
    }
}
