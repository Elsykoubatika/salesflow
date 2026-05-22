using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Technical.DTOs;

namespace SalesFlow.Application.Technical.Services;

public interface ITechnicalQuoteService
{
    Task<Result<TechnicalQuoteListResponse>> ListAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default);
    Task<Result<TechnicalQuoteResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<TechnicalQuoteResponse>> CreateAsync(CreateTechnicalQuoteRequest request, CancellationToken ct = default);
    Task<Result<TechnicalQuoteItemResponse>> AddItemAsync(Guid quoteId, CreateTechnicalQuoteItemRequest request, CancellationToken ct = default);
    Task<Result<TechnicalQuoteResponse>> SendAsync(Guid id, CancellationToken ct = default);
    Task<Result<TechnicalQuoteResponse>> AcceptAsync(Guid id, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}