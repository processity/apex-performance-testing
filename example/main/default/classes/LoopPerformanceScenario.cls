/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public abstract class LoopPerformanceScenario implements PerformanceScenario {

    protected List<Integer> data;

    public void setup(Integer size) {
        data = new List<Integer>(size);

        for (Integer i = 0; i < size; i++) {
            data[i] = i;
        }
    }

    //PMD false positive, no teardown required
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void teardown() {
    }

    public String getLabel() {
        return 'LoopPerformanceScenario';
    }
}