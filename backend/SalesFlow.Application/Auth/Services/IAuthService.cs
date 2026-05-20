using SalesFlow.Application.Auth.DTOs;
using SalesFlow.Application.Common.Models;

namespace SalesFlow.Application.Auth.Services;

public interface IAuthService
{
    Task<Result<AuthResponse>> RegisterAsync(RegisterRequest request, CancellationToken ct = default);
    Task<Result<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default);
}
