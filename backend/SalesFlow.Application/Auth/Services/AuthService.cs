using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Auth.DTOs;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Auth.Services;

public class AuthService : IAuthService
{
    private readonly IAppDbContext _db;
    private readonly IPasswordHasher _hasher;
    private readonly IJwtTokenGenerator _tokenGenerator;

    public AuthService(IAppDbContext db, IPasswordHasher hasher, IJwtTokenGenerator tokenGenerator)
    {
        _db = db;
        _hasher = hasher;
        _tokenGenerator = tokenGenerator;
    }

    public async Task<Result<AuthResponse>> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        // Vérifier l'unicité de l'email (case-insensitive)
        var emailLower = request.Email.Trim().ToLowerInvariant();
        var emailExists = await _db.Users.AnyAsync(u => u.Email == emailLower, ct);
        if (emailExists)
            return Result<AuthResponse>.Failure("Un compte existe déjà avec cet email.");

        var user = new User
        {
            Email = emailLower,
            PasswordHash = _hasher.Hash(request.Password),
            FullName = request.FullName.Trim(),
            PhoneNumber = request.PhoneNumber?.Trim(),
            DomainType = request.DomainType
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync(ct);

        var token = _tokenGenerator.GenerateToken(user);
        return Result<AuthResponse>.Success(new AuthResponse(token, user.Id, user.Email, user.FullName, user.DomainType));
    }

    public async Task<Result<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var emailLower = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == emailLower, ct);

        // Message volontairement générique pour ne pas révéler l'existence du compte
        if (user is null || !_hasher.Verify(request.Password, user.PasswordHash))
            return Result<AuthResponse>.Failure("Email ou mot de passe incorrect.");

        if (!user.IsActive)
            return Result<AuthResponse>.Failure("Ce compte est désactivé.");

        var token = _tokenGenerator.GenerateToken(user);
        return Result<AuthResponse>.Success(new AuthResponse(token, user.Id, user.Email, user.FullName, user.DomainType));
    }
}
