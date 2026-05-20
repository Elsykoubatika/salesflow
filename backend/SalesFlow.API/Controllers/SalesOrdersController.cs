using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Documents.Services;
using SalesFlow.Application.Sales.DTOs;
using SalesFlow.Application.Sales.Services;
using SalesFlow.Domain.Enums;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/sales-orders")]
[Authorize]
public class SalesOrdersController : ControllerBase
{
    private readonly ISalesOrderService _service;
    private readonly IDocumentGenerator _docGenerator;

    public SalesOrdersController(ISalesOrderService service, IDocumentGenerator docGenerator)
    {
        _service = service;
        _docGenerator = docGenerator;
    }

    /// <summary>Liste paginée des devis/commandes. Filtres optionnels par statut et client.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(SalesOrderListResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] SalesOrderStatus? status = null,
        [FromQuery] Guid? clientId = null,
        CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, status, clientId, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    /// <summary>Détail complet, avec lignes et transitions possibles.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(SalesOrderResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _service.GetByIdAsync(id, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    /// <summary>Crée un nouveau devis (statut Draft) avec ses lignes.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(SalesOrderResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateSalesOrderRequest request, CancellationToken ct)
    {
        var result = await _service.CreateAsync(request, ct);
        if (!result.IsSuccess) return BadRequest(new { error = result.Error });
        return CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value);
    }

    /// <summary>Modifie un brouillon. Refuse si déjà envoyé (utiliser une transition).</summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(SalesOrderResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateSalesOrderRequest request, CancellationToken ct)
    {
        var result = await _service.UpdateAsync(id, request, ct);
        if (result.IsSuccess) return Ok(result.Value);
        return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
    }

    /// <summary>
    /// Change le statut du document (envoyer un devis, accepter, livrer, encaisser...).
    /// Le serveur valide la transition selon la machine à états.
    /// </summary>
    [HttpPost("{id:guid}/transition")]
    [ProducesResponseType(typeof(SalesOrderResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Transition(Guid id, [FromBody] TransitionSalesOrderRequest request, CancellationToken ct)
    {
        var result = await _service.TransitionAsync(id, request, ct);
        if (result.IsSuccess) return Ok(result.Value);
        return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
    }

    /// <summary>Supprime un brouillon. Pour annuler un document envoyé, utiliser la transition Cancelled.</summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var result = await _service.DeleteAsync(id, ct);
        if (result.IsSuccess) return NoContent();
        return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
    }

    /// <summary>
    /// Télécharge le PDF du devis/facture. Le titre du document varie selon le statut :
    /// Devis (Draft/Sent), Bon de commande (Accepted), Facture (Delivered/Paid).
    /// </summary>
    [HttpGet("{id:guid}/pdf")]
    [Produces("application/pdf")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DownloadPdf(Guid id, CancellationToken ct)
    {
        var result = await _docGenerator.GenerateSalesOrderPdfAsync(id, ct);
        if (!result.IsSuccess)
            return NotFound(new { error = result.Error });

        var doc = result.Value!;
        return File(doc.Bytes, doc.ContentType, doc.FileName);
    }
}
