using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class InventoryMovementConfiguration : IEntityTypeConfiguration<InventoryMovement>
{
    public void Configure(EntityTypeBuilder<InventoryMovement> builder)
    {
        builder.ToTable("inventory_movements");
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Change).HasColumnType("numeric(14,3)");
        builder.Property(m => m.ResultingQuantity).HasColumnType("numeric(14,3)");
        builder.Property(m => m.Reason).HasConversion<int>();
        builder.Property(m => m.Note).HasMaxLength(500);

        builder.HasIndex(m => m.InventoryItemId);
        builder.HasIndex(m => new { m.InventoryItemId, m.CreatedAt });
        builder.HasIndex(m => m.SalesOrderId);
    }
}
