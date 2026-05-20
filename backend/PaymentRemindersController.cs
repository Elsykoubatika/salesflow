using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/payment-reminders")]
[Authorize]
public class PaymentRemindersController : ControllerBase
{
    private readonly ICurrentUser _currentUser;
    private readonly IAppDbContext _dbContext;

    public PaymentRemindersController(ICurrentUser currentUser, IAppDbContext dbContext)
    {
        _currentUser = currentUser;
        _dbContext = dbContext;
    }

    [HttpGet("pending")]
    public async Task<ActionResult<List<dynamic>>> GetPendingReminders()
    {
        var reminders = await _dbContext.PaymentReminders
            .Where(r => r.UserId == _currentUser.UserId && r.Status == "Pending")
            .Include(r => r.TechnicalInvoice)
            .ThenInclude(i => i!.Client)
            .OrderBy(r => r.ReminderDate)
            .Select(r => new
            {
                r.Id,
                r.TechnicalInvoice!.InvoiceNumber,
                ClientName = r.TechnicalInvoice!.Client!.Name,
                Amount = r.TechnicalInvoice.AmountDue,
                r.DaysOverdue,
                r.ReminderDate,
                r.ReminderCount,
                r.IsEscalated
            })
            .ToListAsync();

        return Ok(reminders);
    }

    [HttpPost("auto-generate")]
    public async Task<ActionResult> AutoGenerateReminders()
    {
        var overdueInvoices = await _dbContext.TechnicalInvoices
            .Where(i => i.UserId == _currentUser.UserId && i.Status != "Paid" && i.DueDate < DateTime.Now)
            .Include(i => i.Payments)
            .ToListAsync();

        var generatedCount = 0;

        foreach (var invoice in overdueInvoices)
        {
            var daysOverdue = (DateTime.Now - invoice.DueDate).Days;
            
            // Create reminders at 7, 14, 21 days
            if ((daysOverdue == 7 || daysOverdue == 14 || daysOverdue == 21) &&
                !await _dbContext.PaymentReminders
                    .AnyAsync(r => r.TechnicalInvoiceId == invoice.Id && r.DaysOverdue == daysOverdue))
            {
                var reminder = new PaymentReminder
                {
                    UserId = _currentUser.UserId,
                    TechnicalInvoiceId = invoice.Id,
                    ReminderDate = DateTime.Now,
                    DaysOverdue = daysOverdue,
                    ReminderType = "Email",
                    Status = "Pending",
                    IsAutomatic = true,
                    SendToClient = true,
                    ReminderCount = 1
                };

                _dbContext.PaymentReminders.Add(reminder);
                generatedCount++;
            }
        }

        await _dbContext.SaveChangesAsync();
        return Ok(new { generatedReminders = generatedCount });
    }

    [HttpPost("{id}/send")]
    public async Task<ActionResult> SendReminder(Guid id, [FromBody] SendReminderRequest request)
    {
        var reminder = await _dbContext.PaymentReminders
            .Include(r => r.TechnicalInvoice)
            .ThenInclude(i => i!.Client)
            .FirstOrDefaultAsync(r => r.Id == id && r.UserId == _currentUser.UserId);

        if (reminder == null) return NotFound();

        // TODO: Integrate with email service
        // await _emailService.SendPaymentReminder(reminder.TechnicalInvoice.Client.Email, reminder);

        reminder.Status = "Sent";
        reminder.LastReminderSent = DateTime.Now;
        reminder.ReminderCount++;

        // Escalate if 3rd reminder
        if (reminder.ReminderCount >= 3)
        {
            reminder.IsEscalated = true;
            reminder.EscalationNotes = "Invoice escalated after 3 reminders";
        }

        await _dbContext.SaveChangesAsync();

        return Ok(new
        {
            reminderId = reminder.Id,
            status = reminder.Status,
            escalated = reminder.IsEscalated,
            reminderCount = reminder.ReminderCount
        });
    }

    [HttpPost("{id}/acknowledge")]
    public async Task<ActionResult> AcknowledgeReminder(Guid id)
    {
        var reminder = await _dbContext.PaymentReminders
            .FirstOrDefaultAsync(r => r.Id == id && r.UserId == _currentUser.UserId);

        if (reminder == null) return NotFound();

        reminder.Status = "Acknowledged";
        await _dbContext.SaveChangesAsync();

        return Ok(reminder);
    }

    [HttpPost("{id}/resolve")]
    public async Task<ActionResult> ResolveReminder(Guid id, [FromBody] ResolveReminderRequest request)
    {
        var reminder = await _dbContext.PaymentReminders
            .FirstOrDefaultAsync(r => r.Id == id && r.UserId == _currentUser.UserId);

        if (reminder == null) return NotFound();

        reminder.Status = "Completed";
        reminder.ResolutionDate = DateTime.Now;
        reminder.EscalationNotes = request.ResolutionNotes;

        await _dbContext.SaveChangesAsync();

        return Ok(reminder);
    }

    [HttpGet("statistics")]
    public async Task<ActionResult> GetStatistics()
    {
        var reminders = await _dbContext.PaymentReminders
            .Where(r => r.UserId == _currentUser.UserId)
            .ToListAsync();

        var stats = new
        {
            TotalReminders = reminders.Count,
            Pending = reminders.Count(r => r.Status == "Pending"),
            Sent = reminders.Count(r => r.Status == "Sent"),
            Completed = reminders.Count(r => r.Status == "Completed"),
            Escalated = reminders.Count(r => r.IsEscalated),
            AverageDaysToResolution = reminders
                .Where(r => r.ResolutionDate.HasValue)
                .Select(r => (r.ResolutionDate.Value - r.ReminderDate).TotalDays)
                .DefaultIfEmpty(0)
                .Average()
        };

        return Ok(stats);
    }
}

public record SendReminderRequest(string ReminderType);
public record ResolveReminderRequest(string ResolutionNotes);
