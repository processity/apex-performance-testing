/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public class ListPopulateByAssignPerformanceScenario implements PerformanceScenario {

    private Integer size;

    public void setup(Integer size) {
        this.size = size;
    }

    public void run() {
        List<Integer> values = new List<Integer>(size);

        for (Integer i = 0; i < size; i++) {
            values[i] = i;
        }
    }

    //PMD false positive, no teardown required
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void teardown() {
    }

    public String getLabel() {
        return 'ListPopulateByAssignPerformanceScenario';
    }
}