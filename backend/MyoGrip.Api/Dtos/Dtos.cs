using System.ComponentModel.DataAnnotations;

namespace MyoGrip.Api.Dtos;

public record ApiError(string Code, string Message, Dictionary<string, string[]>? Errors = null);

public class RegisterRequest
{
    [Required, MaxLength(100)] public string? FullName { get; set; }
    [Required, Range(1, 120)] public int? Age { get; set; }
    [Required, EmailAddress] public string? Email { get; set; }
    [Required, MinLength(8)] public string? Password { get; set; }
    [Required] public string? ClinicCode { get; set; }
}
public record RegisterResponse(Guid UserId, string Email);

public class LoginRequest
{
    [Required] public string? Email { get; set; }
    [Required] public string? Password { get; set; }
}
public record UserBrief(Guid UserId, string FullName, string Role);
public record LoginResponse(string AccessToken, int ExpiresIn, UserBrief User);

public class UpdateProfileRequest
{
    [Required, MaxLength(100)] public string? FullName { get; set; }
    [Required, Range(1, 120)] public int? Age { get; set; }
    [Required, EmailAddress] public string? Email { get; set; }
}
public record ClinicianDto(string Name);
public record ProfileResponse(Guid UserId, string FullName, int Age, string Email, string ClinicCode, ClinicianDto Clinician);

public class SettingsRequest
{
    [Required, Range(0, 100)] public int? Sensitivity { get; set; }
    [Required] public List<int>? ActiveGrips { get; set; }
    [Required] public bool? TensEnabled { get; set; }
}
public record SettingsResponse(int Sensitivity, int[] ActiveGrips, bool TensEnabled, string DeliveryStatus, DateTime UpdatedAt);

public class SyncLogsRequest
{
    [Required, MaxLength(100)] public string? BatchId { get; set; }
    [Required] public List<SyncEntryDto>? Entries { get; set; }
}
public class SyncEntryDto
{
    public DateTimeOffset? Timestamp { get; set; }
    public string? Type { get; set; }
    public int? Gesture { get; set; }
    public double? GripStrength { get; set; }
    public int? DurationSeconds { get; set; }
    public string? Message { get; set; }
}
public record RejectedItem(int Index, string Reason);
public record SyncLogsResponse(int Accepted, int Rejected, List<RejectedItem> RejectedItems);

public class PredictRequest
{
    [Required] public List<List<double>>? Window { get; set; }
}
public record AiPrediction(
    int Gesture, double Force, double Uncertainty, bool RejectedBySafety,
    double StiffnessIndex, int StiffnessFlag, int HapticSpike);
