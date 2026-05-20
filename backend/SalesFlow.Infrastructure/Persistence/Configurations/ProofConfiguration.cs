using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class ProofConfiguration : IEntityTypeConfiguration<Proof>
{
    public void Configure(EntityTypeBuilder<Proof> builder)
    {
        builder.ToTable("proofs");
        builder.HasKey(p => p.Id);

        // Image binaire en bytea
        builder.Property(p => p.ImageBytes).HasColumnType("bytea");
        builder.Property(p => p.ImageContentType).IsRequired().HasMaxLength(50);

        builder.Property(p => p.Amount).HasColumnType("numeric(14,2)");
        builder.Property(p => p.Currency).IsRequired().HasMaxLength(3).HasDefaultValue("XAF");
        builder.Property(p => p.TransactionReference).HasMaxLength(100);
        builder.Property(p => p.Notes).HasMaxLength(1000);
        builder.Property(p => p.ErrorMessage).HasMaxLength(500);

        builder.Property(p => p.Operator).HasConversion<int>();
        builder.Property(p => p.Status).HasConversion<int>();

        builder.HasIndex(p => p.UserId);
        builder.HasIndex(p => new { p.UserId, p.Status });
        builder.HasIndex(p => p.TransactionReference);

        builder.HasOne(p => p.User)
               .WithMany()
               .HasForeignKey(p => p.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.Client)
               .WithMany()
               .HasForeignKey(p => p.ClientId)
               .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(p => p.SalesOrder)
               .WithMany()
               .HasForeignKey(p => p.SalesOrderId)
               .OnDelete(DeleteBehavior.SetNull);
    }
}
