using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Reminders.DTOs;

namespace SalesFlow.Application.Reminders.Services;

public interface IReminderService
{
    Task<Result<ReminderListResponse>> ListAsync(int page, int pageSize, bool unreadOnly = false, CancellationToken ct = default);
    Task<Result<ReminderDto>> GetByIdAsync(string id, CancellationToken ct = default);
    Task<Result<bool>> MarkAsReadAsync(string id, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(string id, CancellationToken ct = default);
    Task<Result<ReminderDto>> CreateAsync(string orderId, string type, string title, string message, CancellationToken ct = default);
}
