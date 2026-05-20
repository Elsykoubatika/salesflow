namespace SalesFlow.Application.Reminders.DTOs;

public record ReminderDto(
    string Id,
    string Type,
    string Title,
    string Message,
    bool IsRead,
    string? OrderNumber,
    string? ClientName,
    DateTime ScheduledFor,
    DateTime CreatedAt
);

public record ReminderListResponse(
    IEnumerable<ReminderDto> Items,
    int Total,
    int UnreadCount,
    int Page,
    int PageSize
);

public record MarkReminderReadRequest(bool IsRead);
