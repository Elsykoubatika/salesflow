using System.ComponentModel.DataAnnotations;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Proofs.DTOs;

/// <summary>
/// Champs saisis manuellement à la création.
/// L'image elle-même arrive via multipart/form-data, traitée séparément dans le contrôleur.
/// </summary>
public record CreateProofRequest(
    [Range(0, 999_999_999.99)] decimal? Amount,
    [MaxLength(3)] string? Currency,
    [MaxLength(100)] string? TransactionReference,
    MobileMoneyOperator Operator,
    DateTime? TransactionDate,
    [MaxLength(1000)] string? Notes,
    Guid? ClientId,
    Guid? SalesOrderId
);

public record UpdateProofRequest(
    [Range(0, 999_999_999.99)] decimal? Amount,
    [MaxLength(3)] string? Currency,
    [MaxLength(100)] string? TransactionReference,
    MobileMoneyOperator Operator,
    DateTime? TransactionDate,
    [MaxLength(1000)] string? Notes,
    Guid? ClientId,
    Guid? SalesOrderId,
    ProofStatus Status,
    [MaxLength(500)] string? ErrorMessage
);

public record ProofResponse(
    Guid Id,
    string ImageContentType,
    int ImageSizeBytes,
    decimal? Amount,
    string Currency,
    string? TransactionReference,
    MobileMoneyOperator Operator,
    string OperatorLabel,
    DateTime? TransactionDate,
    string? Notes,
    ProofStatus Status,
    string StatusLabel,
    string? ErrorMessage,
    Guid? ClientId,
    string? ClientName,
    Guid? SalesOrderId,
    string? OrderNumber,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record ProofListResponse(
    IEnumerable<ProofResponse> Items,
    int Total,
    int Page,
    int PageSize,
    int PendingCount
);
