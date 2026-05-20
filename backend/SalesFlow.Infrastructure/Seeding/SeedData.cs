using Microsoft.EntityFrameworkCore;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;  // ✅ Add this
using SalesFlow.Infrastructure.Persistence;

namespace SalesFlow.Infrastructure.Seeding;

public static class SeedDataFixed
{
    private static readonly Guid TestUserId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private static readonly string SeedUser = "SeedData";
    private static readonly DateTime SeedTime = DateTime.UtcNow;

    /// <summary>
    /// Seed test user first, then products, then clients
    /// </summary>
    public static async Task SeedAllAsync(AppDbContext dbContext)
    {
        await SeedTestUserAsync(dbContext);
        await SeedProductsAsync(dbContext);
        await SeedClientsAsync(dbContext);
    }

    /// <summary>
    /// ✅ NEW: Seed test user first (required for FK constraints)
    /// </summary>
    public static async Task SeedTestUserAsync(AppDbContext dbContext)
    {
        if (await dbContext.Users.AnyAsync()) return;

        // ✅ Générateur le hash au runtime
        var plainPassword = "Password123!";
        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(plainPassword, workFactor: 12);

        var testUser = new User
        {
            Id = TestUserId,
            Email = "test@cowema.cg",
            PasswordHash = hashedPassword, // In real app, hash this properly
            FullName = "Test User",
            PhoneNumber = "+242050000000",
            DomainType = DomainType.Commerce,
            IsActive = true,
            CreatedAt = SeedTime,
            CreatedBy = SeedUser
        };

        dbContext.Users.Add(testUser);
        await dbContext.SaveChangesAsync();
    }

    public static async Task SeedProductsAsync(AppDbContext dbContext)
    {
        if (await dbContext.Products.AnyAsync()) return;

        var products = GetProducts();
        dbContext.Products.AddRange(products);
        await dbContext.SaveChangesAsync();
    }

    public static async Task SeedClientsAsync(AppDbContext dbContext)
    {
        if (await dbContext.Clients.AnyAsync()) return;

        var clients = GetClients();
        dbContext.Clients.AddRange(clients);
        await dbContext.SaveChangesAsync();
    }

    private static List<Product> GetProducts()
    {
        return new List<Product>
        {
            // ÉLECTRONIQUE (5 items)
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Disjoncteur 10A",
                Sku = "DISJ-10A-001",
                Description = "Disjoncteur unipolaire 10 ampères pour circuits électriques standard. Conforme NFC15-100. Legrand.",
                Price = 12000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Disjoncteur+10A",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Prise électrique simple",
                Sku = "PRISE-SIMP-001",
                Description = "Prise électrique murale simple 16A pour usage domestique. Installation murale. Schneider Electric.",
                Price = 3500m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Prise+Simple",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Câble électrique 2.5mm²",
                Sku = "CABLE-2.5-001",
                Description = "Câble électrique souple 2.5mm² pour circuits électriques. Rouleau 100m. Cuivre haute qualité Nexans.",
                Price = 85000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Câble+2.5mm",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Tableau électrique 6 modules",
                Sku = "TABLEAU-6M-001",
                Description = "Tableau de distribution électrique 6 modules 230V avec porte et serrure. Schneider Electric.",
                Price = 45000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Tableau+6M",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Interrupteur mural",
                Sku = "INTER-MUR-001",
                Description = "Interrupteur mural simple 10A pour éclairage. Blanc ivoire. Legrand.",
                Price = 4200m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Interrupteur",
                IsActive = true
            },

            // MATÉRIAUX BTP (5 items)
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Sac de ciment Simon 50kg",
                Sku = "CIMENT-50KG-001",
                Description = "Sac de ciment Portland 50kg pour béton et mortier. Couverture 1.8m² @ 15cm. Simon Ciments.",
                Price = 6500m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Ciment+50kg",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Tuyauterie PVC 20mm",
                Sku = "TUYAU-PVC20-001",
                Description = "Tuyau PVC rigide 20mm pour installations plomberie. Longueur 1m. Plastinor.",
                Price = 2500m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Tuyau+PVC",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Fil électrique rouleau 100m",
                Sku = "FIL-ELEC-100M",
                Description = "Fil électrique isolé rouleau 100 mètres. 1.5mm² cuivre haute qualité. Nexans Congo.",
                Price = 18000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Fil+100m",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Boîte de jonction plastique",
                Sku = "BOITE-JONCT-001",
                Description = "Boîte de jonction électrique plastique 100x100mm. Étanche IP65. Legrand.",
                Price = 3000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Boîte+Jonction",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Peinture blanche 10L",
                Sku = "PAINT-10L-001",
                Description = "Peinture acrylique blanche 10 litres pour murs intérieurs. Couvre 120m². AgIP Paint.",
                Price = 80000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Peinture+10L",
                IsActive = true
            },

            // PLOMBERIE (5 items)
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Robinet cuisine inox",
                Sku = "ROBIN-INOX-001",
                Description = "Robinet mélangeur mitigeur cuisine en inox brossé avec tuyau renforcé. Grohe.",
                Price = 75000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Robinet+Cuisine",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Tuyau flexible 1m",
                Sku = "TUYAU-FLEX-001",
                Description = "Tuyau flexible acier inox 1 mètre connexion 3/4\". Haute pression 40 bars. Watts.",
                Price = 8500m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Tuyau+Flexible",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Raccord T-PVC 20mm",
                Sku = "RACCORD-T-001",
                Description = "Raccord en T PVC pour tuyauterie 20mm. Connexion par colle. Plastinor.",
                Price = 1200m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Raccord+T",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Siphon évier",
                Sku = "SIPHON-EVIER-001",
                Description = "Siphon en P pour évier cuisine 1.5\" chromé avec bouchon nettoyage. Geberit.",
                Price = 12000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Siphon+Évier",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Seau eau 20L",
                Sku = "SEAU-20L-001",
                Description = "Seau en plastique bleu 20 litres avec anse. Réutilisable. HDPE Industrial.",
                Price = 4500m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Seau+20L",
                IsActive = true
            },

            // SERVICES & PRESTATIONS (5 items)
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Intervention électrique",
                Sku = "SERV-ELEC-001",
                Description = "Service d'intervention électrique par électricien qualifié. Tarif: 35k XAF/heure.",
                Price = 35000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Intervention+Électrique",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Dépannage plomberie",
                Sku = "SERV-PLOMB-001",
                Description = "Service de dépannage plomberie 24h/24 7j/7. Tarif: 40k XAF/heure + matériaux.",
                Price = 40000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Dépannage+Plomberie",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Consultation technique",
                Sku = "CONS-TECH-001",
                Description = "Consultation technique pour diagnostic et devis. Durée: 30min à 1h. Tarif: 25k XAF.",
                Price = 25000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Consultation",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Formation groupe électricité",
                Sku = "FORM-ELEC-001",
                Description = "Formation groupe sur normes électriques NFC15-100. 8 heures, 10-20 personnes. Tarif: 500k XAF.",
                Price = 500000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Formation+Électricité",
                IsActive = true
            },
            new Product
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                Name = "Maintenance annuelle",
                Sku = "MAINT-ANN-001",
                Description = "Contrat de maintenance annuelle installations électriques. 4 visites/an + dépannage inclus. Tarif: 250k XAF.",
                Price = 250000m,
                Currency = "XAF",
                ImageUrl = "https://via.placeholder.com/300x300?text=Maintenance+Annuelle",
                IsActive = true
            }
        };
    }

    private static List<Client> GetClients()
    {
        return new List<Client>
        {
            new Client
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                FullName = "ECAB Consulting SARL",
                Email = "contact@ecab.cd",
                PhoneNumber = "+243991234567",
                Address = "Gombe, Kinshasa",
                Region = "Kasai",
                Notes = "Entreprise - Contact: Jean Durand"
            },
            new Client
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                FullName = "Impact Group Congo",
                Email = "info@impact-group.cd",
                PhoneNumber = "+243987654321",
                Address = "Plateau, Kinshasa",
                Region = "Kasai",
                Notes = "Entreprise - Contact: Marie Okolo"
            },
            new Client
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                FullName = "TradeHub Congo",
                Email = "hello@tradehub.cd",
                PhoneNumber = "+243992345678",
                Address = "Limete, Kinshasa",
                Region = "Kasai",
                Notes = "Entreprise - Contact: Paul Mfuamba"
            },
            new Client
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                FullName = "Jean Kasongo",
                Email = "jean.kasongo@email.com",
                PhoneNumber = "+243993456789",
                Address = "Barumbu, Kinshasa",
                Region = "Kasai",
                Notes = "Client particulier - Réparations électriques"
            },
            new Client
            {
                UserId = TestUserId,
                CreatedAt = SeedTime,
                CreatedBy = SeedUser,
                FullName = "Marie Okolo",
                Email = "marie.okolo@email.com",
                PhoneNumber = "+243994567890",
                Address = "La Gombe, Kinshasa",
                Region = "Kasai",
                Notes = "Client particulier - Travaux plomberie"
            }
        };
    }
}