using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Infrastructure.Persistence.Configurations;

public class ReminderConfiguration : IEntityTypeConfiguration<Reminder>
{
    public void Configure(EntityTypeBuilder<Reminder> builder)
    {
        builder.ToTable("reminders");
        builder.HasKey(r => r.Id);

        builder.Property(r => r.Type).IsRequired().HasMaxLength(50);
        builder.Property(r => r.Title).IsRequired().HasMaxLength(200);
        builder.Property(r => r.Message).IsRequired().HasMaxLength(1000);

        builder.HasIndex(r => r.UserId);
        builder.HasIndex(r => new { r.UserId, r.IsRead });
        builder.HasIndex(r => r.ScheduledFor);

        builder.HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.SalesOrder)
            .WithMany()
            .HasForeignKey(r => r.SalesOrderId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
