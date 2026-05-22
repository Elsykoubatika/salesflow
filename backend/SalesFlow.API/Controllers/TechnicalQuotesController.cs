using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Technical.DTOs;
using SalesFlow.Application.Technical.Services;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical/quotes")]
[Authorize]
[Tags("Technical Quotes")]
public class TechnicalQuotesController : ControllerBase
{
    private readonly ITechnicalQuoteService _service;

    public TechnicalQuotesController(ITechnicalQuoteService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null,
        CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, status, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct = default)
    {
        var result = await _service.GetByIdAsync(id, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(new { error = result.Error });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTechnicalQuoteRequest request, CancellationToken ct = default)
    {
        var result = await _service.CreateAsync(request, ct);
        if (!result.IsSuccess) return BadRequest(new { error = result.Error });
        return CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value);
    }

    [HttpPost("{id:guid}/items")]
    public async Task<IActionResult> AddItem(Guid id, [FromBody] CreateTechnicalQuoteItemRequest request, CancellationToken ct = default)
    {
        //var itemRequest = request with { QuoteId = id };
        var result = await _service.AddItemAsync(id, request, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(new { error = result.Error });
    }

    [HttpPatch("{id:guid}/send")]
    public async Task<IActionResult> Send(Guid id, CancellationToken ct = default)
    {
        var result = await _service.SendAsync(id, ct);
        if (!result.IsSuccess)
            return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
        return Ok(result.Value);
    }

    [HttpPatch("{id:guid}/accept")]
    public async Task<IActionResult> Accept(Guid id, CancellationToken ct = default)
    {
        var result = await _service.AcceptAsync(id, ct);
        if (!result.IsSuccess)
            return result.Error!.Contains("introuvable") ? NotFound(new { error = result.Error }) : BadRequest(new { error = result.Error });
        return Ok(result.Value);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct = default)
    {
        var result = await _service.DeleteAsync(id, ct);
        return result.IsSuccess ? NoContent() : NotFound(new { error = result.Error });
    }
}