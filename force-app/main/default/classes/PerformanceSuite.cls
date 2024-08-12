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

    @NamespaceAccessible
    public PerformanceSuite(String suiteName, List<PerformanceScenario> performanceScenariosToRun) {
        this.performanceScenariosToRun = performanceScenariosToRun.iterator();
        this.suiteName = suiteName;
        List<String> performanceScenarioNames = new List<String>();
        for(PerformanceScenario thisScenario : performanceScenariosToRun) {
            performanceScenarioNames.add(getClassNameOf(thisScenario));
        }
        this.performanceScenarioNames = performanceScenarioNames.iterator();
    }

    // This is crazy-ugly, but works even for inner classes
    // https://salesforce.stackexchange.com/questions/3385/can-i-determine-the-class-name-of-an-object-instance-at-run-time/384185#384185
    @SuppressWarnings(
            'PMD.UnusedLocalVariable'
    ) // The case has to be used in a statement but we don't need the value
    private static String getClassNameOf(PerformanceScenario performanceScenario) {
        String result = 'DateTime';
        try {
            Datetime typeCheck = (Datetime) performanceScenario;
        } catch (System.TypeException expectedTypeException) {
            String message = expectedTypeException.getMessage()
                    .substringAfter('Invalid conversion from runtime type ');
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
    public void run() {
        PerformanceExperiment baseExperiment;

        do {
            PerformanceExperiment thisExperiment = new PerformanceExperiment()
                    .setSuiteName(suiteName)
                    .setStartSize(startSize)
                    .setStepSize(stepSize)
                    .setEndSize(endSize)
                    .setRepetitions(repetitions)
                    .setExperimentName(performanceScenarioNames.next())
                    .setExperiment(performanceScenariosToRun.next());

            thisExperiment.thenRun(baseExperiment);
            baseExperiment = thisExperiment;
        } while(performanceScenariosToRun.hasNext());

        baseExperiment.run();
    }
}