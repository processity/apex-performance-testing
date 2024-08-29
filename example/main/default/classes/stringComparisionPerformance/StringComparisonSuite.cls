public with sharing class StringComparisonSuite implements PerformanceSuiteRunner {
    public PerformanceSuite.Response run() {
        return new PerformanceSuite(
                'String Comparison',
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
