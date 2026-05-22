using Microsoft.Extensions.DependencyInjection;
using SalesFlow.Application.Auth.Services;
using SalesFlow.Application.Catalog.Services;
using SalesFlow.Application.Clients.Services;
using SalesFlow.Application.Inventory.Services;
using SalesFlow.Application.Liberal.Services;
using SalesFlow.Application.Proofs.Services;
using SalesFlow.Application.Reminders.Services;
using SalesFlow.Application.Sales.Services;
using SalesFlow.Application.Technical.Services;
using System.Text;

namespace SalesFlow.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // Auth & Core
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IClientService, ClientService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<ISalesOrderService, SalesOrderService>();
        services.AddScoped<IInventoryService, InventoryService>();
        services.AddScoped<IProofService, ProofService>();
        services.AddScoped<IReminderService, ReminderService>();

        // Technical
        services.AddScoped<ITechnicalQuoteService, TechnicalQuoteService>();
        services.AddScoped<ITechnicalInterventionService, TechnicalInterventionService>();
        services.AddScoped<ITechnicalInvoiceService, TechnicalInvoiceService>();
        services.AddScoped<ITechnicalMaintenanceService, TechnicalMaintenanceService>();
        services.AddScoped<ITechnicalCalculatorService, TechnicalCalculatorService>();

        // Liberal
        services.AddScoped<ILiberalContractService, LiberalContractService>();
        services.AddScoped<ILiberalInvoiceService, LiberalInvoiceService>();
        services.AddScoped<IPipelineService, PipelineService>();
        services.AddScoped<ILiberalProjectService, LiberalProjectService>();
        services.AddScoped<ILiberalFinanceService, LiberalFinanceService>();

        return services;
    }
   
}
