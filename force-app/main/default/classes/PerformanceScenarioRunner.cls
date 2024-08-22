/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public inherited sharing class PerformanceScenarioRunner {
    private PerformanceScenario performanceScenario;
    private PerformanceTestingMode mode;

    public PerformanceScenarioRunner(PerformanceScenario performanceScenario, PerformanceTestingMode mode) {
        this.performanceScenario = performanceScenario;
        this.mode = mode;
    }

    public Integer runAndReturnCpuTime(Integer size) {
        performanceScenario.setup(size);

        LimitMeasure measure;
        if (this.mode == PerformanceTestingMode.PLATFORM_EVENTS) {
            measure = new CurrentTimeLimitMeasure();
        } else {
            measure = new CpuLimitsMeasure();
        }

        performanceScenario.run();
        Integer cpuTime = measure.getResult();
        performanceScenario.teardown();

        return cpuTime;
    }
}
