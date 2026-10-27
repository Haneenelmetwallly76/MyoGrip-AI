using System.Globalization;
using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Data;
using MyoGrip.Api.Dtos;

namespace MyoGrip.Api.Services;

public class UsageService
{
    public const int MaxRangeDays = 366;

    private readonly AppDbContext _db;

    public UsageService(AppDbContext db) => _db = db;

    private record Row(DateTime Timestamp, string Type, double? GripStrength, int? DurationSeconds);

    public static (DateTime From, DateTime To) DefaultRange()
    {
        var to = DateTime.UtcNow.Date;
        return (to.AddDays(-29), to);
    }

    public static bool TryResolveRange(DateTime? from, DateTime? to, out DateTime start, out DateTime end, out string error)
    {
        end = (to ?? DateTime.UtcNow).Date;
        start = (from ?? end.AddDays(-29)).Date;
        error = "";
        if (start > end)
        {
            error = "from must be on or before to.";
            return false;
        }
        if ((end - start).TotalDays >= MaxRangeDays)
        {
            error = $"The range can be at most {MaxRangeDays} days.";
            return false;
        }
        return true;
    }

    public async Task<UsageResponse> BuildAsync(Guid userId, DateTime from, DateTime to, CancellationToken ct = default)
    {
        var start = from.Date;
        var endExclusive = to.Date.AddDays(1);

        var rows = await _db.LogEntries.AsNoTracking()
            .Where(e => e.UserId == userId && e.Timestamp >= start && e.Timestamp < endExclusive)
            .Select(e => new Row(e.Timestamp, e.Type, e.GripStrength, e.DurationSeconds))
            .ToListAsync(ct);

        var byDay = rows.GroupBy(r => r.Timestamp.Date).ToDictionary(g => g.Key, g => g.ToList());

        var days = new List<UsageDay>();
        for (var day = start; day < endExclusive; day = day.AddDays(1))
        {
            var list = byDay.TryGetValue(day, out var found) ? found : new List<Row>();
            var usage = list.Where(r => r.Type == "usage").ToList();

            var seconds = usage.Sum(r => r.DurationSeconds ?? 0);
            double? grip = null;
            if (seconds > 0)
                grip = usage.Sum(r => (r.GripStrength ?? 0) * (r.DurationSeconds ?? 0)) / seconds;
            else if (usage.Count > 0)
                grip = usage.Average(r => r.GripStrength ?? 0);

            days.Add(new UsageDay(
                day.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                Math.Round(seconds / 3600.0, 3),
                grip.HasValue ? Math.Round(grip.Value, 4) : null,
                list.Count(r => r.Type == "error")));
        }

        var lastSynced = await _db.SyncBatches.AsNoTracking()
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.ReceivedAt)
            .Select(b => (DateTime?)b.ReceivedAt)
            .FirstOrDefaultAsync(ct);

        return new UsageResponse(
            start.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            to.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            days,
            lastSynced.HasValue ? DateTime.SpecifyKind(lastSynced.Value, DateTimeKind.Utc) : null);
    }
}
