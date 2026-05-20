using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

public class Reminder : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid SalesOrderId { get; set; }
    public SalesOrder? SalesOrder { get; set; }

    public string Type { get; set; } = "PaymentOverdue"; // PaymentOverdue, LowStock, etc.
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }
    public DateTime ScheduledFor { get; set; }
}
