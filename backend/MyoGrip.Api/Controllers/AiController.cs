using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyoGrip.Api.Dtos;
using MyoGrip.Api.Services;

namespace MyoGrip.Api.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize(Roles = "Patient")]
public class AiController : ControllerBase
{
    private readonly AiClient _ai;
    private readonly ILogger<AiController> _logger;

    public AiController(AiClient ai, ILogger<AiController> logger)
    {
        _ai = ai;
        _logger = logger;
    }

    [HttpPost("predict")]
    public async Task<IActionResult> Predict(PredictRequest req, CancellationToken ct)
    {
        var window = req.Window!;
        if (window.Count != AiClient.WindowSize || window.Any(r => r is null || r.Count != AiClient.Channels))
        {
            return BadRequest(new ApiError("VALIDATION_ERROR", "One or more fields are invalid.",
                new Dictionary<string, string[]>
                {
                    ["window"] = new[] { $"Must be {AiClient.WindowSize} rows x {AiClient.Channels} columns." }
                }));
        }

        if (!_ai.IsConfigured)
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new ApiError("AI_NOT_CONFIGURED", "AiService:ServiceKey is not set on the API."));

        try
        {
            var result = await _ai.PredictAsync(window, User.GetUserId(), ct);
            return Ok(result);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "AI service call failed");
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new ApiError("AI_UNAVAILABLE", "The AI service is unreachable or returned an error."));
        }
        catch (TaskCanceledException ex) when (!ct.IsCancellationRequested)
        {
            _logger.LogWarning(ex, "AI service call timed out");
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new ApiError("AI_UNAVAILABLE", "The AI service timed out."));
        }
    }
}
