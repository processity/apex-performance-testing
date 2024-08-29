/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public abstract class LoopPerformanceScenario extends PerformanceScenario {

    protected List<Integer> data;

    public override void setup(Integer size) {
        data = new List<Integer>(size);

        for (Integer i = 0; i < size; i++) {
            data[i] = i;
        }
    }
}