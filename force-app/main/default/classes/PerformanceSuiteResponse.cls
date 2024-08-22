public inherited sharing class PerformanceSuiteResponse {
    public String label;
    public PerformanceTestingMode mode;
    public Integer totalExecutions;

    public PerformanceSuiteResponse(String label, Integer totalExecutions, PerformanceTestingMode mode) {
        this.label = label;
        this.mode = mode;
        this.totalExecutions = totalExecutions;
    }

    public PerformanceSuiteResponse(String label, Integer totalExecutions) {
        this.label = label;
        this.mode = PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER;
        this.totalExecutions = totalExecutions;
    }

    public PerformanceSuiteResponse(String label) {
        this.label = label;
        this.totalExecutions = 0;
        this.mode = PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER;
    }
}
