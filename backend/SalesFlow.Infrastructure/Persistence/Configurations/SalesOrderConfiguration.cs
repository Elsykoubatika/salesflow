using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class SalesOrderConfiguration : IEntityTypeConfiguration<SalesOrder>
{
    public void Configure(EntityTypeBuilder<SalesOrder> builder)
    {
        builder.ToTable("sales_orders");
        builder.HasKey(o => o.Id);

        builder.Property(o => o.OrderNumber).IsRequired().HasMaxLength(30);
        builder.Property(o => o.Status).HasConversion<int>();
        builder.Property(o => o.Currency).IsRequired().HasMaxLength(3).HasDefaultValue("XAF");

        builder.Property(o => o.Subtotal).HasColumnType("numeric(14,2)");
        builder.Property(o => o.TaxAmount).HasColumnType("numeric(14,2)");
        builder.Property(o => o.Total).HasColumnType("numeric(14,2)");

        builder.Property(o => o.Notes).HasMaxLength(2000);
        builder.Property(o => o.CancellationReason).HasMaxLength(500);

        builder.HasIndex(o => o.UserId);
        builder.HasIndex(o => new { o.UserId, o.Status });
        builder.HasIndex(o => new { o.UserId, o.OrderNumber }).IsUnique();

        builder.HasOne(o => o.User)
               .WithMany()
               .HasForeignKey(o => o.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(o => o.Client)
               .WithMany()
               .HasForeignKey(o => o.ClientId)
               .OnDelete(DeleteBehavior.Restrict);  // Ne pas supprimer un client référencé

        builder.HasMany(o => o.Items)
               .WithOne(i => i.SalesOrder)
               .HasForeignKey(i => i.SalesOrderId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
