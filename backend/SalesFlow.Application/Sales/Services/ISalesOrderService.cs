using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Sales.DTOs;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Sales.Services;

public interface ISalesOrderService
{
    Task<Result<SalesOrderListResponse>> ListAsync(
        int page, int pageSize, SalesOrderStatus? status, Guid? clientId, CancellationToken ct = default);

    Task<Result<SalesOrderResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<SalesOrderResponse>> CreateAsync(CreateSalesOrderRequest request, CancellationToken ct = default);

    Task<Result<SalesOrderResponse>> UpdateAsync(Guid id, UpdateSalesOrderRequest request, CancellationToken ct = default);

    Task<Result<SalesOrderResponse>> TransitionAsync(Guid id, TransitionSalesOrderRequest request, CancellationToken ct = default);

    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}
