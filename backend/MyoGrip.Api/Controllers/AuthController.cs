using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Data;
using MyoGrip.Api.Dtos;
using MyoGrip.Api.Models;
using MyoGrip.Api.Services;

namespace MyoGrip.Api.Controllers;

[ApiController]
[Route("api/auth")]
[EnableRateLimiting("auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly TokenService _tokens;
    private readonly PasswordHasher<AppUser> _hasher = new();

    public AuthController(AppDbContext db, TokenService tokens)
    {
        _db = db;
        _tokens = tokens;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        var email = req.Email!.Trim().ToLowerInvariant();
        var code = req.ClinicCode!.Trim().ToUpperInvariant();

        var clinic = await _db.Clinics.FirstOrDefaultAsync(c => c.Code == code);
        if (clinic is null)
            return BadRequest(new ApiError("INVALID_CLINIC_CODE", "Clinic code not found."));

        if (await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict(new ApiError("EMAIL_EXISTS", "Email already registered."));

        var user = new AppUser
        {
            FullName = req.FullName!.Trim(),
            Age = req.Age!.Value,
            Email = email,
            ClinicId = clinic.Id,
        };
        user.PasswordHash = _hasher.HashPassword(user, req.Password!);

        _db.Users.Add(user);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {

            return Conflict(new ApiError("EMAIL_EXISTS", "Email already registered."));
        }

        return StatusCode(StatusCodes.Status201Created, new RegisterResponse(user.Id, user.Email));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req)
    {
        var email = req.Email!.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user is null ||
            _hasher.VerifyHashedPassword(user, user.PasswordHash, req.Password!) == PasswordVerificationResult.Failed)
        {
            return Unauthorized(new ApiError("INVALID_CREDENTIALS", "Wrong email or password."));
        }

        var token = _tokens.Create(user);
        return Ok(new LoginResponse(token, TokenService.LifetimeSeconds,
            new UserBrief(user.Id, user.FullName, user.Role)));
    }
}
