using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using SalesFlow.Application.Reminders.DTOs;
using SalesFlow.Application.Reminders.Services;
using SalesFlow.Domain.Common;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/reminders")]
[Tags("Reminders")]
public class RemindersController : ControllerBase
{
    private readonly IReminderService _service;

    public RemindersController(IReminderService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ReminderListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ReminderListResponse>> List([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] bool unreadOnly = false, CancellationToken ct = default)
    {
        var result = await _service.ListAsync(page, pageSize, unreadOnly, ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ReminderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ReminderDto>> GetById(string id, CancellationToken ct = default)
    {
        var result = await _service.GetByIdAsync(id, ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }

    [HttpPatch("{id}/read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> MarkAsRead(string id, [FromBody] MarkReminderReadRequest request, CancellationToken ct = default)
    {
        var result = await _service.MarkAsReadAsync(id, ct);
        return result.IsSuccess ? NoContent() : BadRequest(result.Error);
    }

    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(string id, CancellationToken ct = default)
    {
        var result = await _service.DeleteAsync(id, ct);
        return result.IsSuccess ? NoContent() : BadRequest(result.Error);
    }
}
