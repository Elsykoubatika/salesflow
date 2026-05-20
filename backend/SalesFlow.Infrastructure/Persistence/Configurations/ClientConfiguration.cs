using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class ClientConfiguration : IEntityTypeConfiguration<Client>
{
    public void Configure(EntityTypeBuilder<Client> builder)
    {
        builder.ToTable("clients");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.FullName).IsRequired().HasMaxLength(150);
        builder.Property(c => c.PhoneNumber).HasMaxLength(30);
        builder.Property(c => c.Email).HasMaxLength(254);
        builder.Property(c => c.Address).HasMaxLength(300);
        builder.Property(c => c.Region).HasMaxLength(100);
        builder.Property(c => c.Notes).HasMaxLength(1000);

        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => new { c.UserId, c.PhoneNumber });

        builder.HasOne(c => c.User)
               .WithMany(u => u.Clients)
               .HasForeignKey(c => c.UserId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
