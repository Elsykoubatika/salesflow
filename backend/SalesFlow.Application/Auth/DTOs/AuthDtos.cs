using System.ComponentModel.DataAnnotations;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Auth.DTOs;

public record RegisterRequest(
    [Required, EmailAddress] string Email,
    [Required, MinLength(8)] string Password,
    [Required] string FullName,
    string? PhoneNumber,
    DomainType DomainType
);

public record LoginRequest(
    [Required, EmailAddress] string Email,
    [Required] string Password
);

public record AuthResponse(
    string Token,
    Guid UserId,
    string Email,
    string FullName,
    DomainType DomainType
);
