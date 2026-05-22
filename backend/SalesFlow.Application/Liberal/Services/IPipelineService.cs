using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Liberal.DTOs;

namespace SalesFlow.Application.Liberal.Services;

public interface IPipelineService
{
    Task<Result<ProspectListResponse>> ListProspectsAsync(
        int page = 1,
        int pageSize = 20,
        string? stage = null,
        CancellationToken ct = default
    );

    Task<Result<ProspectContactResponse>> GetProspectByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<ProspectContactResponse>> CreateProspectAsync(
        CreateProspectContactRequest request,
        CancellationToken ct = default
    );

    Task<Result<ProspectContactResponse>> UpdateProspectAsync(
        Guid id,
        UpdateProspectContactRequest request,
        CancellationToken ct = default
    );

    Task<Result<ProspectContactResponse>> UpdateProspectStageAsync(
        Guid id,
        UpdateProspectStageRequest request,
        CancellationToken ct = default
    );

    Task<Result<PipelineEventResponse>> LogEventAsync(
        Guid prospectId,
        CreatePipelineEventRequest request,
        CancellationToken ct = default
    );

    Task<Result<bool>> DeleteProspectAsync(Guid id, CancellationToken ct = default);
}
