using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("products");
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Name).IsRequired().HasMaxLength(150);
        builder.Property(p => p.Description).HasMaxLength(2000);
        builder.Property(p => p.Sku).HasMaxLength(50);

        // Précision monétaire : 12 chiffres dont 2 décimales (jusqu'à 9 999 999 999,99)
        builder.Property(p => p.Price).HasColumnType("numeric(12,2)");

        builder.Property(p => p.Currency).IsRequired().HasMaxLength(3).HasDefaultValue("XAF");
        builder.Property(p => p.ImageUrl).HasMaxLength(500);

        // VariantsJson stocké comme jsonb pour permettre d'éventuelles requêtes natives Postgres
        builder.Property(p => p.VariantsJson).HasColumnType("jsonb");

        builder.HasIndex(p => p.UserId);
        builder.HasIndex(p => new { p.UserId, p.IsActive });

        builder.HasOne(p => p.User)
               .WithMany()
               .HasForeignKey(p => p.UserId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
