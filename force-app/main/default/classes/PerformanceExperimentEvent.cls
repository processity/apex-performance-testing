/**
 * @author anmol@processity.ai
 * @date 27/08/2024
 * @description Runs a Performance Experiment as a callback for the platform event(from flow) or
 * runs next experiment if the current experiment execution fails.
 */

public with sharing class PerformanceExperimentEvent {
    private final String serializedExperiment;

    @InvocableMethod(
        Label='Execute Experiment'
        Description='Execute next Experiment from list of experiment.'
        Category='PerformanceTesting'
    )
    public static void executeExperiment(List<String> serializedExperiments) {
        new PerformanceExperimentEvent(serializedExperiments).execute();
    }

    public PerformanceExperimentEvent(List<String> serializedExperiments) {
        serializedExperiment = serializedExperiments[0];
    }

    public void execute() {
        if (serializedExperiment != null) {
            PerformanceExperiment experiment = new PerformanceExperiment.Builder(serializedExperiment).getInstance();
            experiment.execute();
        }
    }

    public void resume() {
        if (serializedExperiment != null) {
            PerformanceExperiment experiment = new PerformanceExperiment.Builder(serializedExperiment).getInstance();
            experiment.executeNext();
        }
    }
}
