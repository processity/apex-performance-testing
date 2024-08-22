/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

@IsTest
private class PerformanceSuiteTest {
    @IsTest
    private static void runInQueueableMode() {
        Test.startTest();
        new PerformanceSuite(
                'PerformanceSuiteTest',
                new List<PerformanceScenario>{ new PerformanceExperimentTest.TestPerformanceScenario() },
                PerformanceTestingMode.QUEUEABLE
            )
            .setStartSize(0)
            .setStepSize(1)
            .setEndSize(2)
            .setRepetitions(2)
            .clearExistingResults()
            .run();

        Test.stopTest();

        Assert.isTrue(PerformanceExperimentTest.assertTestPerformanceScenario(0, 1, 2, 2));
    }

    @IsTest
    private static void runInQueueableFinializerMode() {
        Test.startTest();
        new PerformanceSuite(
                'PerformanceSuiteTest',
                new List<PerformanceScenario>{ new PerformanceExperimentTest.TestPerformanceScenario() }
            )
            .setStartSize(0)
            .setStepSize(1)
            .setEndSize(2)
            .setRepetitions(2)
            .clearExistingResults()
            .run();

        Test.stopTest();

        Assert.isTrue(PerformanceExperimentTest.assertTestPerformanceScenario(0, 1, 2, 2));
    }

    @IsTest
    private static void runInPlatformEventMode() {
        Test.startTest();
        new PerformanceSuite(
                'PerformanceSuiteTest',
                new List<PerformanceScenario> {
                    new PerformanceExperimentTest.FailingPerformanceScenario(PerformanceExperimentTest.FailureMode.RUN),
                    new PerformanceExperimentTest.TestPerformanceScenario()
                },
                PerformanceTestingMode.PLATFORM_EVENTS
            )
            .setStartSize(0)
            .setStepSize(1)
            .setEndSize(2)
            .setRepetitions(2)
            .clearExistingResults()
            .run();
        Test.stopTest();

        Assert.isTrue(PerformanceExperimentTest.assertTestPerformanceScenario(0, 1, 2, 2));
    }
}
