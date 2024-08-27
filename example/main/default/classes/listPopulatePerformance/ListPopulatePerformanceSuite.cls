/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public with sharing class ListPopulatePerformanceSuite implements PerformanceSuiteRunner {
    public static PerformanceSuite.Response run() {
       return new PerformanceSuite('ListPopulate', new List<PerformanceScenario>{
                        new ListPopulateByAddPerformanceScenario(),
                        new ListPopulateByAssignPerformanceScenario()
                    }, PerformanceTestingMode.PLATFORM_EVENTS)
                    .setStartSize(10000)
                    .setStepSize(1000)
                    .setEndSize(100000)
                    .setRepetitions(5)
                    .clearExistingResults()
                    .run();
    }
}