/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public class ListPopulateByAssignPerformanceScenario extends PerformanceScenario {

    public override void run() {
        List<Integer> values = new List<Integer>(size);

        for (Integer i = 0; i < size; i++) {
            values[i] = i;
        }
    }
}