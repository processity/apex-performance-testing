/**
 * @author aidan@processity.ai
 * @date 11/07/2024
 * @description A suite of performance experiments to run. Create with a list of scenarios and the size/iterations.
 * Then, the suite will run all the experiments in chained Queueables
 */

@NamespaceAccessible
public with sharing class PerformanceSuite {
    private final String suiteName;
    private final Integer numberOfExperiments;
    private final PerformanceTestingMode mode;
    private final Iterator<String> performanceScenarioNames;
    private final Iterator<PerformanceScenario> performanceScenariosToRun;

    private Integer startSize;
    private Integer stepSize;
    private Integer endSize;
    private Integer repetitions;

    @NamespaceAccessible
    public PerformanceSuite(String suiteName, List<PerformanceScenario> performanceScenariosToRun) {
        this(suiteName, performanceScenariosToRun, PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER);
    }

    @NamespaceAccessible
    public PerformanceSuite(
        String suiteName,
        List<PerformanceScenario> performanceScenariosToRun,
        PerformanceTestingMode mode
    ) {
        this.numberOfExperiments = performanceScenariosToRun.size();
        this.performanceScenariosToRun = performanceScenariosToRun.iterator();
        this.suiteName = suiteName;
        List<String> performanceScenarioNames = new List<String>();
        for (PerformanceScenario thisScenario : performanceScenariosToRun) {
            performanceScenarioNames.add(PerformanceScenario.getClassNameOf(thisScenario));
        }
        this.performanceScenarioNames = performanceScenarioNames.iterator();
        this.mode = mode;
    }

    @NamespaceAccessible
    public PerformanceSuite setStartSize(Integer startSize) {
        this.startSize = startSize;
        return this;
    }

    @NamespaceAccessible
    public PerformanceSuite setStepSize(Integer stepSize) {
        this.stepSize = stepSize;
        return this;
    }

    @NamespaceAccessible
    public PerformanceSuite setEndSize(Integer endSize) {
        this.endSize = endSize;
        return this;
    }

    @NamespaceAccessible
    public PerformanceSuite setRepetitions(Integer repetitions) {
        this.repetitions = repetitions;
        return this;
    }

    @NamespaceAccessible
    public PerformanceSuite clearExistingResults() {
        delete [SELECT Id FROM PerformanceMeasureResult__c WHERE SuiteName__c = :suiteName];
        return this;
    }

    @NamespaceAccessible
    public PerformanceSuite.Response run() {
        PerformanceExperiment baseExperiment;
        Integer totalExecutions = Integer.valueOf(
            Math.ceil((endSize - startSize) / stepSize + 1) * repetitions * numberOfExperiments
        );

        do {
            PerformanceExperiment thisExperiment = new PerformanceExperiment.Builder()
                .setSuiteName(suiteName)
                .setStartSize(startSize)
                .setStepSize(stepSize)
                .setEndSize(endSize)
                .setMode(mode)
                .setRepetitions(repetitions)
                .setExperiment(performanceScenariosToRun.next())
                .setTotalExecutions(totalExecutions)
                .setThenRun(baseExperiment)
                .getInstance();

            baseExperiment = thisExperiment;
        } while (performanceScenariosToRun.hasNext());

        try {
            baseExperiment.execute();

            insert as system new PerformanceMeasureResult__c(
                SuiteName__c = suiteName,
                ExperimentName__c = baseExperiment.getLabel(),
                Size__c = 0,
                Result__c = 'STARTED',
                PerformanceMetrics__c = JSON.serialize(
                    new Map<String, Object>{
                        'totalExecutions' => totalExecutions,
                        'mode' => mode.name()
                    }
                )
            );
        } catch (Exception ex) {
            insert as system new PerformanceMeasureResult__c(
                Result__c = 'Error',
                SuiteName__c = suiteName,
                Size__c = baseExperiment.thisStep,
                ExperimentName__c = baseExperiment.getLabel(),
                ErrorDetail__c = ex.getTypeName() + ': ' + ex.getMessage() + '\n' + ex.getStackTraceString()
            );
        }

        return new PerformanceSuite.Response(suiteName, totalExecutions, mode);
    }

    @NamespaceAccessible
    public inherited sharing class Response {
        @NamespaceAccessible
        public String label;
        @NamespaceAccessible
        public PerformanceTestingMode mode;
        @NamespaceAccessible
        public Integer totalExecutions;

        public Response(String label, Integer totalExecutions, PerformanceTestingMode mode) {
            this.label = label;
            this.mode = mode;
            this.totalExecutions = totalExecutions;
        }

        public Response(String label, Integer totalExecutions) {
            this.label = label;
            this.mode = PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER;
            this.totalExecutions = totalExecutions;
        }

        public Response(String label) {
            this.label = label;
            this.totalExecutions = 0;
            this.mode = PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER;
        }
    }
}
