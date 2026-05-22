using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Liberal.DTOs;

namespace SalesFlow.Application.Liberal.Services;

public interface ILiberalContractService
{
    Task<Result<LiberalContractListResponse>> ListAsync(
        int page = 1,
        int pageSize = 20,
        string? status = null,
        bool activeOnly = false,
        CancellationToken ct = default
    );

    Task<Result<LiberalContractResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<LiberalContractResponse>> CreateAsync(
        CreateLiberalContractRequest request,
        CancellationToken ct = default
    );

    Task<Result<LiberalContractResponse>> UpdateAsync(
        Guid id,
        UpdateLiberalContractRequest request,
        CancellationToken ct = default
    );

    Task<Result<LiberalContractResponse>> SignAsync(
        Guid id,
        SignContractRequest request,
        CancellationToken ct = default
    );

    Task<Result<LiberalContractResponse>> RenewAsync(
        Guid id,
        RenewContractRequest request,
        CancellationToken ct = default
    );

    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}
