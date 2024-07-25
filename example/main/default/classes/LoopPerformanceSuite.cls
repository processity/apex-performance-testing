/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public with sharing class LoopPerformanceSuite {

    public static void run() {
        new PerformanceSuite('LoopPerformance', new List<PerformanceScenario>{
                new IntegerLoopPerformanceScenario(),
                new IteratorLoopPerformanceScenario(),
                new IntegerStoredSizeLoopPerformanceScenario()
        })
                .setStartSize(1000)
                .setStepSize(1000)
                .setEndSize(10000)
                .setRepetitions(20)
                .run();
    }
}