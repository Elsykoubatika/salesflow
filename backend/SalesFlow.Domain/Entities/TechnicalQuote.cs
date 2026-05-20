using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

public class TechnicalQuote : BaseEntity
{
    public string Currency { get; set; } = "XAF";
    public DateTime? ValidUntil { get; set; }

    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid ClientId { get; set; }
    public Client? Client { get; set; }

    public string QuoteNumber { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string ServiceLocation { get; set; } = string.Empty;

    // Timing
    public decimal EstimatedHours { get; set; } // Duration estimate
    public decimal HourlyRate { get; set; } // Tarif horaire

    // Materials/Intelligent Calculations
    public List<TechnicalQuoteItem> Items { get; set; } = new();
    public decimal MaterialsCost { get; set; } // Total matériaux
    public decimal LaborCost { get; set; } // Durée × tarif
    public decimal Total { get; set; }

    // Intelligent Calculator Data (for cement bags, breakers, outlets, etc.)
    public string? CalculationContextJson { get; set; }

    // Status
    public string Status { get; set; } = "Draft"; // Draft, Sent, Accepted, Invoiced
    public DateTime? SentAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
}

public class TechnicalQuoteItem : BaseEntity
{
    public Guid TechnicalQuoteId { get; set; }
    public TechnicalQuote? TechnicalQuote { get; set; }

    public string ItemName { get; set; } = string.Empty;
    public string ItemType { get; set; } = string.Empty; // Material, Tool, etc.
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal Total => Quantity * UnitPrice;
    public string Unit { get; set; } = "pcs";
}

public class TechnicalCalculationContext
{
    public string? ProjectType { get; set; } // "Electrical", "Plumbing", "HVAC", etc.
    
    // Electrical calculations
    public decimal? WallArea { get; set; } // for cement bags calculation
    public int? CircuitBreakers { get; set; }
    public int? Outlets { get; set; }
    public decimal? PowerLoad { get; set; } // kW
    
    // Plumbing calculations
    public int? Bathrooms { get; set; }
    public int? Kitchens { get; set; }
    public string Currency { get; set; } = "XAF";
    public DateTime? ValidUntil { get; set; }
    // Generic
    public Dictionary<string, object> CustomParameters { get; set; } = new();
}
