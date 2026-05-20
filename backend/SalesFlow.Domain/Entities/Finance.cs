using SalesFlow.Domain.Common;

namespace SalesFlow.Domain.Entities;

public class FinanceAccount : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string AccountName { get; set; } = string.Empty;
    public string AccountType { get; set; } = "Personal"; // Personal, Family, Business
    public string Description { get; set; } = string.Empty;
    public decimal CurrentBalance { get; set; }
    public string Currency { get; set; } = "XAF";
    
    public List<FinanceTransaction> Transactions { get; set; } = new();
    public List<FinanceCategory> Categories { get; set; } = new();
    public List<FinanceBudget> Budgets { get; set; } = new();
}

public class FinanceTransaction : BaseEntity
{
    public Guid FinanceAccountId { get; set; }
    public FinanceAccount? FinanceAccount { get; set; }

    public string TransactionType { get; set; } = "Income"; // Income, Expense, Transfer
    public string Category { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime TransactionDate { get; set; }
    public string Status { get; set; } = "Completed"; // Completed, Pending, Cancelled
    public string? PaymentMethod { get; set; } // Cash, MobileMoney, Bank, Card, etc.
    public string? ReferenceNumber { get; set; }
    public bool IsRecurring { get; set; }
    public string? RecurrencePattern { get; set; } // Weekly, Monthly, Yearly
}

public class FinanceCategory : BaseEntity
{
    public Guid FinanceAccountId { get; set; }
    public FinanceAccount? FinanceAccount { get; set; }

    public string CategoryName { get; set; } = string.Empty;
    public string CategoryType { get; set; } = "Expense"; // Income, Expense
    public string Icon { get; set; } = "📊";
    public string Color { get; set; } = "#0D6B4F";
}

public class FinanceBudget : BaseEntity
{
    public Guid FinanceAccountId { get; set; }
    public FinanceAccount? FinanceAccount { get; set; }

    public string BudgetName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal PlannedAmount { get; set; }
    public decimal SpentAmount { get; set; }
    public string Period { get; set; } = "Monthly"; // Weekly, Monthly, Yearly
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = "Active"; // Active, Completed, Paused

    public decimal RemainingAmount => Math.Max(0, PlannedAmount - SpentAmount);
    public decimal PercentageUsed => PlannedAmount > 0 ? (SpentAmount / PlannedAmount) * 100 : 0;
}

public class FinanceReport : BaseEntity
{
    public Guid FinanceAccountId { get; set; }
    public FinanceAccount? FinanceAccount { get; set; }

    public string ReportType { get; set; } = "Monthly"; // Weekly, Monthly, Yearly, Custom
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalIncome { get; set; }
    public decimal TotalExpenses { get; set; }
    public decimal NetAmount => TotalIncome - TotalExpenses;
    public Dictionary<string, decimal> CategoryBreakdown { get; set; } = new();
}
