/**
 * @author aidan@processity.ai
 * @date 11/07/2024
 * @description A suite of performance experiments to run. Create with a list of scenarios and the size/iterations.
 * Then, the suite will run all the experiments in chained Queueables
 */

@NamespaceAccessible
public with sharing class PerformanceSuite {
    private Iterator<PerformanceScenario> performanceScenariosToRun;
    private Iterator<String> performanceScenarioNames;
    private String suiteName;
    private Integer startSize;
    private Integer stepSize;
    private Integer endSize;
    private Integer repetitions;
    private Integer numberOfExperiments;
    private PerformanceTestingMode mode;

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
            performanceScenarioNames.add(getClassNameOf(thisScenario));
        }
        this.performanceScenarioNames = performanceScenarioNames.iterator();
        this.mode = mode;
    }

    // This is crazy-ugly, but works even for inner classes
    // https://salesforce.stackexchange.com/questions/3385/can-i-determine-the-class-name-of-an-object-instance-at-run-time/384185#384185
    @SuppressWarnings('PMD.UnusedLocalVariable') // The case has to be used in a statement but we don't need the value
    private static String getClassNameOf(Object performanceScenario) {
        String result = 'DateTime';
        try {
            Datetime typeCheck = (Datetime) performanceScenario;
        } catch (System.TypeException expectedTypeException) {
            String message = expectedTypeException.getMessage().substringAfter('Invalid conversion from runtime type ');
            result = message.substringBefore(' to Datetime');
        }
        return result;
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
    public Integer run() {
        PerformanceExperiment baseExperiment;
        Integer totalExecutions = Integer.valueOf(
            Math.ceil((endSize - startSize) / stepSize + 1) * repetitions * numberOfExperiments
        );

        do {
            PerformanceExperiment thisExperiment = new PerformanceExperiment()
                .setSuiteName(suiteName)
                .setStartSize(startSize)
                .setStepSize(stepSize)
                .setEndSize(endSize)
                .setMode(mode)
                .setRepetitions(repetitions)
                .setExperimentName(performanceScenarioNames.next())
                .setExperiment(performanceScenariosToRun.next())
                .setTotalExecutions(totalExecutions);

            thisExperiment.thenRun(baseExperiment);
            baseExperiment = thisExperiment;
        } while (performanceScenariosToRun.hasNext());

        try {
            if (mode == PerformanceTestingMode.PLATFORM_EVENTS) {
                baseExperiment.run();
            } else {
                baseExperiment.runQueable();
            }
            insert as system new PerformanceMeasureResult__c(
                SuiteName__c = suiteName,
                ExperimentName__c = baseExperiment.experiment.getLabel(),
                Size__c = 0,
                Result__c = 'STARTED',
                ErrorDetail__c = JSON.serialize(
                    new Map<String, Object>{ 'totalExecutions' => totalExecutions, 'mode' => mode.name() }
                )
            );
        } catch (Exception ex) {
            insert as system new PerformanceMeasureResult__c(
                SuiteName__c = suiteName,
                ExperimentName__c = baseExperiment.experiment.getLabel(),
                Size__c = baseExperiment.thisStep,
                Result__c = 'Error',
                ErrorDetail__c = ex.getMessage()
            );
        }

        return totalExecutions;
    }
}
