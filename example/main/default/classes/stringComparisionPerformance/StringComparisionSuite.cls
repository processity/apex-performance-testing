public with sharing class StringComparisionSuite implements PerformanceSuiteRunner {
    public PerformanceSuite.Response run() {
        return new PerformanceSuite(
                'String Comparision',
                new List<PerformanceScenario>{
                    new ClassicEqualityCheck(),
                    new StringDotEqualsCheck(),
                    new StringDotEqualsIgnoreCase()
                },
                PerformanceTestingMode.QUEUEABLE
            )
            .setStartSize(10)
            .setStepSize(10)
            .setEndSize(100)
            .setRepetitions(1)
            .clearExistingResults()
            .run();
    }
}
