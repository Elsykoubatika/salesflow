using Microsoft.Extensions.DependencyInjection;
using SalesFlow.Application.Auth.Services;
using SalesFlow.Application.Catalog.Services;
using SalesFlow.Application.Clients.Services;
using SalesFlow.Application.Inventory.Services;
using SalesFlow.Application.Proofs.Services;
using SalesFlow.Application.Sales.Services;

namespace SalesFlow.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IClientService, ClientService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<ISalesOrderService, SalesOrderService>();
        services.AddScoped<IInventoryService, InventoryService>();
        services.AddScoped<IProofService, ProofService>();
        return services;
    }
}
