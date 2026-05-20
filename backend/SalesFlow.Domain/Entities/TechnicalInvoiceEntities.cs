using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

/// Facture technique complète
public class TechnicalInvoice : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }
    public string Currency { get; set; } = "XAF";
    public Guid? TechnicalInterventionId { get; set; }
    public TechnicalIntervention? TechnicalIntervention { get; set; }

    public Guid? TechnicalQuoteId { get; set; }
    public TechnicalQuote? TechnicalQuote { get; set; }

    // Invoice Info
    public string InvoiceNumber { get; set; } = string.Empty;
    public DateTime InvoiceDate { get; set; }
    public DateTime DueDate { get; set; }

    // Service Info
    public DateTime WorkStartDate { get; set; }
    public DateTime WorkEndDate { get; set; }
    public string ServiceDescription { get; set; } = string.Empty;
    public string LocationOfWork { get; set; } = string.Empty;

    // Calculation
    public decimal HourlyRate { get; set; }
    public decimal ActualHours { get; set; }
    public decimal LaborCost => ActualHours * HourlyRate; // Durée réelle × tarif

    // Materials
    public List<TechnicalQuoteItem> MaterialsUsed { get; set; } = new();
    public decimal MaterialsCost { get; set; }

    // Advance & Deductions
    public decimal AdvancePayment { get; set; } // Acompte versé
    public decimal OtherDeductions { get; set; }

    // Totals
    public decimal SubTotal => LaborCost + MaterialsCost; // Durée + matériaux
    public decimal TaxAmount { get; set; }
    public decimal Total { get; set; } // Somme finale
    public decimal AmountDue => Total - AdvancePayment - OtherDeductions;

    // Status & Payment
    public string Status { get; set; } = "Pending"; // Pending, PartiallyPaid, Paid, Overdue
    public DateTime? PaidDate { get; set; }
    public decimal AmountPaid { get; set; }

    // Payments
    public List<TechnicalPaymentRecord> Payments { get; set; } = new();

    // Documents
    public string? PdfFilePath { get; set; } // PDF généré
    public string? Notes { get; set; }
}

/// Preuve de paiement - Mobile Money
public class TechnicalPaymentRecord : BaseEntity
{
    public Guid TechnicalInvoiceId { get; set; }
    public TechnicalInvoice? TechnicalInvoice { get; set; }

    // Payment Details
    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }
    public string PaymentMethod { get; set; } = string.Empty; // Cash, MobileMoney, Bank, Check
    
    // Mobile Money Specific
    public string? MobileMoneyOperator { get; set; } // MTN Momo, Airtel Money, etc.
    public string? MobileMoneyReference { get; set; } // Transaction reference
    public string? PhoneNumber { get; set; } // Phone used for payment
    public string? SenderName { get; set; }

    // Payment Status
    public string Status { get; set; } = "Completed"; // Pending, Completed, Failed, Verified
    public bool IsVerified { get; set; }
    public DateTime? VerificationDate { get; set; }

    // Proof Documentation
    public List<PaymentProofDocument> ProofDocuments { get; set; } = new();
    public string? Notes { get; set; }
}

/// Documents de preuve (screenshots, reçus, etc.)
public class PaymentProofDocument : BaseEntity
{
    public Guid TechnicalPaymentRecordId { get; set; }
    public TechnicalPaymentRecord? TechnicalPaymentRecord { get; set; }

    public string DocumentName { get; set; } = string.Empty;
    public string DocumentType { get; set; } = string.Empty; // Screenshot, Receipt, Bank Statement
    public string FilePath { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public DateTime UploadDate { get; set; }
}

/// Suivi paiement - Rappels automatiques si impayé >7j
public class PaymentReminder : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid TechnicalInvoiceId { get; set; }
    public TechnicalInvoice? TechnicalInvoice { get; set; }

    // Reminder Details
    public int DaysOverdue { get; set; } // Impayé depuis combien de jours
    public DateTime ReminderDate { get; set; }
    public string ReminderType { get; set; } = "Email"; // Email, SMS, In-App
    public string Status { get; set; } = "Pending"; // Pending, Sent, Acknowledged, Resolved

    // Reminder History
    public int ReminderCount { get; set; } // Nombre de rappels envoyés
    public DateTime? LastReminderSent { get; set; }
    public DateTime? ResolutionDate { get; set; }

    // Escalation
    public bool IsEscalated { get; set; }
    public string? EscalationNotes { get; set; }

    // Settings
    public bool IsAutomatic { get; set; } // Auto-generated at 7, 14, 21 days
    public bool SendToClient { get; set; }
}

/// Historique client - Toutes les interventions et factures par client
public class ClientTechnicalHistory : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    // Statistics
    public int TotalInterventions { get; set; }
    public decimal TotalInvoiced { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal TotalOutstanding { get; set; }

    // Performance
    public decimal AverageHoursPerIntervention { get; set; }
    public decimal AverageInvoiceAmount { get; set; }
    public decimal PaymentComplianceRate { get; set; } // % à temps

    // Latest Activity
    public DateTime? LastInterventionDate { get; set; }
    public DateTime? LastPaymentDate { get; set; }
    public DateTime? LastReminderSentDate { get; set; }

    // Relationship
    public string ClientStatus { get; set; } = "Active"; // Active, Inactive, Problematic, VIP
    public string? Notes { get; set; }
    public DateTime LastUpdated { get; set; }
}
