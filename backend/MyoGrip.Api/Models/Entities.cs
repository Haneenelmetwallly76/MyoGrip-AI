namespace MyoGrip.Api.Models;

public class Clinic
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string ClinicianName { get; set; } = "";
}

public class AppUser
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string FullName { get; set; } = "";
    public int Age { get; set; }
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public string Role { get; set; } = "Patient";
    public int ClinicId { get; set; }
    public Clinic Clinic { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ProstheticSettings
{
    public int Id { get; set; }
    public Guid UserId { get; set; }
    public int Sensitivity { get; set; }
    public string ActiveGrips { get; set; } = "";
    public bool TensEnabled { get; set; }
    public bool Delivered { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class SyncBatch
{
    public int Id { get; set; }
    public Guid UserId { get; set; }
    public string BatchId { get; set; } = "";
    public int Accepted { get; set; }
    public int Rejected { get; set; }
    public DateTime ReceivedAt { get; set; } = DateTime.UtcNow;
    public List<LogEntry> Entries { get; set; } = new();
}

public class LogEntry
{
    public int Id { get; set; }
    public Guid UserId { get; set; }
    public int SyncBatchId { get; set; }
    public SyncBatch SyncBatch { get; set; } = null!;
    public DateTime Timestamp { get; set; }
    public string Type { get; set; } = "";
    public int? Gesture { get; set; }
    public double? GripStrength { get; set; }
    public int? DurationSeconds { get; set; }
    public string? Message { get; set; }
}

public class Report
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int ClinicId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime PeriodFrom { get; set; }
    public DateTime PeriodTo { get; set; }
    public double TotalUsageHours { get; set; }
    public double? AvgGripStrength { get; set; }
    public int DaysWithUsage { get; set; }
    public int ErrorCount { get; set; }
    public DateTime? ReadAt { get; set; }
}

public class AuditLog
{
    public int Id { get; set; }
    public Guid ClinicianId { get; set; }
    public Guid? PatientId { get; set; }
    public string Action { get; set; } = "";
    public DateTime At { get; set; } = DateTime.UtcNow;
}
