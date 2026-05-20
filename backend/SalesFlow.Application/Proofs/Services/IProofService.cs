using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Proofs.DTOs;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Proofs.Services;

/// <summary>Image téléchargée + métadonnées pour récupération depuis le contrôleur.</summary>
public record ProofImage(byte[] Bytes, string ContentType);

public interface IProofService
{
    Task<Result<ProofListResponse>> ListAsync(
        int page, int pageSize, ProofStatus? status, Guid? clientId, Guid? salesOrderId,
        CancellationToken ct = default);

    Task<Result<ProofResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    /// <summary>Récupère uniquement les bytes de l'image (pour le téléchargement direct).</summary>
    Task<Result<ProofImage>> GetImageAsync(Guid id, CancellationToken ct = default);

    Task<Result<ProofResponse>> CreateAsync(
        CreateProofRequest request,
        byte[] imageBytes,
        string imageContentType,
        CancellationToken ct = default);

    Task<Result<ProofResponse>> UpdateAsync(Guid id, UpdateProofRequest request, CancellationToken ct = default);

    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}
