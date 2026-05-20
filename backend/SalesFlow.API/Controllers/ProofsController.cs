using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Proofs.DTOs;
using SalesFlow.Application.Proofs.Services;
using SalesFlow.Domain.Enums;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/proofs")]
[Authorize]
public class ProofsController : ControllerBase
{
    private readonly IProofService _service;

    public ProofsController(IProofService service)
    {
        _service = service;
    }

    /// <summary>Liste paginée des preuves. Filtres optionnels par statut, client, commande.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ProofListResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] ProofStatus? status = null,
        [FromQuery] Guid? clientId = null,
        [FromQuery] Guid? salesOrderId = null,
        CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, status, clientId, salesOrderId, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    /// <summary>Métadonnées d'une preuve (sans l'image).</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ProofResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _service.GetByIdAsync(id, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    /// <summary>Téléchargement de l'image binaire de la preuve.</summary>
    [HttpGet("{id:guid}/image")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetImage(Guid id, CancellationToken ct)
    {
        var result = await _service.GetImageAsync(id, ct);
        if (!result.IsSuccess) return NotFound(new { error = result.Error });

        return File(result.Value!.Bytes, result.Value!.ContentType);
    }

    /// <summary>
    /// Upload d'une preuve. Multipart/form-data avec :
    /// - file : l'image (champ "file")
    /// - data : JSON des métadonnées (champ "data")
    /// </summary>
    [HttpPost]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ProofResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10 MB max au niveau HTTP
    public async Task<IActionResult> Upload(
        [FromForm] UploadProofForm form,
        CancellationToken ct)
    {
        if (form.File is null || form.File.Length == 0)
            return BadRequest(new { error = "Fichier image manquant ou vide." });

        if (string.IsNullOrWhiteSpace(form.Data))
            return BadRequest(new { error = "Métadonnées manquantes." });

        // Désérialiser les métadonnées JSON
        CreateProofRequest request;
        try
        {
            request = JsonSerializer.Deserialize<CreateProofRequest>(form.Data, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            }) ?? throw new InvalidOperationException("Métadonnées invalides.");
        }
        catch (JsonException ex)
        {
            return BadRequest(new { error = $"JSON invalide : {ex.Message}" });
        }

        // Lire le fichier en mémoire
        using var ms = new MemoryStream();
        await form.File.CopyToAsync(ms, ct);
        var bytes = ms.ToArray();

        var result = await _service.CreateAsync(request, bytes, form.File.ContentType, ct);
        if (!result.IsSuccess) return BadRequest(new { error = result.Error });

        return CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value);
    }

    /// <summary>DTO multipart pour upload d'une preuve. Regroupé dans une classe pour Swashbuckle.</summary>
    public class UploadProofForm
    {
        /// <summary>Image de la preuve (JPEG, PNG, WebP, max 5 MB).</summary>
        public IFormFile File { get; set; } = null!;

        /// <summary>JSON sérialisé des métadonnées (CreateProofRequest).</summary>
        public string Data { get; set; } = string.Empty;
    }


    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ProofResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateProofRequest request, CancellationToken ct)
    {
        var result = await _service.UpdateAsync(id, request, ct);
        if (result.IsSuccess) return Ok(result.Value);
        return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var result = await _service.DeleteAsync(id, ct);
        return result.IsSuccess ? NoContent() : NotFound(new { error = result.Error });
    }
}
