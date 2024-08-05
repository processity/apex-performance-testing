/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public class IntegerStoredSizeLoopPerformanceScenario extends LoopPerformanceScenario {
    public void run() {
        Integer sum = 0;
        for(Integer i=0, size=data.size(); i < size; i++) {
            sum += data[i];
        }
    }
}