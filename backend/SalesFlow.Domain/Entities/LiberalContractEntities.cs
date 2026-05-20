using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

/// Forfait Honoraires - Offrir services
public class LiberalContract : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    public string ContractNumber { get; set; } = string.Empty;
    public string ContractName { get; set; } = string.Empty;
    public string ServiceDescription { get; set; } = string.Empty;

    // Pricing Models
    public string PricingModel { get; set; } = "Project"; // Hourly, Daily, Project, Retainer
    
    // Rates based on model
    public decimal? HourlyRate { get; set; } // À l'heure
    public decimal? DailyRate { get; set; } // Au jour
    public decimal? ProjectRate { get; set; } // Au projet
    public decimal? MonthlyRetainer { get; set; } // Retainer mensuel

    // Contract Terms
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string EngagementType { get; set; } = "Project"; // Project, Monthly, Yearly, Recurring

    // Status
    public string Status { get; set; } = "Draft"; // Draft, Proposed, Signed, Active, Completed, Terminated
    public DateTime? SignedDate { get; set; }

    // Renewal
    public bool IsRecurring { get; set; }
    public string? RecurrencePattern { get; set; } // Monthly, Quarterly, Yearly
    public DateTime? NextRenewalDate { get; set; }
    public bool AutoRenew { get; set; }

    // Invoices and Payments
    public List<LiberalInvoice> Invoices { get; set; } = new();
    public decimal TotalBilled { get; set; }
    public decimal TotalPaid { get; set; }

    // Documents
    public string? ContractDocument { get; set; } // File path
    public string? Notes { get; set; }
}

/// Facturation Prestation
public class LiberalInvoice : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ContractId { get; set; }
    public LiberalContract? Contract { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    public string InvoiceNumber { get; set; } = string.Empty;
    public DateTime InvoiceDate { get; set; }
    public DateTime DueDate { get; set; }

    // Service Period
    public DateTime ServiceStartDate { get; set; }
    public DateTime ServiceEndDate { get; set; }
    public decimal TotalHours { get; set; }

    // Pricing & Calculation
    public decimal BaseAmount { get; set; } // Amount before multiplier
    public decimal ComplexityMultiplier { get; set; } = 1m; // 1×, 1.5×, 2×
    public decimal SubTotal => BaseAmount * ComplexityMultiplier;
    public decimal TaxAmount { get; set; }
    public decimal AdvancePayment { get; set; } // Acompte versé
    public decimal Total { get; set; }

    // Deliverables
    public List<InvoiceDeliverable> Deliverables { get; set; } = new();
    public string? DeliverableDetails { get; set; }

    // Payment Status
    public string Status { get; set; } = "Pending"; // Pending, PartiallyPaid, Paid, Overdue
    public decimal AmountPaid { get; set; }
    public decimal RemainingAmount => Total - AmountPaid;
    public DateTime? PaidDate { get; set; }
    public List<PaymentRecord> Payments { get; set; } = new();
}

public class InvoiceDeliverable : BaseEntity
{
    public Guid LiberalInvoiceId { get; set; }
    public LiberalInvoice? LiberalInvoice { get; set; }

    public string DeliverableName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTime? DeliveryDate { get; set; }
}

/// Pipeline de contacts - Prospects → Discussion → Contrat
public class ProspectContact : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string CompanyName { get; set; } = string.Empty;
    public string ContactPerson { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;

    // Pipeline Status
    public string Stage { get; set; } = "Prospect"; // Prospect, Discussion, Proposal, Negotiation, Signed, Lost
    public string? Source { get; set; } // Referral, Website, LinkedIn, etc.

    // Dates clés
    public DateTime FirstContactDate { get; set; }
    public DateTime? LastContactDate { get; set; }
    public DateTime? NextFollowUpDate { get; set; }

    // Key Events
    public List<PipelineEvent> Events { get; set; } = new();

    // Potential Contract Value
    public decimal EstimatedValue { get; set; }
    public decimal Probability { get; set; } // 0-100%

    // Renewal Tracking
    public DateTime? RenewalDate { get; set; }
    public bool NeedsRenewal { get; set; }
    public List<string> RenewalReminders { get; set; } = new();

    // Notes
    public string? Notes { get; set; }
}

public class PipelineEvent : BaseEntity
{
    public Guid ProspectContactId { get; set; }
    public ProspectContact? ProspectContact { get; set; }

    public string EventType { get; set; } = string.Empty; // Call, Meeting, Email, Proposal, Contract Signed
    public DateTime EventDate { get; set; }
    public string? Notes { get; set; }
    public bool IsRenewalEvent { get; set; }
}

/// Paiements partiels et suivi récurrence
public class PaymentRecord : BaseEntity
{
    public Guid LiberalInvoiceId { get; set; }
    public LiberalInvoice? LiberalInvoice { get; set; }

    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }
    public string PaymentMethod { get; set; } = string.Empty; // Cash, MobileMoney, Bank, Card
    public string? TransactionReference { get; set; }
    public string Status { get; set; } = "Completed"; // Pending, Completed, Failed
    public string? Notes { get; set; }
}

/// Rappels renouvellement - Automatic reminders
public class RenewalReminder : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ContractId { get; set; }
    public LiberalContract? Contract { get; set; }

    public DateTime ReminderDate { get; set; }
    public DateTime ContractRenewalDate { get; set; }
    public string Status { get; set; } = "Pending"; // Pending, Sent, Completed, Ignored
    public DateTime? SentDate { get; set; }
    public bool IsAutomated { get; set; }
}
