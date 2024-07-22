/**
 * @author aidan@processity.ai
 * @date 18/07/2024
 * @description If a PerformanceExperiment failed, then insert a record to mark the failure and continue from the next
 * step.
 */

public with sharing class PerformanceExperimentFinalizer implements Finalizer {
    
    private PerformanceExperiment performanceExperiment;

    public PerformanceExperimentFinalizer(PerformanceExperiment performanceExperiment) {
        this.performanceExperiment = performanceExperiment;
    }

    public void execute(FinalizerContext context) {
        if(context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            Exception errorException = context.getException();
            insert as user new PerformanceMeasureResult__c(
                    ExperimentName__c = performanceExperiment.experimentName,
                    Size__c = performanceExperiment.thisStep,
                    Result__c = ParentJobResult.UNHANDLED_EXCEPTION.name(),
                    ErrorDetail__c = errorException.getTypeName() + ': ' + errorException.getMessage() + '\n' + errorException.getStackTraceString()
            );
            performanceExperiment.incrementCounters();
            performanceExperiment.requeueIfNecessary();
        }
    }
}