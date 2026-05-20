using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Clients.DTOs;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Clients.Services;

public class ClientService : IClientService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public ClientService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<ClientListResponse>> ListAsync(int page, int pageSize, string? search, CancellationToken ct = default)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        // Sanitize pagination
        page = page < 1 ? 1 : page;
        pageSize = pageSize switch
        {
            < 1 => DefaultPageSize,
            > MaxPageSize => MaxPageSize,
            _ => pageSize
        };

        var query = _db.Clients.AsNoTracking().Where(c => c.UserId == userId);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(c =>
                c.FullName.ToLower().Contains(s) ||
                (c.PhoneNumber != null && c.PhoneNumber.ToLower().Contains(s)) ||
                (c.Email != null && c.Email.ToLower().Contains(s)) ||
                (c.Region != null && c.Region.ToLower().Contains(s))
            );
        }

        var total = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(c => c.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => Map(c))
            .ToListAsync(ct);

        return Result<ClientListResponse>.Success(new ClientListResponse(items, total, page, pageSize));
    }

    public async Task<Result<ClientResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        var client = await _db.Clients.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        return client is null
            ? Result<ClientResponse>.Failure("Client introuvable.")
            : Result<ClientResponse>.Success(Map(client));
    }

    public async Task<Result<ClientResponse>> CreateAsync(CreateClientRequest request, CancellationToken ct = default)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        var client = new Client
        {
            UserId = userId,
            FullName = request.FullName.Trim(),
            PhoneNumber = request.PhoneNumber?.Trim(),
            Email = request.Email?.Trim().ToLowerInvariant(),
            Address = request.Address?.Trim(),
            Region = request.Region?.Trim(),
            Notes = request.Notes?.Trim()
        };

        _db.Clients.Add(client);
        await _db.SaveChangesAsync(ct);

        return Result<ClientResponse>.Success(Map(client));
    }

    public async Task<Result<ClientResponse>> UpdateAsync(Guid id, UpdateClientRequest request, CancellationToken ct = default)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        var client = await _db.Clients
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        if (client is null)
            return Result<ClientResponse>.Failure("Client introuvable.");

        client.FullName = request.FullName.Trim();
        client.PhoneNumber = request.PhoneNumber?.Trim();
        client.Email = request.Email?.Trim().ToLowerInvariant();
        client.Address = request.Address?.Trim();
        client.Region = request.Region?.Trim();
        client.Notes = request.Notes?.Trim();

        await _db.SaveChangesAsync(ct);  // UpdatedAt mis à jour automatiquement par AppDbContext

        return Result<ClientResponse>.Success(Map(client));
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        var client = await _db.Clients
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        if (client is null)
            return Result<bool>.Failure("Client introuvable.");

        _db.Clients.Remove(client);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static ClientResponse Map(Client c) => new(
        c.Id, c.FullName, c.PhoneNumber, c.Email, c.Address, c.Region, c.Notes, c.CreatedAt, c.UpdatedAt
    );
}
