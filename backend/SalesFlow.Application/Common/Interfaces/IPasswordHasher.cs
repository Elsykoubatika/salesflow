namespace SalesFlow.Application.Common.Interfaces;

/// <summary>
/// Hashage et vérification des mots de passe (BCrypt).
/// </summary>
public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string hash);
}
