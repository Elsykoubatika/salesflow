using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Proofs.DTOs;
using SalesFlow.Application.Proofs.Services;
using SalesFlow.Domain.Enums;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/proofs")]
[Authorize]
[Tags("Proofs")]
[Produces("application/json")]
public class ProofsController : ControllerBase
{
    private readonly IProofService _service;
    private const int MaxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
    public ProofsController(IProofService service)
    {
        _service = service;
    }

    /// <summary>
    /// Liste paginée des preuves avec filtres optionnels.
    /// Exclut les données d'image pour la performance.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ProofListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null,
        [FromQuery] Guid? clientId = null,
        [FromQuery] Guid? salesOrderId = null,
        CancellationToken ct = default)
    {
        // ✅ Convertir string status en enum
        ProofStatus? proofStatus = null;
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (Enum.TryParse<ProofStatus>(status, ignoreCase: true, out var parsed))
                proofStatus = parsed;
            else
                return BadRequest(new { error = $"Statut invalide : {status}. Utilisez : Pending, Validated, Error." });
        }

        var result = await _service.ListAsync(page, pageSize, proofStatus, clientId, salesOrderId, ct);

        return result.IsSuccess
            ? Ok(result.Value)
            : BadRequest(new { error = result.Error });
    }

    /// <summary>
    /// Récupère les métadonnées d'une preuve (sans l'image).
    /// Pour obtenir l'image, utilisez GET /api/proofs/{id}/image
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ProofResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct = default)
    {
        var result = await _service.GetByIdAsync(id, ct);

        return result.IsSuccess
            ? Ok(result.Value)
            : NotFound(new { error = result.Error });
    }

    /// <summary>
    /// Télécharge l'image d'une preuve (JPEG, PNG, ou WebP).
    /// Retourne le fichier binaire avec le bon Content-Type.
    /// </summary>
    [HttpGet("{id:guid}/image")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [Produces("image/jpeg", "image/png", "image/webp")]
    public async Task<IActionResult> GetImage(Guid id, CancellationToken ct = default)
    {
        var result = await _service.GetImageAsync(id, ct);

        if (!result.IsSuccess)
        {
            return result.Error!.Contains("introuvable")
                ? NotFound(new { error = result.Error })
                : BadRequest(new { error = result.Error });
        }

        var (imageBytes, contentType) = (result.Value!.ImageBytes, result.Value!.ContentType);

        return File(imageBytes, contentType, $"proof-{id}.{GetImageExtension(contentType)}");
    }

    /// <summary>
    /// Upload une nouvelle preuve de paiement avec image.
    /// 
    /// Body (multipart/form-data):
    /// - image: fichier image (JPEG/PNG/WebP, max 5 MB) - REQUIS
    /// - amount: montant de la transaction (decimal) - OPTIONNEL
    /// - currency: devise (ex: XAF) - OPTIONNEL (défaut: XAF)
    /// - transactionReference: numéro de transaction - OPTIONNEL
    /// - operator: opérateur mobile money (0=Other, 1=MTN, 2=Airtel) - OPTIONNEL
    /// - transactionDate: date de la transaction (datetime) - OPTIONNEL
    /// - notes: notes supplémentaires - OPTIONNEL
    /// - clientId: ID du client associé - OPTIONNEL
    /// - salesOrderId: ID de la commande associée - OPTIONNEL
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ProofResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status413PayloadTooLarge)]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Upload(
    IFormFile image,                                  // ✅ PAS de [FromForm] ici!
    [FromForm] decimal? amount = null,
    [FromForm] string? currency = null,
    [FromForm] string? transactionReference = null,
    [FromForm] int? @operator = null,
    [FromForm] DateTime? transactionDate = null,
    [FromForm] string? notes = null,
    [FromForm] Guid? clientId = null,
    [FromForm] Guid? salesOrderId = null,
    CancellationToken ct = default)
    {
        // ✅ Validation: image requise
        if (image == null || image.Length == 0)
            return BadRequest(new { error = "Image requise." });

        // ✅ Validation: taille max
        if (image.Length > MaxImageSizeBytes)
            return StatusCode(StatusCodes.Status413PayloadTooLarge, new
            {
                error = $"Image trop grande. Maximum {MaxImageSizeBytes / (1024 * 1024)} MB. Reçu: {Math.Round(image.Length / 1024.0 / 1024.0, 2)} MB."
            });

        // ✅ Validation: format accepté
        var allowedContentTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/webp" };
        if (!allowedContentTypes.Contains(image.ContentType?.ToLowerInvariant()))
            return BadRequest(new { error = $"Format non supporté: {image.ContentType}. Utilisez JPEG, PNG ou WebP." });

        // ✅ Lire les bytes de l'image
        using var memoryStream = new MemoryStream();
        await image.CopyToAsync(memoryStream, ct);
        var imageBytes = memoryStream.ToArray();

        // ✅ Valider l'opérateur si fourni
        MobileMoneyOperator? parsedOperator = null;
        if (@operator.HasValue)
        {
            if (!Enum.IsDefined(typeof(MobileMoneyOperator), @operator.Value))
                return BadRequest(new { error = "Opérateur invalide. Utilisez: 0 (Other), 1 (MTN), 2 (Airtel)." });

            parsedOperator = (MobileMoneyOperator)@operator.Value;
        }

        // ✅ Créer la requête de service
        var request = new CreateProofRequest(
            amount,
            currency,
            transactionReference,
            parsedOperator ?? MobileMoneyOperator.Other,
            transactionDate,
            notes,
            clientId,
            salesOrderId
        );

        // ✅ Appeler le service
        var result = await _service.UploadAsync(request, imageBytes, image.ContentType!, ct);

        if (!result.IsSuccess)
            return BadRequest(new { error = result.Error });

        return CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value);
    }

    /// <summary>
    /// Modifie les métadonnées d'une preuve (statut, montant, notes, etc.).
    /// NOTE: L'image ne peut pas être modifiée après upload. Supprimez et re-uploadez si nécessaire.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ProofResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Update(
        Guid id,
        [FromBody] UpdateProofRequest request,
        CancellationToken ct = default)
    {
        var result = await _service.UpdateAsync(id, request, ct);

        if (!result.IsSuccess)
        {
            return result.Error!.Contains("introuvable")
                ? NotFound(new { error = result.Error })
                : BadRequest(new { error = result.Error });
        }

        return Ok(result.Value);
    }

    /// <summary>
    /// Supprime une preuve (image + toutes les métadonnées).
    /// Cette opération est irréversible.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct = default)
    {
        var result = await _service.DeleteAsync(id, ct);

        if (!result.IsSuccess)
            return NotFound(new { error = result.Error });

        return NoContent();
    }

    /// <summary>Helper pour obtenir l'extension de fichier basée sur le content-type.</summary>
    private static string GetImageExtension(string contentType) => contentType?.ToLowerInvariant() switch
    {
        "image/jpeg" or "image/jpg" => "jpg",
        "image/png" => "png",
        "image/webp" => "webp",
        _ => "jpg"
    };
}