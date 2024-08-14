/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public with sharing class ListPopulatePerformanceSuite {
    public static void run() {
        new PerformanceSuite('ListPopulate', new List<PerformanceScenario>{
                new ListPopulateByAddPerformanceScenario(),
                new ListPopulateByAssignPerformanceScenario()
        })
                .setStartSize(10000)
                .setStepSize(1000)
                .setEndSize(100000)
                .setRepetitions(5)
                .clearExistingResults()
                .run();
    }
}