using SalesFlow.Application.Common.Models;

namespace SalesFlow.Application.Technical.Services;

public interface ITechnicalInvoiceService
{
    Task<Result<TechnicalInvoiceListResponse>> ListAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default);
    Task<Result<TechnicalInvoiceResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<TechnicalInvoiceResponse>> CreateAsync(CreateTechnicalInvoiceRequest request, CancellationToken ct = default);
    Task<Result<bool>> SendAsync(Guid id, CancellationToken ct = default);
    Task<Result<bool>> MarkPaidAsync(Guid id, decimal amountPaid, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}