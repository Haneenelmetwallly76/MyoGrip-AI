using System.Security.Claims;

namespace MyoGrip.Api.Services;

public static class ClaimsExtensions
{

    public static Guid GetUserId(this ClaimsPrincipal principal) =>
        Guid.TryParse(principal.FindFirst("sub")?.Value, out var id) ? id : Guid.Empty;
}
