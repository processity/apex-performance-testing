/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public class IntegerLoopPerformanceScenario extends LoopPerformanceScenario {

    public void run() {
        Integer sum = 0;
        for(Integer i=0; i < data.size(); i++) {
            sum += data[i];
        }
    }
}