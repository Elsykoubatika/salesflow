

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Inventory.DTOs;
using SalesFlow.Application.Inventory.Services;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/inventory")]
[Authorize]
[Tags("Inventory")]
[Produces("application/json")]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _service;

    public InventoryController(IInventoryService service)
    {
        _service = service;
    }

    // ===== ITEMS ENDPOINTS =====

    /// <summary>
    /// Liste paginée des articles en stock.
    /// Optionnellement filtrer les articles en rupture de stock.
    /// </summary>
    [HttpGet("items")]
    [ProducesResponseType(typeof(InventoryListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ListItems(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] bool lowStockOnly = false,
        CancellationToken ct = default)
    {
        var result = await _service.ListItemsAsync(page, pageSize, lowStockOnly, ct);

        return result.IsSuccess
            ? Ok(result.Value)
            : BadRequest(new { error = result.Error });
    }

    /// <summary>
    /// Récupère les détails d'un article en stock (métadonnées + historique des mouvements).
    /// </summary>
    [HttpGet("items/{id:guid}")]
    [ProducesResponseType(typeof(InventoryItemResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetItem(Guid id, CancellationToken ct = default)
    {
        var result = await _service.GetItemByIdAsync(id, ct);

        return result.IsSuccess
            ? Ok(result.Value)
            : NotFound(new { error = result.Error });
    }

    /// <summary>
    /// Crée un nouvel article en stock.
    /// Si InitialQuantity > 0, un mouvement d'entrée initiale est enregistré automatiquement.
    /// </summary>
    [HttpPost("items")]
    [ProducesResponseType(typeof(InventoryItemResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateItem(
        [FromBody] CreateInventoryItemRequest request,
        CancellationToken ct = default)
    {
        var result = await _service.CreateItemAsync(request, ct);

        if (!result.IsSuccess)
            return BadRequest(new { error = result.Error });

        return CreatedAtAction(nameof(GetItem), new { id = result.Value!.Id }, result.Value);
    }

    /// <summary>
    /// Met à jour les métadonnées d'un article en stock.
    /// NOTE: La quantité ne peut être modifiée que via des mouvements de stock (POST /movements).
    /// </summary>
    [HttpPut("items/{id:guid}")]
    [ProducesResponseType(typeof(InventoryItemResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateItem(
        Guid id,
        [FromBody] UpdateInventoryItemRequest request,
        CancellationToken ct = default)
    {
        var result = await _service.UpdateItemAsync(id, request, ct);

        if (!result.IsSuccess)
            return result.Error!.Contains("introuvable")
                ? NotFound(new { error = result.Error })
                : BadRequest(new { error = result.Error });

        return Ok(result.Value);
    }

    /// <summary>
    /// Supprime un article en stock (et tous ses mouvements associés).
    /// Cette opération est irréversible.
    /// </summary>
    [HttpDelete("items/{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteItem(Guid id, CancellationToken ct = default)
    {
        var result = await _service.DeleteItemAsync(id, ct);

        return result.IsSuccess
            ? NoContent()
            : NotFound(new { error = result.Error });
    }

    // ===== MOVEMENTS ENDPOINTS =====

    /// <summary>
    /// Enregistre un mouvement de stock (entrée ou sortie).
    /// 
    /// Change > 0 = Entrée (achat, retour...)
    /// Change < 0 = Sortie (vente, perte...)
    /// 
    /// La quantité de l'article est mise à jour automatiquement.
    /// </summary>
    [HttpPost("movements")]
    [ProducesResponseType(typeof(InventoryMovementResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RecordMovement(
        [FromBody] CreateInventoryMovementRequest request,
        CancellationToken ct = default)
    {
        // ✅ Validation: Change ne peut pas être zéro
        if (request.Change == 0)
            return BadRequest(new { error = "Le changement de quantité ne peut pas être zéro." });

        var result = await _service.RecordMovementAsync(request, ct);

        if (!result.IsSuccess)
        {
            return result.Error!.Contains("introuvable")
                ? NotFound(new { error = result.Error })
                : BadRequest(new { error = result.Error });
        }

        return CreatedAtAction(nameof(GetMovements),
            new { inventoryItemId = request.InventoryItemId },
            result.Value);
    }

    /// <summary>
    /// Récupère tous les mouvements d'un article en stock (audit trail complet).
    /// Triés par date décroissante (mouvements les plus récents en premier).
    /// </summary>
    [HttpGet("items/{inventoryItemId:guid}/movements")]
    [ProducesResponseType(typeof(InventoryMovementListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMovements(
        Guid inventoryItemId,
        CancellationToken ct = default)
    {
        var result = await _service.GetMovementsAsync(inventoryItemId, ct);

        return result.IsSuccess
            ? Ok(result.Value)
            : NotFound(new { error = result.Error });
    }

    // ===== ANALYTICS ENDPOINTS =====

    /// <summary>
    /// Récupère tous les articles en rupture de stock
    /// (Quantity ≤ ReorderThreshold).
    /// Triés par quantité (les plus critiques en premier).
    /// </summary>
    [HttpGet("alerts/low-stock")]
    [ProducesResponseType(typeof(IEnumerable<InventoryItemResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLowStockAlerts(CancellationToken ct = default)
    {
        var result = await _service.GetLowStockItemsAsync(ct);

        return result.IsSuccess
            ? Ok(result.Value)
            : BadRequest(new { error = result.Error });
    }

    /// <summary>
    /// Récupère la valeur totale du stock en inventaire.
    /// Calcul: ∑(Cost × Quantity) pour tous les articles actifs avec un coût défini.
    /// </summary>
    [HttpGet("analytics/total-value")]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTotalStockValue(CancellationToken ct = default)
    {
        var result = await _service.GetTotalStockValueAsync(ct);

        if (!result.IsSuccess)
            return BadRequest(new { error = result.Error });

        return Ok(new { totalValue = result.Value, currency = "XAF" });
    }
}