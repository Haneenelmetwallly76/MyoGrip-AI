using System.Net.Http.Json;
using MyoGrip.Api.Dtos;

namespace MyoGrip.Api.Services;

public class AiClient
{

    public const int WindowSize = 200;
    public const int Channels = 8;

    private readonly HttpClient _http;
    private readonly string? _serviceKey;

    public AiClient(HttpClient http, IConfiguration config)
    {
        _http = http;
        _serviceKey = config["AiService:ServiceKey"];
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_serviceKey);

    public async Task<AiPrediction> PredictAsync(List<List<double>> window, Guid userId, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "predict")
        {
            Content = JsonContent.Create(new { window })
        };
        request.Headers.Add("X-Service-Key", _serviceKey);
        request.Headers.Add("X-User-Id", userId.ToString());

        using var response = await _http.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadFromJsonAsync<AiPrediction>(cancellationToken: ct);
        return result ?? throw new HttpRequestException("Empty response from AI service.");
    }
}
