using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Quartz;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Infrastructure.Jobs;

[DisallowConcurrentExecution]
public class OverdueOrdersReminderJob : IJob
{
    private readonly AppDbContext _db;
    private readonly ILogger<OverdueOrdersReminderJob> _logger;

    public OverdueOrdersReminderJob(AppDbContext db, ILogger<OverdueOrdersReminderJob> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task Execute(IJobExecutionContext context)
    {
        try
        {
            _logger.LogInformation("OverdueOrdersReminderJob started");

            var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

            // Chercher les commandes Sent/Accepted depuis >7j sans paiement
            var overdueOrders = await _db.SalesOrders
                .Where(o => (o.Status == SalesOrderStatus.Sent || o.Status == SalesOrderStatus.Accepted) &&
                            o.SentAt != null &&
                            o.SentAt < sevenDaysAgo)
                .ToListAsync();

            foreach (var order in overdueOrders)
            {
                // Vérifier si un reminder existe déjà
                var existingReminder = await _db.Reminders
                    .AnyAsync(r => r.SalesOrderId == order.Id && r.Type == "PaymentOverdue");

                if (!existingReminder)
                {
                    var reminder = new Reminder
                    {
                        UserId = order.UserId,
                        SalesOrderId = order.Id,
                        Type = "PaymentOverdue",
                        Title = $"Commande {order.OrderNumber} impayée",
                        Message = $"La commande {order.OrderNumber} pour {(order.Client != null ? order.Client.FullName : "Client inconnu")} est impayée depuis plus de 7 jours.",
                        ScheduledFor = DateTime.UtcNow,
                        IsRead = false
                    };

                    _db.Reminders.Add(reminder);
                    _logger.LogInformation($"Created reminder for overdue order {order.OrderNumber}");
                }
            }

            await _db.SaveChangesAsync();
            _logger.LogInformation($"OverdueOrdersReminderJob completed. Processed {overdueOrders.Count} orders");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "OverdueOrdersReminderJob failed");
            throw;
        }
    }
}
