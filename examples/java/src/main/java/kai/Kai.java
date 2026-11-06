package kai;

import ai.hanzo.Hanzo;
import ai.hanzo.cloud.ApiException;
import ai.hanzo.cloud.api.AiApi;
import ai.hanzo.cloud.model.AiDecisionsAnswer;
import ai.hanzo.cloud.model.AiDecisionsChoice;
import ai.hanzo.cloud.model.AiDecisionsQuestion;
import ai.hanzo.cloud.model.AiDecisionsRequest;
import ai.hanzo.cloud.model.AiDecisionsResponse;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One Kai decision: the strongest opening move in tic-tac-toe, as a choice over the nine squares. */
public final class Kai {

    public static void main(String[] args) {
        Map<String, String> squares = new LinkedHashMap<>();
        squares.put("r1c1", "top-left");
        squares.put("r1c2", "top-center");
        squares.put("r1c3", "top-right");
        squares.put("r2c1", "middle-left");
        squares.put("r2c2", "center");
        squares.put("r2c3", "middle-right");
        squares.put("r3c1", "bottom-left");
        squares.put("r3c2", "bottom-center");
        squares.put("r3c3", "bottom-right");

        String model = System.getenv().getOrDefault("KAI_MODEL", "kai"); // or "typesafe/jev-1.13"
        List<String> empty = List.of("", "", "");

        // HANZO_API_KEY, HANZO_BASE_URL and HANZO_ORG_ID, read once.
        AiApi ai = new AiApi(Hanzo.client());
        try {
            AiDecisionsResponse decision = ai.postDecisions(new AiDecisionsRequest()
                    .model(model)
                    .state(Map.of("game", "tic-tac-toe", "board", List.of(empty, empty, empty), "player", "X"))
                    .putQuestionsItem("move", new AiDecisionsQuestion(new AiDecisionsChoice()
                            .type(AiDecisionsChoice.TypeEnum.CHOICE)
                            .instructions("Choose the strongest legal next move.")
                            .criteria(squares))));

            AiDecisionsAnswer move = decision.getAnswers().get("move");
            if (move == null || move.getChoice() == null || !squares.containsKey(move.getChoice())) {
                System.err.printf("Kai returned an illegal move: %s%n", move == null ? "<missing>" : move.getChoice());
                System.exit(1);
            }

            System.out.printf("model: %s%n", decision.getModel());
            System.out.printf("id: %s%n", decision.getId());
            System.out.printf("latency_ms: %s%n", decision.getLatencyMs());
            System.out.printf("move: %s (%s)%n", move.getChoice(), squares.get(move.getChoice()));
            System.out.printf("confidence: %.4f%n", move.getConfidence());
            move.getProbabilities().entrySet().stream()
                    .sorted(Map.Entry.<String, BigDecimal>comparingByValue().reversed())
                    .forEach(e -> System.out.printf("  %s: %.2f%%%n", e.getKey(), e.getValue().doubleValue() * 100));
        } catch (ApiException e) {
            System.err.printf("Kai refused: HTTP %d %s%n", e.getCode(), e.getResponseBody());
            System.exit(1);
        }
    }
}
