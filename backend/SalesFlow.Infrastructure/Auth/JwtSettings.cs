namespace SalesFlow.Infrastructure.Auth;

public class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;       // Au moins 32 caractères
    public int ExpiryMinutes { get; set; } = 60 * 24;     // 24h par défaut
}
