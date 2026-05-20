using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

public class TechnicalIntervention : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    public Guid? TechnicalQuoteId { get; set; }
    public TechnicalQuote? TechnicalQuote { get; set; }

    public string InterventionNumber { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;

    // Timing
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public decimal ActualHours => EndTime.HasValue ? (decimal)(EndTime.Value - StartTime).TotalHours : 0;

    // ✅ Changed from MaintenanceChecklistItem to TechnicalChecklistItem
    public List<TechnicalChecklistItem> ChecklistItems { get; set; } = new();

    // Additional materials used during intervention
    public List<TechnicalQuoteItem> AdditionalMaterials { get; set; } = new();

    // Notes & photos
    public string Notes { get; set; } = string.Empty;
    public List<string> PhotoUrls { get; set; } = new();

    // Invoicing
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "InProgress";
    public DateTime? CompletedAt { get; set; }
}

public class MaintenanceChecklistItem : BaseEntity
{
    public Guid TechnicalInterventionId { get; set; }
    public TechnicalIntervention? TechnicalIntervention { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public string? Notes { get; set; }
    public int Order { get; set; }

    // Checklist template mapping
    public string? ChecklistTemplateId { get; set; }
}

public class MaintenanceChecklistTemplate
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ApplianceType { get; set; } = string.Empty; // "Refrigerator", "AC Unit", "Breaker Panel", etc.
    public string ProblemCategory { get; set; } = string.Empty; // "Electrical Fault", "Overheating", "Water Leak", etc.
    public List<ChecklistStep> Steps { get; set; } = new();
}

public class ChecklistStep
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Order { get; set; }
    public string? ToolsNeeded { get; set; }
    public string? SafetyWarning { get; set; }
}
