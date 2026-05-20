using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Reminders.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Reminders.Services;

public class ReminderService : IReminderService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public ReminderService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<ReminderListResponse>> ListAsync(int page, int pageSize, bool unreadOnly = false, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        page = page < 1 ? 1 : page;
        pageSize = pageSize < 1 || pageSize > 100 ? 20 : pageSize;

        var query = _db.Reminders.AsNoTracking().Where(r => r.UserId == userId);
        if (unreadOnly) query = query.Where(r => !r.IsRead);

        var total = await query.CountAsync(ct);
        var unreadCount = await _db.Reminders.AsNoTracking()
            .Where(r => r.UserId == userId && !r.IsRead)
            .CountAsync(ct);

        var items = await query
            .OrderByDescending(r => r.ScheduledFor)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ReminderDto(
                r.Id.ToString(),
                r.Type,
                r.Title,
                r.Message,
                r.IsRead,
                r.SalesOrder != null ? r.SalesOrder.OrderNumber : null,
                r.SalesOrder != null && r.SalesOrder.Client != null ? r.SalesOrder.Client.FullName : null,
                r.ScheduledFor,
                r.CreatedAt
            ))
            .ToListAsync(ct);

        return Result<ReminderListResponse>.Success(new ReminderListResponse(items, total, unreadCount, page, pageSize));
    }

    public async Task<Result<ReminderDto>> GetByIdAsync(string id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        if (!Guid.TryParse(id, out var reminderId)) return Result<ReminderDto>.Failure("ID invalide");

        var reminder = await _db.Reminders.AsNoTracking()
            .Where(r => r.Id == reminderId && r.UserId == userId)
            .Select(r => new ReminderDto(
                r.Id.ToString(),
                r.Type,
                r.Title,
                r.Message,
                r.IsRead,
                r.SalesOrder != null ? r.SalesOrder.OrderNumber : null,
                r.SalesOrder != null && r.SalesOrder.Client != null ? r.SalesOrder.Client.FullName : null,
                r.ScheduledFor,
                r.CreatedAt
            ))
            .FirstOrDefaultAsync(ct);

        return reminder != null 
            ? Result<ReminderDto>.Success(reminder)
            : Result<ReminderDto>.Failure("Rappel introuvable");
    }

    public async Task<Result<bool>> MarkAsReadAsync(string id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        if (!Guid.TryParse(id, out var reminderId)) return Result<bool>.Failure("ID invalide");

        var reminder = await _db.Reminders.FirstOrDefaultAsync(r => r.Id == reminderId && r.UserId == userId, ct);
        if (reminder == null) return Result<bool>.Failure("Rappel introuvable");

        reminder.IsRead = true;
        reminder.ReadAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> DeleteAsync(string id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        if (!Guid.TryParse(id, out var reminderId)) return Result<bool>.Failure("ID invalide");

        var reminder = await _db.Reminders.FirstOrDefaultAsync(r => r.Id == reminderId && r.UserId == userId, ct);
        if (reminder == null) return Result<bool>.Failure("Rappel introuvable");

        _db.Reminders.Remove(reminder);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    public async Task<Result<ReminderDto>> CreateAsync(string orderId, string type, string title, string message, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        if (!Guid.TryParse(orderId, out var orderIdGuid)) return Result<ReminderDto>.Failure("Order ID invalide");

        var order = await _db.SalesOrders.FirstOrDefaultAsync(o => o.Id == orderIdGuid && o.UserId == userId, ct);
        if (order == null) return Result<ReminderDto>.Failure("Commande introuvable");

        var reminder = new Reminder
        {
            UserId = userId,
            SalesOrderId = orderIdGuid,
            Type = type,
            Title = title,
            Message = message,
            ScheduledFor = DateTime.UtcNow,
            IsRead = false
        };

        _db.Reminders.Add(reminder);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(reminder.Id.ToString(), ct);
    }

    private Guid RequireUserId() => _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
}
