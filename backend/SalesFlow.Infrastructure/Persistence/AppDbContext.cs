using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Domain.Common;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence;

public class AppDbContext : DbContext, IAppDbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Client> Clients => Set<Client>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<SalesOrder> SalesOrders => Set<SalesOrder>();
    public DbSet<SalesOrderItem> SalesOrderItems => Set<SalesOrderItem>();
    public DbSet<InventoryItem> InventoryItems => Set<InventoryItem>();
    public DbSet<InventoryMovement> InventoryMovements => Set<InventoryMovement>();
    public DbSet<Proof> Proofs => Set<Proof>();
    public DbSet<Reminder> Reminders => Set<Reminder>();

    // ─── TECHNICAL MODULE ────────────────────────────────────────────────────
    public DbSet<TechnicalQuote> TechnicalQuotes => Set<TechnicalQuote>();
    public DbSet<TechnicalQuoteItem> TechnicalQuoteItems => Set<TechnicalQuoteItem>();
    public DbSet<TechnicalIntervention> TechnicalInterventions => Set<TechnicalIntervention>();
    public DbSet<TechnicalChecklistItem> TechnicalChecklistItems => Set<TechnicalChecklistItem>();
    public DbSet<TechnicalInvoice> TechnicalInvoices => Set<TechnicalInvoice>();
    public DbSet<TechnicalPaymentRecord> TechnicalPaymentRecords => Set<TechnicalPaymentRecord>();
    public DbSet<MaintenancePlan> MaintenancePlans => Set<MaintenancePlan>();
    public DbSet<MaintenanceTask> MaintenanceTasks => Set<MaintenanceTask>();

    // ─── LIBERAL MODULE ──────────────────────────────────────────────────────
    public DbSet<ProspectContact> ProspectContacts => Set<ProspectContact>();
    public DbSet<PipelineEvent> PipelineEvents => Set<PipelineEvent>();
    public DbSet<LiberalContract> LiberalContracts => Set<LiberalContract>();
    public DbSet<LiberalInvoice> LiberalInvoices => Set<LiberalInvoice>();
    public DbSet<LiberalProject> LiberalProjects => Set<LiberalProject>();
    public DbSet<ProjectDeliverable> ProjectDeliverables => Set<ProjectDeliverable>();
    public DbSet<FinanceAccount> FinanceAccounts => Set<FinanceAccount>();
    public DbSet<FinanceTransaction> FinanceTransactions => Set<FinanceTransaction>();
    public DbSet<FinanceBudget> FinanceBudgets => Set<FinanceBudget>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Charge automatiquement toutes les configurations IEntityTypeConfiguration
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        base.OnModelCreating(modelBuilder);

        // ✅ Simple, explicit relationship configuration
        modelBuilder.Entity<TechnicalChecklistItem>()
            .HasOne(x => x.TechnicalIntervention)
            .WithMany(x => x.ChecklistItems)
            .HasForeignKey(x => x.TechnicalInterventionId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Met à jour automatiquement UpdatedAt sur toute entité modifiée
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Modified)
                entry.Entity.UpdatedAt = DateTime.UtcNow;
        }
        return base.SaveChangesAsync(cancellationToken);
    }
}
