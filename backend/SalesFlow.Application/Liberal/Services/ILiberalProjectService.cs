using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Liberal.DTOs;

namespace SalesFlow.Application.Liberal.Services;

public interface ILiberalProjectService
{
    Task<Result<LiberalProjectListResponse>> ListAsync(
        int page = 1,
        int pageSize = 20,
        string? status = null,
        bool activeOnly = false,
        CancellationToken ct = default
    );

    Task<Result<LiberalProjectResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<LiberalProjectResponse>> CreateAsync(
        CreateLiberalProjectRequest request,
        CancellationToken ct = default
    );

    Task<Result<LiberalProjectResponse>> UpdateAsync(
        Guid id,
        UpdateLiberalProjectRequest request,
        CancellationToken ct = default
    );

    Task<Result<DeliverableResponse>> AddDeliverableAsync(
        CreateDeliverableRequest request,
        CancellationToken ct = default
    );

    Task<Result<bool>> CompleteDeliverableAsync(Guid deliverableId, CancellationToken ct = default);

    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}
