using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class SalesOrderItemConfiguration : IEntityTypeConfiguration<SalesOrderItem>
{
    public void Configure(EntityTypeBuilder<SalesOrderItem> builder)
    {
        builder.ToTable("sales_order_items");
        builder.HasKey(i => i.Id);

        builder.Property(i => i.Description).IsRequired().HasMaxLength(500);
        builder.Property(i => i.UnitPrice).HasColumnType("numeric(12,2)");
        builder.Property(i => i.Quantity).HasColumnType("numeric(10,3)");
        builder.Property(i => i.Notes).HasMaxLength(500);

        builder.Ignore(i => i.LineTotal);  // Propriété calculée, pas stockée

        builder.HasIndex(i => i.SalesOrderId);

        // ProductId est optionnel : ligne libre autorisée
        builder.HasOne(i => i.Product)
               .WithMany()
               .HasForeignKey(i => i.ProductId)
               .OnDelete(DeleteBehavior.SetNull);  // Si produit supprimé, on garde la ligne
    }
}
