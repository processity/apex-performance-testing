/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public class ListPopulateByAddPerformanceScenario extends PerformanceScenario {

    public override void run() {
        List<Integer> values = new List<Integer>();

        for (Integer i = 0; i < size; i++) {
            values.add(i);
        }
    }
}