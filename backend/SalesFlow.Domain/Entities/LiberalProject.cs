using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

public class LiberalProject : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    public string ProjectName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string ProjectType { get; set; } = string.Empty; // "Training", "Consulting", "Coaching", etc.

    // Timeline
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = "Planning"; // Planning, InProgress, Completed, Archived

    // Financials
    public decimal BudgetAmount { get; set; }
    public decimal EstimatedHours { get; set; }
    public decimal HourlyRate { get; set; }
    public decimal TotalInvoiced { get; set; }
    public decimal TotalPaid { get; set; }

    // Deliverables
    public List<ProjectDeliverable> Deliverables { get; set; } = new();
    
    // Tasks/Milestones
    public List<ProjectTask> Tasks { get; set; } = new();

    // Documents
    public List<ProjectDocument> Documents { get; set; } = new();

    // Notes
    public string Notes { get; set; } = string.Empty;
}

public class ProjectDeliverable : BaseEntity
{
    public Guid LiberalProjectId { get; set; }
    public LiberalProject? LiberalProject { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime DueDate { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedDate { get; set; }
    public int Order { get; set; }
}

public class ProjectTask : BaseEntity
{
    public Guid LiberalProjectId { get; set; }
    public LiberalProject? LiberalProject { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Priority { get; set; } = "Medium"; // Low, Medium, High
    public string Status { get; set; } = "Todo"; // Todo, InProgress, Done
    public DateTime DueDate { get; set; }
    public decimal EstimatedHours { get; set; }
    public decimal ActualHours { get; set; }
    public int Order { get; set; }
}

public class ProjectDocument : BaseEntity
{
    public Guid LiberalProjectId { get; set; }
    public LiberalProject? LiberalProject { get; set; }

    public string DocumentName { get; set; } = string.Empty;
    public string DocumentType { get; set; } = string.Empty; // "Contract", "Report", "Proposal", etc.
    public string FilePath { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string ContentType { get; set; } = "application/pdf";
    public bool IsTemplate { get; set; }
}
