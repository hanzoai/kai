// One Kai decision through the Hanzo C# SDK (NuGet `Hanzo`): the strongest
// opening move in tic-tac-toe, as a choice over the nine squares.
using Hanzo.AI;
using Hanzo.AI.Api;
using Hanzo.AI.Client;
using Hanzo.AI.Model;

var squares = new Dictionary<string, string>
{
    ["r1c1"] = "top-left", ["r1c2"] = "top-center", ["r1c3"] = "top-right",
    ["r2c1"] = "middle-left", ["r2c2"] = "center", ["r2c3"] = "middle-right",
    ["r3c1"] = "bottom-left", ["r3c2"] = "bottom-center", ["r3c3"] = "bottom-right",
};

// HANZO_API_KEY, HANZO_BASE_URL and HANZO_ORG_ID, read once.
var ai = new AiApi(Gateway.Configuration());

try
{
    var decision = ai.PostDecisions(new AiDecisionsRequest(
        model: Environment.GetEnvironmentVariable("KAI_MODEL") ?? "kai", // or "typesafe/jev-1.13"
        state: new
        {
            game = "tic-tac-toe",
            board = new[] { new[] { "", "", "" }, new[] { "", "", "" }, new[] { "", "", "" } },
            player = "X",
        },
        questions: new Dictionary<string, AiDecisionsQuestion>
        {
            ["move"] = new AiDecisionsQuestion(new AiDecisionsChoice(
                type: AiDecisionsChoice.TypeEnum.Choice,
                instructions: "Choose the strongest legal next move.",
                criteria: squares)),
        }));

    var move = decision.Answers["move"];
    if (move.Choice is null || !squares.ContainsKey(move.Choice))
    {
        Console.Error.WriteLine($"Kai returned an illegal move: {move.Choice ?? "<missing>"}");
        return 1;
    }

    Console.WriteLine($"model: {decision.Model}");
    Console.WriteLine($"id: {decision.Id}");
    Console.WriteLine($"latency_ms: {decision.LatencyMs}");
    Console.WriteLine($"move: {move.Choice} ({squares[move.Choice]})");
    Console.WriteLine($"confidence: {move.Confidence:F4}");
    foreach (var (square, p) in move.Probabilities.OrderByDescending(kv => kv.Value))
    {
        Console.WriteLine($"  {square}: {p * 100:F2}%");
    }
    return 0;
}
catch (ApiException e)
{
    Console.Error.WriteLine($"Kai refused: HTTP {e.ErrorCode} {e.ErrorContent}");
    return 1;
}
