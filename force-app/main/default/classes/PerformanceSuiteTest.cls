/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

@IsTest
private class PerformanceSuiteTest {

    @IsTest
    static void testBehavior() {
        Test.startTest();
        new PerformanceSuite('PerformanceSuiteTest', new List<PerformanceScenario>{
                new PerformanceExperimentTest.TestPerformanceScenario()
        })
                .setStartSize(0)
                .setStepSize(1)
                .setEndSize(2)
                .setRepetitions(2)
                .run();
        Test.stopTest();
        
        Assert.isTrue(PerformanceExperimentTest.assertTestPerformanceScenario(0, 1, 2, 2));
    }
}