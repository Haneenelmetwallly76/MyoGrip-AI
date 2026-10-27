using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Data;
using MyoGrip.Api.Dtos;
using MyoGrip.Api.Models;
using MyoGrip.Api.Services;

namespace MyoGrip.Api.Controllers;

[ApiController]
[Route("api/reports")]
[Authorize(Roles = "Patient")]
public class ReportsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly UsageService _usage;

    public ReportsController(AppDbContext db, UsageService usage)
    {
        _db = db;
        _usage = usage;
    }

    [HttpPost("send")]
    public async Task<IActionResult> Send(CancellationToken ct)
    {
        var uid = User.GetUserId();
        var user = await _db.Users.Include(u => u.Clinic).FirstOrDefaultAsync(u => u.Id == uid, ct);
        if (user is null)
            return Unauthorized(new ApiError("UNAUTHORIZED", "Account no longer exists."));

        var (from, to) = UsageService.DefaultRange();
        var usage = await _usage.BuildAsync(uid, from, to, ct);

        var daysWithUsage = usage.Days.Where(d => d.UsageHours > 0).ToList();
        var errors = usage.Days.Sum(d => d.ErrorCount);
        if (daysWithUsage.Count == 0 && errors == 0)
            return BadRequest(new ApiError("NO_USAGE_DATA", "There is no usage or error data to report yet."));

        var totalHours = daysWithUsage.Sum(d => d.UsageHours);
        var gripDays = daysWithUsage.Where(d => d.AvgGripStrength.HasValue).ToList();
        double? avgGrip = gripDays.Count > 0 && totalHours > 0
            ? gripDays.Sum(d => d.AvgGripStrength!.Value * d.UsageHours) / gripDays.Sum(d => d.UsageHours)
            : null;

        var report = new Report
        {
            UserId = uid,
            ClinicId = user.ClinicId,
            PeriodFrom = from,
            PeriodTo = to,
            TotalUsageHours = Math.Round(totalHours, 3),
            AvgGripStrength = avgGrip.HasValue ? Math.Round(avgGrip.Value, 4) : null,
            DaysWithUsage = daysWithUsage.Count,
            ErrorCount = errors,
        };
        _db.Reports.Add(report);
        await _db.SaveChangesAsync(ct);

        return StatusCode(StatusCodes.Status201Created,
            new ReportCreatedResponse(report.Id, report.CreatedAt, user.Clinic.ClinicianName));
    }
}
