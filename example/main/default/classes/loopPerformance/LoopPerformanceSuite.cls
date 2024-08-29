/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

public with sharing class LoopPerformanceSuite implements PerformanceSuiteRunner {

    public static PerformanceSuite.Response run() {
        return new PerformanceSuite('LoopPerformance', new List<PerformanceScenario>{
                        new IntegerLoopPerformanceScenario(),
                        new IteratorLoopPerformanceScenario(),
                        new IntegerStoredSizeLoopPerformanceScenario()
                    }, PerformanceTestingMode.PLATFORM_EVENTS)
                    .setStartSize(1000)
                    .setStepSize(1000)
                    .setEndSize(10000)
                    .setRepetitions(20)
                    .clearExistingResults()
                    .run();
    }
}