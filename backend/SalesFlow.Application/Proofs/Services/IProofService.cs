using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Proofs.DTOs;
using SalesFlow.Domain.Enums;
namespace SalesFlow.Application.Proofs.Services;

public interface IProofService
{
    /// <summary>Liste paginée des preuves avec filtres optionnels.</summary>
    Task<Result<ProofListResponse>> ListAsync(
    int page = 1,
    int pageSize = 20,
    ProofStatus? status = null,
    Guid? clientId = null,
    Guid? salesOrderId = null,
    CancellationToken ct = default
    );
    /// <summary>Récupère une preuve par ID (métadonnées uniquement, pas l'image).</summary>
    Task<Result<ProofResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    /// <summary>Récupère les bytes d'une image de preuve.</summary>
    Task<Result<ProofImage>> GetImageAsync(Guid id, CancellationToken ct = default);

    /// <summary>Upload une nouvelle preuve de paiement avec image.</summary>
    Task<Result<ProofResponse>> UploadAsync(
        CreateProofRequest request,
        byte[] imageBytes,
        string imageContentType,
        CancellationToken ct = default
    );

    /// <summary>Modifie une preuve existante (métadonnées et statut uniquement, pas l'image).</summary>
    Task<Result<ProofResponse>> UpdateAsync(
        Guid id,
        UpdateProofRequest request,
        CancellationToken ct = default
    );

    /// <summary>Supprime une preuve (image + métadonnées).</summary>
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}