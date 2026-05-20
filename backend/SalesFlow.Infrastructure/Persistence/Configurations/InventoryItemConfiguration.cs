using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class InventoryItemConfiguration : IEntityTypeConfiguration<InventoryItem>
{
    public void Configure(EntityTypeBuilder<InventoryItem> builder)
    {
        builder.ToTable("inventory_items");
        builder.HasKey(i => i.Id);

        builder.Property(i => i.Name).IsRequired().HasMaxLength(150);
        builder.Property(i => i.Sku).HasMaxLength(50);
        builder.Property(i => i.Description).HasMaxLength(1000);
        builder.Property(i => i.Unit).IsRequired().HasMaxLength(10).HasDefaultValue("pcs");

        builder.Property(i => i.Quantity).HasColumnType("numeric(14,3)");
        builder.Property(i => i.ReorderThreshold).HasColumnType("numeric(14,3)");
        builder.Property(i => i.Cost).HasColumnType("numeric(12,2)");

        // Propriétés calculées : ne pas créer de colonnes
        builder.Ignore(i => i.IsLowStock);
        builder.Ignore(i => i.StockValue);

        builder.HasIndex(i => i.UserId);
        builder.HasIndex(i => new { i.UserId, i.IsActive });
        builder.HasIndex(i => new { i.UserId, i.Sku });

        builder.HasOne(i => i.User)
               .WithMany()
               .HasForeignKey(i => i.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(i => i.Product)
               .WithMany()
               .HasForeignKey(i => i.ProductId)
               .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(i => i.Movements)
               .WithOne(m => m.InventoryItem)
               .HasForeignKey(m => m.InventoryItemId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
