using SalesFlow.Application.Clients.DTOs;
using SalesFlow.Application.Common.Models;

namespace SalesFlow.Application.Clients.Services;

public interface IClientService
{
    Task<Result<ClientListResponse>> ListAsync(int page, int pageSize, string? search, CancellationToken ct = default);
    Task<Result<ClientResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<ClientResponse>> CreateAsync(CreateClientRequest request, CancellationToken ct = default);
    Task<Result<ClientResponse>> UpdateAsync(Guid id, UpdateClientRequest request, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}
