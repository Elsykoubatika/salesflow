using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SalesFlow.Application;
using SalesFlow.Infrastructure;
using SalesFlow.Infrastructure.Auth;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Infrastructure.Seeding;
using System.Text;

// QuestPDF - licence communautaire (gratuite < 1M$ revenu annuel)
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

var builder = WebApplication.CreateBuilder(args);

// ─── Services ────────────────────────────────────────────────────────────────

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Accès au HttpContext pour récupérer l'utilisateur connecté dans les services
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<SalesFlow.Application.Common.Security.ICurrentUser, SalesFlow.API.Security.CurrentUser>();

// Application + Infrastructure (DbContext, JWT, hasher, services métier)
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// JWT - lecture des paramètres depuis appsettings.json
var jwtSettings = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>()
    ?? throw new InvalidOperationException("Section 'Jwt' manquante dans la configuration.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings.Issuer,
            ValidAudience = jwtSettings.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddAuthorization();

// CORS - permissif en dev, à restreindre en prod
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

// Swagger avec support du Bearer JWT
builder.Services.AddSwaggerGen(opt =>
{
    opt.SwaggerDoc("v1", new OpenApiInfo { Title = "SalesFlow Pro Congo API", Version = "v1" });

    var jwtScheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Description = "Entrer 'Bearer {token}' (sans guillemets)",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        Reference = new OpenApiReference { Id = "Bearer", Type = ReferenceType.SecurityScheme }
    };
    opt.AddSecurityDefinition("Bearer", jwtScheme);
    opt.AddSecurityRequirement(new OpenApiSecurityRequirement { { jwtScheme, Array.Empty<string>() } });
});

// ─── Pipeline ────────────────────────────────────────────────────────────────

var app = builder.Build();

// Applique automatiquement les migrations EF au démarrage en environnement de dev
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

    try
    {
        // Apply migrations
        await dbContext.Database.MigrateAsync();
        Console.WriteLine("✅ Migrations applied successfully");

        // Seed data (20 articles + 5 clients)
        await SeedDataFixed.SeedProductsAsync(dbContext);
        Console.WriteLine("✅ 20 products seeded");

        await SeedDataFixed.SeedClientsAsync(dbContext);
        Console.WriteLine("✅ 5 clients seeded");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Error during seeding: {ex.Message}");
        throw;
    }

    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();