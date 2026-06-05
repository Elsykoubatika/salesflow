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

    // ─── AFFILIATE MODULE ──────────────────────────────────────────────────────
    public DbSet<Deal> Deals => Set<Deal>();
    public DbSet<DealShare> DealShares => Set<DealShare>();
    public DbSet<DealEvent> DealEvents => Set<DealEvent>();

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

        //
        modelBuilder.Entity<Deal>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CreatorUserId);
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => new { e.Status, e.ActiveFrom, e.ActiveTo });
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.CommissionType).HasMaxLength(8).IsRequired();
            entity.Property(e => e.Currency).HasMaxLength(8);
            entity.Property(e => e.Status).HasMaxLength(16);
            entity.Property(e => e.CommissionAmount).HasPrecision(18, 2);
            entity.Property(e => e.CommissionPercent).HasPrecision(5, 2);
        });

        modelBuilder.Entity<DealShare>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UniqueCode).IsUnique();
            entity.HasIndex(e => e.DealId);
            entity.HasIndex(e => e.AffiliateUserId);
            entity.HasIndex(e => new { e.DealId, e.AffiliateUserId, e.Channel })
                  .IsUnique(); // un seul lien par (deal, affilié, canal)
            entity.Property(e => e.UniqueCode).HasMaxLength(16).IsRequired();
            entity.Property(e => e.Channel).HasMaxLength(16).IsRequired();
        });

        modelBuilder.Entity<DealEvent>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.DealShareId);
            entity.HasIndex(e => e.EventType);
            entity.HasIndex(e => new { e.DealShareId, e.EventType, e.CreatedAt });
            entity.Property(e => e.EventType).HasMaxLength(8).IsRequired();
            entity.Property(e => e.IpHash).HasMaxLength(32);
            entity.Property(e => e.UserAgent).HasMaxLength(200);
            entity.Property(e => e.SaleAmount).HasPrecision(18, 2);
            entity.Property(e => e.CommissionEarned).HasPrecision(18, 2);
        });

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
