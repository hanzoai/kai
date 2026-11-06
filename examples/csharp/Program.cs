using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

public static class Program
{
    public static async Task<int> Main(string[] args)
    {
        try
        {
            string apiKey = Environment.GetEnvironmentVariable("HANZO_API_KEY")
                ?? throw new InvalidOperationException("HANZO_API_KEY is required");
            string model = Environment.GetEnvironmentVariable("KAI_MODEL") ?? "kai";
            string baseUrl = (Environment.GetEnvironmentVariable("HANZO_BASE_URL") ?? "https://api.hanzo.ai").TrimEnd('/');
            Uri endpoint = new Uri($"{baseUrl}/v1/decisions");

            string[] legalMoves =
            {
                "r1c1", "r1c2", "r1c3",
                "r2c1", "r2c2", "r2c3",
                "r3c1", "r3c2", "r3c3",
            };

            var request = new
            {
                model,
                state = new
                {
                    game = "tic-tac-toe",
                    board = new[]
                    {
                        new[] { "", "", "" },
                        new[] { "", "", "" },
                        new[] { "", "", "" },
                    },
                    player = "X",
                },
                questions = new Dictionary<string, object>
                {
                    ["move"] = new
                    {
                        type = "choice",
                        instructions = "Choose the strongest legal next move.",
                        criteria = new Dictionary<string, string>
                        {
                            ["r1c1"] = "top-left",
                            ["r1c2"] = "top-center",
                            ["r1c3"] = "top-right",
                            ["r2c1"] = "middle-left",
                            ["r2c2"] = "center",
                            ["r2c3"] = "middle-right",
                            ["r3c1"] = "bottom-left",
                            ["r3c2"] = "bottom-center",
                            ["r3c3"] = "bottom-right",
                        },
                    },
                },
            };

            string json = JsonSerializer.Serialize(request);
            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            using var content = new StringContent(json, Encoding.UTF8, "application/json");
            using var response = await client.PostAsync(endpoint, content);
            string body = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException($"Kai returned {(int)response.StatusCode}: {body}");
            }

            JsonNode root = JsonNode.Parse(body) ?? throw new InvalidOperationException("Kai returned an empty response");
            string? id = root["id"]?.GetValue<string>();
            string? answerModel = root["model"]?.GetValue<string>();
            double latency = root["latency_ms"]?.GetValue<double>() ?? 0;
            JsonObject? answers = root["answers"]?.AsObject();
            JsonObject? move = answers?["move"]?.AsObject();
            string? choice = move?["choice"]?.GetValue<string>();
            double confidence = move?["confidence"]?.GetValue<double>() ?? 0;
            JsonObject? probabilities = move?["probabilities"]?.AsObject();

            if (string.IsNullOrWhiteSpace(choice) || !legalMoves.Contains(choice))
            {
                throw new InvalidOperationException($"Kai returned an illegal move: {choice ?? "<missing>"}");
            }

            Console.WriteLine($"model: {answerModel}");
            Console.WriteLine($"id: {id}");
            Console.WriteLine($"latency_ms: {latency}");
            Console.WriteLine($"move: {choice}");
            Console.WriteLine($"confidence: {confidence}");
            Console.WriteLine($"probabilities: {probabilities?.ToJsonString() ?? "{}"}");
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }
}
