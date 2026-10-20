using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Data;
using MyoGrip.Api.Dtos;
using MyoGrip.Api.Models;
using MyoGrip.Api.Services;

namespace MyoGrip.Api.Controllers;

[ApiController]
[Route("api/prosthetic")]
[Authorize(Roles = "Patient")]
public class ProstheticController : ControllerBase
{
    private const int MaxEntries = 500;

    private readonly AppDbContext _db;

    public ProstheticController(AppDbContext db) => _db = db;

    [HttpGet("settings")]
    public async Task<IActionResult> GetSettings()
    {
        var uid = User.GetUserId();
        var s = await _db.Settings.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == uid);
        if (s is null)
            return NotFound(new ApiError("SETTINGS_NOT_FOUND", "No configuration yet."));
        return Ok(ToResponse(s));
    }

    [HttpPut("settings")]
    public async Task<IActionResult> UpdateSettings(SettingsRequest req)
    {
        var grips = req.ActiveGrips!;
        var errors = new Dictionary<string, string[]>();
        if (grips.Count == 0)
            errors["activeGrips"] = new[] { "At least one grip is required." };
        else if (grips.Any(g => g < 0 || g > 9))
            errors["activeGrips"] = new[] { "Each grip must be between 0 and 9." };
        else if (grips.Distinct().Count() != grips.Count)
            errors["activeGrips"] = new[] { "Grip values must be unique." };

        if (errors.Count > 0)
            return BadRequest(new ApiError("VALIDATION_ERROR", "One or more fields are invalid.", errors));

        var uid = User.GetUserId();
        var s = await _db.Settings.FirstOrDefaultAsync(x => x.UserId == uid);
        if (s is null)
        {
            s = new ProstheticSettings { UserId = uid };
            _db.Settings.Add(s);
        }

        s.Sensitivity = req.Sensitivity!.Value;
        s.ActiveGrips = string.Join(",", grips);
        s.TensEnabled = req.TensEnabled!.Value;
        s.Delivered = false;
        s.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {

            return Conflict(new ApiError("CONFLICT", "Settings were being updated at the same time. Please retry."));
        }
        return Ok(ToResponse(s));
    }

    [HttpPost("sync-logs")]
    public async Task<IActionResult> SyncLogs(SyncLogsRequest req)
    {
        var uid = User.GetUserId();
        var batchId = req.BatchId!.Trim();
        var entries = req.Entries!;

        if (entries.Count == 0)
            return BadRequest(new ApiError("VALIDATION_ERROR", "One or more fields are invalid.",
                new Dictionary<string, string[]> { ["entries"] = new[] { "At least one entry is required." } }));

        if (entries.Count > MaxEntries)
            return StatusCode(StatusCodes.Status413PayloadTooLarge,
                new ApiError("BATCH_TOO_LARGE", $"A batch can contain at most {MaxEntries} entries."));

        var existing = await _db.SyncBatches.AsNoTracking()
            .FirstOrDefaultAsync(b => b.UserId == uid && b.BatchId == batchId);
        if (existing is not null)
            return Ok(new SyncLogsResponse(existing.Accepted, existing.Rejected, new List<RejectedItem>()));

        var rejected = new List<RejectedItem>();
        var batch = new SyncBatch { UserId = uid, BatchId = batchId };

        for (var i = 0; i < entries.Count; i++)
        {
            var e = entries[i];
            var reason = Validate(e);
            if (reason is not null)
            {
                rejected.Add(new RejectedItem(i, reason));
                continue;
            }
            var isUsage = e!.Type == "usage";
            batch.Entries.Add(new LogEntry
            {
                UserId = uid,
                Timestamp = e.Timestamp!.Value.UtcDateTime,
                Type = e.Type!,
                Gesture = isUsage ? e.Gesture : null,
                GripStrength = isUsage ? e.GripStrength : null,
                DurationSeconds = isUsage ? e.DurationSeconds : null,
                Message = isUsage ? null : e.Message!.Trim(),
            });
        }

        batch.Accepted = batch.Entries.Count;
        batch.Rejected = rejected.Count;

        if (batch.Accepted == 0)
        {
            return BadRequest(new
            {
                code = "VALIDATION_ERROR",
                message = "No valid entries in this batch.",
                accepted = 0,
                rejected = rejected.Count,
                rejectedItems = rejected
            });
        }

        _db.SyncBatches.Add(batch);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {

            var again = await _db.SyncBatches.AsNoTracking()
                .FirstOrDefaultAsync(b => b.UserId == uid && b.BatchId == batchId);
            if (again is null) throw;
            return Ok(new SyncLogsResponse(again.Accepted, again.Rejected, new List<RejectedItem>()));
        }

        return Ok(new SyncLogsResponse(batch.Accepted, batch.Rejected, rejected));
    }

    private static string? Validate(SyncEntryDto? e)
    {
        if (e is null) return "Entry is empty.";
        if (e.Timestamp is null) return "timestamp is required.";

        if (e.Type == "usage")
        {
            if (e.Gesture is null or < 0 or > 9) return "gesture must be an integer from 0 to 9.";
            if (e.GripStrength is null or < 0 or > 1) return "gripStrength must be between 0 and 1.";
            if (e.DurationSeconds is null or < 0) return "durationSeconds must be 0 or more.";
            return null;
        }
        if (e.Type == "error")
        {
            if (string.IsNullOrWhiteSpace(e.Message)) return "message is required for error entries.";
            if (e.Message.Length > 500) return "message is longer than 500 characters.";
            return null;
        }
        return "type must be \"usage\" or \"error\".";
    }

    private static SettingsResponse ToResponse(ProstheticSettings s) => new(
        s.Sensitivity,
        s.ActiveGrips.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(x => int.Parse(x)).ToArray(),
        s.TensEnabled,
        s.Delivered ? "applied" : "pending",
        DateTime.SpecifyKind(s.UpdatedAt, DateTimeKind.Utc));
}
