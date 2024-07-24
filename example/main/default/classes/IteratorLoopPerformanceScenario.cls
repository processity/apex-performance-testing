/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public class IteratorLoopPerformanceScenario extends LoopPerformanceScenario {
    
    public void run() {
        Integer sum = 0;
        for(Integer i : data) {
            sum += i;
        }
    }
}