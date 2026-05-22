using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Liberal.DTOs;

public record CreateProspectContactRequest(
    [Required, MaxLength(200)] string CompanyName,
    [Required, MaxLength(150)] string ContactPerson,
    [Phone, MaxLength(20)] string? PhoneNumber,
    [EmailAddress, MaxLength(254)] string? Email,
    [MaxLength(100)] string? Source,
    [Range(0, 999_999_999)] decimal EstimatedValue,
    [MaxLength(500)] string? Notes
);

public record UpdateProspectContactRequest(
    [Required, MaxLength(200)] string CompanyName,
    [Required, MaxLength(150)] string ContactPerson,
    [Phone, MaxLength(20)] string? PhoneNumber,
    [EmailAddress, MaxLength(254)] string? Email,
    [Range(0, 999_999_999)] decimal EstimatedValue,
    [MaxLength(500)] string? Notes
);

public record UpdateProspectStageRequest(
    [Required] string Stage, // Prospect, Discussion, Proposal, Negotiation, Signed, Lost
    [MaxLength(500)] string? Notes
);

public record ProspectContactResponse(
    Guid Id,
    string CompanyName,
    string ContactPerson,
    string? PhoneNumber,
    string? Email,
    string? Source,
    decimal EstimatedValue,
    string Stage,
    decimal Probability,
    DateTime? NextFollowUpDate,
    string? Notes,
    int EventCount,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record ProspectListResponse(
    IEnumerable<ProspectContactResponse> Items,
    int Total,
    int Page,
    int PageSize
);

public record CreatePipelineEventRequest(
    [Required, MaxLength(100)] string EventType, // Call, Meeting, Email, Proposal, Contract Signed
    [Required] DateTime EventDate,
    [MaxLength(500)] string? Notes,
    bool IsRenewalEvent = false,
    DateTime? NextFollowUp = null // Appliqué au prospect (NextFollowUpDate)
);

public record PipelineEventResponse(
    Guid Id,
    Guid ProspectId,
    string EventType,
    DateTime EventDate,
    string? Notes,
    bool IsRenewalEvent,
    DateTime CreatedAt
);
