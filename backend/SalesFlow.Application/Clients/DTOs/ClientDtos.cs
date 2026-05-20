using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Clients.DTOs;

public record CreateClientRequest(
    [Required, MaxLength(150)] string FullName,
    [MaxLength(30)] string? PhoneNumber,
    [EmailAddress, MaxLength(254)] string? Email,
    [MaxLength(300)] string? Address,
    [MaxLength(100)] string? Region,
    [MaxLength(1000)] string? Notes
);

public record UpdateClientRequest(
    [Required, MaxLength(150)] string FullName,
    [MaxLength(30)] string? PhoneNumber,
    [EmailAddress, MaxLength(254)] string? Email,
    [MaxLength(300)] string? Address,
    [MaxLength(100)] string? Region,
    [MaxLength(1000)] string? Notes
);

public record ClientResponse(
    Guid Id,
    string FullName,
    string? PhoneNumber,
    string? Email,
    string? Address,
    string? Region,
    string? Notes,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record ClientListResponse(
    IEnumerable<ClientResponse> Items,
    int Total,
    int Page,
    int PageSize
);
