using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Liberal.DTOs;

namespace SalesFlow.Application.Liberal.Services;

public interface ILiberalInvoiceService
{
    Task<Result<LiberalInvoiceListResponse>> ListAsync(
        int page = 1,
        int pageSize = 20,
        string? status = null,
        CancellationToken ct = default
    );

    Task<Result<LiberalInvoiceResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<LiberalInvoiceResponse>> CreateAsync(
        CreateLiberalInvoiceRequest request,
        CancellationToken ct = default
    );

    Task<Result<LiberalInvoiceResponse>> UpdateAsync(
        Guid id,
        UpdateLiberalInvoiceRequest request,
        CancellationToken ct = default
    );

    Task<Result<bool>> SendAsync(Guid id, CancellationToken ct = default);

    Task<Result<bool>> MarkPaidAsync(Guid id, CancellationToken ct = default);

    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}
