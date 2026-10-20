using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Data;
using MyoGrip.Api.Dtos;
using MyoGrip.Api.Models;
using MyoGrip.Api.Services;

namespace MyoGrip.Api.Controllers;

[ApiController]
[Route("api/user")]
[Authorize(Roles = "Patient")]
public class UserController : ControllerBase
{
    private readonly AppDbContext _db;

    public UserController(AppDbContext db) => _db = db;

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var user = await LoadCurrentUser();
        if (user is null) return Unauthorized(new ApiError("UNAUTHORIZED", "Account no longer exists."));
        return Ok(ToProfile(user));
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile(UpdateProfileRequest req)
    {
        var user = await LoadCurrentUser();
        if (user is null) return Unauthorized(new ApiError("UNAUTHORIZED", "Account no longer exists."));

        var email = req.Email!.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email == email && u.Id != user.Id))
            return Conflict(new ApiError("EMAIL_EXISTS", "Email already in use."));

        user.FullName = req.FullName!.Trim();
        user.Age = req.Age!.Value;
        user.Email = email;

        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Conflict(new ApiError("EMAIL_EXISTS", "Email already in use."));
        }
        return Ok(ToProfile(user));
    }

    private Task<AppUser?> LoadCurrentUser()
    {
        var id = User.GetUserId();
        return _db.Users.Include(u => u.Clinic).FirstOrDefaultAsync(u => u.Id == id);
    }

    private static ProfileResponse ToProfile(AppUser u) =>
        new(u.Id, u.FullName, u.Age, u.Email, u.Clinic.Code, new ClinicianDto(u.Clinic.ClinicianName));
}
