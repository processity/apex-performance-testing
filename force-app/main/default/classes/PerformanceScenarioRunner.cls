/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public inherited sharing class PerformanceScenarioRunner {
    
    private PerformanceScenario performanceScenario;

    public PerformanceScenarioRunner(PerformanceScenario performanceScenario) {
        this.performanceScenario = performanceScenario;
    }

    public Integer runAndReturnCpuTime(Integer size) {
        performanceScenario.setup(size);
        LimitsMeasure measure = new LimitsMeasure();
        performanceScenario.run();
        Integer cpuTime = measure.getResult();
        performanceScenario.teardown();
        return cpuTime;
    }
}