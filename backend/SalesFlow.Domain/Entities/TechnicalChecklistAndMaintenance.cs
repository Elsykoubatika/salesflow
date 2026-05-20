using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

public class TechnicalChecklistItem : BaseEntity
{
    public Guid TechnicalInterventionId { get; set; }
    public TechnicalIntervention? TechnicalIntervention { get; set; }  // ✅ Keep only ONE

    public string Title { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string Task { get; set; } = string.Empty;
    public TechnicalIntervention? Intervention { get; set; }
}

public class MaintenancePlan : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public string Status { get; set; } = "Active";
    public string AssetName { get; set; } = string.Empty;
    public string? AssetModel { get; set; }
    public string? Description { get; set; }
    
    public string Frequency { get; set; } = "Mensuel";
    public decimal EstimatedCost { get; set; }
    public double EstimatedDuration { get; set; }
    public DateTime? LastMaintenanceDate { get; set; }
    public DateTime NextScheduledDate { get; set; }
    public string? Notes { get; set; }

    public List<MaintenanceTask> Tasks { get; set; } = new();
}

public class MaintenanceTask : BaseEntity
{
    public Guid MaintenancePlanId { get; set; }
    public MaintenancePlan? Plan { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending";
    public DateTime DueDate { get; set; }
    public decimal EstimatedHours { get; set; }
    public decimal ActualHours { get; set; }
    public string TaskName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Sequence { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
}