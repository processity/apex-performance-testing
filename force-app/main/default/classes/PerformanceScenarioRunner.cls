/**
 * @author aidan@processity.ai
 * @date 14/08/2024
 */

public inherited sharing class PerformanceScenarioRunner {
    private PerformanceScenario performanceScenario;

    public PerformanceScenarioRunner(PerformanceScenario performanceScenario) {
        this.performanceScenario = performanceScenario;
    }

    public PerformanceMetrics runAndReturnMetrics(Integer size) {
        performanceScenario.setup(size);

        PerformanceMetrics measure = new PerformanceMetrics();
        performanceScenario.run();
        measure.setResult();

        performanceScenario.teardown();

        return measure;
    }
}
