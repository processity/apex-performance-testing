public with sharing class PerformanceExperimentEvent {
    private String serializedExperiment;

    public PerformanceExperimentEvent(List<String> serializedExperiments) {
        serializedExperiment = serializedExperiments[0];
    }

    @InvocableMethod(
        label='Execute Experiment'
        description='Execute next Experiment from list of experiment.'
        category='PerformanceTesting'
    )
    public static void executeExperiment(List<String> serializedExperiments) {
        new PerformanceExperimentEvent(serializedExperiments).execute();
    }

    public void execute() {
        if (serializedExperiment != null) {
            PerformanceExperiment thisExperiment = PerformanceExperiment.deserialize(serializedExperiment);

            try {
                thisExperiment.run();
            } catch (Exception ex) {
                throw ex;
            }
        }
    }

    public void resume() {
        if (serializedExperiment != null) {
            PerformanceExperiment thisExperiment = PerformanceExperiment.deserialize(serializedExperiment);
            thisExperiment.executeNext();
        }
    }
}
