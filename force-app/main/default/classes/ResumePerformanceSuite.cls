public with sharing class ResumePerformanceSuite {
    @InvocableMethod(
        label='Resume Performance suite execution'
        description='Resume Performance suite execution'
        category='PerformanceTesting'
    )
    public static void resume(List<String> serializedExperiments) {
        new PerformanceExperimentEvent(serializedExperiments).resume();
    }
}
