using SalesFlow.Application.Common.Interfaces;

namespace SalesFlow.Infrastructure.Auth;

public class BcryptPasswordHasher : IPasswordHasher
{
    // Work factor 12 = bon compromis sécurité/performance en 2026 (~250ms par hash)
    private const int WorkFactor = 12;

    public string Hash(string password)
        => BCrypt.Net.BCrypt.HashPassword(password, WorkFactor);

    public bool Verify(string password, string hash)
        => BCrypt.Net.BCrypt.Verify(password, hash);
}
