using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Quartz;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Documents.Services;
using SalesFlow.Application.Reminders.Services;
using SalesFlow.Infrastructure.Auth;
using SalesFlow.Infrastructure.Documents;
using SalesFlow.Infrastructure.Jobs;
using SalesFlow.Infrastructure.Persistence;

namespace SalesFlow.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // EF Core + PostgreSQL
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' manquante.");

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());

        // Authentification
        services.Configure<JwtSettings>(configuration.GetSection(JwtSettings.SectionName));
        services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();
        services.AddSingleton<IPasswordHasher, BcryptPasswordHasher>();

        // Génération PDF
        services.AddScoped<IDocumentGenerator, PdfDocumentGenerator>();

        // Reminders
        services.AddScoped<IReminderService, ReminderService>();

        // Quartz Job Scheduler
        services.AddQuartz(q =>
        {
            
            var jobKey = new JobKey(nameof(OverdueOrdersReminderJob));
            q.AddJob<OverdueOrdersReminderJob>(opts => opts.WithIdentity(jobKey));
            
            q.AddTrigger(opts =>
                opts.ForJob(jobKey)
                    .WithIdentity($"{nameof(OverdueOrdersReminderJob)}-trigger")
                    .WithCronSchedule("0 0 * * * ?") // Every hour at minute 0
            );
        });

        services.AddQuartzHostedService(q => q.WaitForJobsToComplete = true);

        return services;
    }
}
