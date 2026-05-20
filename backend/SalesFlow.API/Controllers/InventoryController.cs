using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Inventory.DTOs;
using SalesFlow.Application.Inventory.Services;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/inventory")]
[Authorize]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _service;

    public InventoryController(IInventoryService service)
    {
        _service = service;
    }

    /// <summary>Liste paginée du stock. Filtres : recherche, lowStockOnly, activeOnly.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(InventoryListResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] bool? lowStockOnly = null,
        [FromQuery] bool? activeOnly = null,
        CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, search, lowStockOnly, activeOnly, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    /// <summary>Raccourci : tous les articles actifs sous le seuil d'alerte.</summary>
    [HttpGet("alerts")]
    [ProducesResponseType(typeof(InventoryListResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Alerts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, null, lowStockOnly: true, activeOnly: true, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    /// <summary>Détail d'un article + 20 derniers mouvements de stock.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(InventoryItemDetailResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _service.GetByIdAsync(id, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    /// <summary>Crée un article. Si initialQuantity > 0, génère un mouvement « InitialStock ».</summary>
    [HttpPost]
    [ProducesResponseType(typeof(InventoryItemResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateInventoryItemRequest request, CancellationToken ct)
    {
        var result = await _service.CreateAsync(request, ct);
        if (!result.IsSuccess) return BadRequest(new { error = result.Error });
        return CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value);
    }

    /// <summary>
    /// Met à jour l'article (nom, seuil, coût, lien produit).
    /// La quantité ne se modifie PAS via cet endpoint — utiliser /adjust.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(InventoryItemResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateInventoryItemRequest request, CancellationToken ct)
    {
        var result = await _service.UpdateAsync(id, request, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    /// <summary>
    /// Ajuste la quantité par un delta (positif ou négatif). Crée un mouvement traçable.
    /// Le serveur refuse si la nouvelle quantité serait négative.
    /// </summary>
    [HttpPost("{id:guid}/adjust")]
    [ProducesResponseType(typeof(InventoryItemResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Adjust(Guid id, [FromBody] AdjustInventoryRequest request, CancellationToken ct)
    {
        var result = await _service.AdjustAsync(id, request, ct);
        if (result.IsSuccess) return Ok(result.Value);
        return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
    }

    /// <summary>Désactive l'article (soft delete). Préserve l'historique des mouvements.</summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var result = await _service.SoftDeleteAsync(id, ct);
        return result.IsSuccess ? NoContent() : NotFound(new { error = result.Error });
    }
}
