using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Data;
using MyoGrip.Api.Dtos;
using MyoGrip.Api.Models;
using MyoGrip.Api.Services;

namespace MyoGrip.Api.Controllers;

[ApiController]
[Route("api/clinic")]
[Authorize(Roles = "Clinician")]
public class ClinicController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly UsageService _usage;

    public ClinicController(AppDbContext db, UsageService usage)
    {
        _db = db;
        _usage = usage;
    }

    [HttpGet("patients")]
    public async Task<IActionResult> ListPatients([FromQuery] string? search, CancellationToken ct)
    {
        var clinician = await CurrentClinician(ct);
        if (clinician is null) return Unauthorized(UnauthorizedError());

        var query = _db.Users.AsNoTracking()
            .Where(u => u.Role == "Patient" && u.ClinicId == clinician.ClinicId);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u => u.FullName.ToLower().Contains(term) || u.Email.Contains(term));
        }

        var patients = await query.OrderBy(u => u.FullName).Take(200).ToListAsync(ct);
        var ids = patients.Select(p => p.Id).ToList();

        var batches = await _db.SyncBatches.AsNoTracking()
            .Where(b => ids.Contains(b.UserId))
            .Select(b => new { b.UserId, b.ReceivedAt })
            .ToListAsync(ct);
        var lastSync = batches
            .GroupBy(b => b.UserId)
            .ToDictionary(g => g.Key, g => g.Max(b => b.ReceivedAt));

        await Audit(clinician, null, "list_patients", ct);

        var items = patients.Select(p => new PatientListItem(
            p.Id, p.FullName, p.Age, p.Email,
            lastSync.TryGetValue(p.Id, out var last) ? DateTime.SpecifyKind(last, DateTimeKind.Utc) : null)).ToList();
        return Ok(new PatientListResponse(items));
    }

    [HttpGet("patients/{id:guid}")]
    public async Task<IActionResult> GetPatient(Guid id, CancellationToken ct)
    {
        var clinician = await CurrentClinician(ct);
        if (clinician is null) return Unauthorized(UnauthorizedError());

        var patient = await FindPatient(clinician, id, ct);
        if (patient is null) return NotFound(PatientNotFound());

        var settings = await _db.Settings.AsNoTracking().FirstOrDefaultAsync(s => s.UserId == patient.Id, ct);
        await Audit(clinician, patient.Id, "view_patient", ct);

        var profile = new ProfileResponse(
            patient.Id, patient.FullName, patient.Age, patient.Email,
            patient.Clinic.Code, new ClinicianDto(patient.Clinic.ClinicianName));
        return Ok(new ClinicPatientDetail(profile, settings is null ? null : ToSettings(settings)));
    }

    [HttpGet("patients/{id:guid}/usage")]
    public async Task<IActionResult> GetUsage(Guid id, [FromQuery] DateTime? from, [FromQuery] DateTime? to, CancellationToken ct)
    {
        var clinician = await CurrentClinician(ct);
        if (clinician is null) return Unauthorized(UnauthorizedError());

        var patient = await FindPatient(clinician, id, ct);
        if (patient is null) return NotFound(PatientNotFound());

        if (!UsageService.TryResolveRange(from, to, out var start, out var end, out var error))
            return BadRequest(new ApiError("VALIDATION_ERROR", error,
                new Dictionary<string, string[]> { ["range"] = new[] { error } }));

        await Audit(clinician, patient.Id, "view_usage", ct);
        return Ok(await _usage.BuildAsync(patient.Id, start, end, ct));
    }

    [HttpGet("patients/{id:guid}/errors")]
    public async Task<IActionResult> GetErrors(Guid id, [FromQuery] int limit = 50, CancellationToken ct = default)
    {
        var clinician = await CurrentClinician(ct);
        if (clinician is null) return Unauthorized(UnauthorizedError());

        var patient = await FindPatient(clinician, id, ct);
        if (patient is null) return NotFound(PatientNotFound());

        var take = Math.Clamp(limit, 1, 200);
        var rows = await _db.LogEntries.AsNoTracking()
            .Where(e => e.UserId == patient.Id && e.Type == "error")
            .OrderByDescending(e => e.Timestamp)
            .Take(take)
            .ToListAsync(ct);

        await Audit(clinician, patient.Id, "view_errors", ct);
        var items = rows
            .Select(e => new ErrorLogItem(DateTime.SpecifyKind(e.Timestamp, DateTimeKind.Utc), e.Message ?? ""))
            .ToList();
        return Ok(new ErrorLogResponse(items));
    }

    [HttpGet("reports")]
    public async Task<IActionResult> ListReports(CancellationToken ct)
    {
        var clinician = await CurrentClinician(ct);
        if (clinician is null) return Unauthorized(UnauthorizedError());

        var reports = await _db.Reports.AsNoTracking()
            .Where(r => r.ClinicId == clinician.ClinicId)
            .OrderByDescending(r => r.CreatedAt)
            .Take(100)
            .ToListAsync(ct);

        var userIds = reports.Select(r => r.UserId).Distinct().ToList();
        var names = await _db.Users.AsNoTracking()
            .Where(u => userIds.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.FullName, ct);

        await Audit(clinician, null, "list_reports", ct);
        var items = reports
            .Select(r => new ReportListItem(
                r.Id, r.UserId, names.TryGetValue(r.UserId, out var name) ? name : "",
                DateTime.SpecifyKind(r.CreatedAt, DateTimeKind.Utc),
                r.PeriodFrom.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                r.PeriodTo.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                r.TotalUsageHours, r.AvgGripStrength, r.DaysWithUsage, r.ErrorCount, r.ReadAt != null))
            .ToList();
        return Ok(new ReportListResponse(items));
    }

    [HttpPost("reports/{id:guid}/read")]
    public async Task<IActionResult> MarkReportRead(Guid id, CancellationToken ct)
    {
        var clinician = await CurrentClinician(ct);
        if (clinician is null) return Unauthorized(UnauthorizedError());

        var report = await _db.Reports.FirstOrDefaultAsync(r => r.Id == id && r.ClinicId == clinician.ClinicId, ct);
        if (report is null)
            return NotFound(new ApiError("REPORT_NOT_FOUND", "Report not found."));

        report.ReadAt ??= DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        await Audit(clinician, report.UserId, "read_report", ct);
        return Ok(new { reportId = report.Id, read = true });
    }

    private async Task<AppUser?> CurrentClinician(CancellationToken ct)
    {
        var id = User.GetUserId();
        return await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == id && u.Role == "Clinician", ct);
    }

    private Task<AppUser?> FindPatient(AppUser clinician, Guid patientId, CancellationToken ct) =>
        _db.Users.Include(u => u.Clinic)
            .FirstOrDefaultAsync(u => u.Id == patientId && u.Role == "Patient" && u.ClinicId == clinician.ClinicId, ct);

    private async Task Audit(AppUser clinician, Guid? patientId, string action, CancellationToken ct)
    {
        _db.AuditLogs.Add(new AuditLog { ClinicianId = clinician.Id, PatientId = patientId, Action = action });
        await _db.SaveChangesAsync(ct);
    }

    private static ApiError UnauthorizedError() => new("UNAUTHORIZED", "Account no longer exists.");

    private static ApiError PatientNotFound() => new("PATIENT_NOT_FOUND", "Patient not found.");

    private static SettingsResponse ToSettings(ProstheticSettings s) => new(
        s.Sensitivity,
        s.ActiveGrips.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(x => int.Parse(x)).ToArray(),
        s.TensEnabled,
        s.Delivered ? "applied" : "pending",
        DateTime.SpecifyKind(s.UpdatedAt, DateTimeKind.Utc));
}
