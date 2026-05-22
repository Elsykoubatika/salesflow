using Microsoft.EntityFrameworkCore;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Common.Interfaces;

/// <summary>
/// Abstraction du DbContext pour que la couche Application
/// ne dépende pas directement d'EF Core (testabilité + Clean Architecture).
/// </summary>
public interface IAppDbContext
{
    DbSet<User> Users { get; }
    DbSet<Client> Clients { get; }
    DbSet<Product> Products { get; }
    DbSet<SalesOrder> SalesOrders { get; }
    DbSet<SalesOrderItem> SalesOrderItems { get; }
    DbSet<InventoryItem> InventoryItems { get; }
    DbSet<InventoryMovement> InventoryMovements { get; }
    DbSet<Proof> Proofs { get; }
    DbSet<Reminder> Reminders { get; }
    // TECHNICAL
    DbSet<TechnicalQuote> TechnicalQuotes { get; }
    DbSet<TechnicalIntervention> TechnicalInterventions { get; }
    DbSet<TechnicalChecklistItem> TechnicalChecklistItems { get; }
    DbSet<TechnicalInvoice> TechnicalInvoices { get; }
    DbSet<TechnicalPaymentRecord> TechnicalPaymentRecords { get; }
    DbSet<MaintenancePlan> MaintenancePlans { get; }
    DbSet<MaintenanceTask> MaintenanceTasks { get; }

    // LIBERAL
    DbSet<ProspectContact> ProspectContacts { get; }
    DbSet<PipelineEvent> PipelineEvents { get; }
    DbSet<LiberalContract> LiberalContracts { get; }
    DbSet<LiberalInvoice> LiberalInvoices { get; }
    DbSet<LiberalProject> LiberalProjects { get; }
    DbSet<ProjectDeliverable> ProjectDeliverables { get; }
    DbSet<FinanceAccount> FinanceAccounts { get; }
    DbSet<FinanceTransaction> FinanceTransactions { get; }
    DbSet<FinanceBudget> FinanceBudgets { get; }
    DbSet<TechnicalQuoteItem> TechnicalQuoteItems { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
