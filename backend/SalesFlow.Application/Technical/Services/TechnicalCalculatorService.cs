namespace SalesFlow.Application.Technical.Services;

public interface ITechnicalCalculatorService
{
    TechnicalCalculationResult CalculateCementBags(decimal wallAreaSqMeters);
    TechnicalCalculationResult CalculateCircuitBreakers(decimal powerLoadKW, string breakerType);
    TechnicalCalculationResult CalculateElectricalOutlets(int bedrooms, int bathrooms, int kitchens);
    TechnicalCalculationResult CalculatePlumbingPipes(int bathrooms, int kitchens);
}

public class TechnicalCalculatorService : ITechnicalCalculatorService
{
    public TechnicalCalculationResult CalculateCementBags(decimal wallAreaSqMeters)
    {
        decimal coveragePerBag = 1.8m;
        decimal bagsNeeded = Math.Ceiling(wallAreaSqMeters / coveragePerBag);
        return new TechnicalCalculationResult
        {
            ItemName = "Sacs de ciment Simon 50kg",
            Quantity = bagsNeeded,
            Unit = "sacs",
            UnitPrice = 6500m,
            Description = $"Pour {wallAreaSqMeters} m²",
            Formula = $"Aire ÷ couverture = {wallAreaSqMeters}m² ÷ {coveragePerBag}m² = {bagsNeeded} sacs"
        };
    }

    public TechnicalCalculationResult CalculateCircuitBreakers(decimal powerLoadKW, string breakerType)
    {
        decimal ampsNeeded = (powerLoadKW * 1000) / 230m;
        decimal breakerRating = ExtractBreakerRating(breakerType);
        decimal breakersNeeded = Math.Ceiling(ampsNeeded / breakerRating);
        return new TechnicalCalculationResult
        {
            ItemName = $"Disjoncteurs {breakerType}",
            Quantity = breakersNeeded,
            Unit = "pièces",
            UnitPrice = 12000m,
            Description = $"Charge {powerLoadKW}kW",
            Formula = $"({powerLoadKW}kW × 1000) ÷ 230V = {ampsNeeded:F0}A ÷ {breakerRating}A = {breakersNeeded}"
        };
    }

    public TechnicalCalculationResult CalculateElectricalOutlets(int bedrooms, int bathrooms, int kitchens)
    {
        int totalOutlets = (bedrooms * 3) + (bathrooms * 2) + (kitchens * 6) + 4;
        return new TechnicalCalculationResult
        {
            ItemName = "Prises électriques",
            Quantity = totalOutlets,
            Unit = "pièces",
            UnitPrice = 3500m,
            Description = $"NFC15-100: {bedrooms} ch + {bathrooms} sdb + {kitchens} cuisine",
            Formula = $"({bedrooms}×3) + ({bathrooms}×2) + ({kitchens}×6) + 4 = {totalOutlets}"
        };
    }

    public TechnicalCalculationResult CalculatePlumbingPipes(int bathrooms, int kitchens)
    {
        decimal metersNeeded = (bathrooms * 15) + (kitchens * 12) + 20;
        return new TechnicalCalculationResult
        {
            ItemName = "Tuyauterie PVC",
            Quantity = metersNeeded,
            Unit = "mètres",
            UnitPrice = 2500m,
            Description = $"{bathrooms} sdb + {kitchens} cuisine",
            Formula = $"({bathrooms}×15) + ({kitchens}×12) + 20 = {metersNeeded}m"
        };
    }

    private decimal ExtractBreakerRating(string type) => type switch { "10A" => 10, "16A" => 16, "20A" => 20, "32A" => 32, "63A" => 63, _ => 10 };
}

public class TechnicalCalculationResult
{
    public string ItemName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public decimal Total => Quantity * UnitPrice;
    public string Description { get; set; } = string.Empty;
    public string Formula { get; set; } = string.Empty;
}
