public with sharing class ResumePerformanceSuite {
    @InvocableMethod(
        Label='Resume Performance suite execution'
        Description='Resume Performance suite execution'
        Category='PerformanceTesting'
    )
    public static void resume(List<String> serializedExperiments) {
        new PerformanceExperimentEvent(serializedExperiments).resume();
    }
}
