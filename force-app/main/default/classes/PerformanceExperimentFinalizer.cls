/**
 * @author aidan@processity.ai
 * @date 18/07/2024
 * @description If a experiment failed, then insert a record to mark the failure and continue from the next
 * step.
 * Run the current experiment if the running mode is Queueable Finalizer.
 */

public with sharing class PerformanceExperimentFinalizer implements Finalizer {
    private final PerformanceExperiment experiment;

    public PerformanceExperimentFinalizer(PerformanceExperiment experiment) {
        this.experiment = experiment;
    }

    public void execute(FinalizerContext context) {
        if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            createErrorRecord(context.getException());
            experiment.executeNext();
        } else if (experiment?.mode == PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER) {
            try {
                experiment.run();
            } catch (Exception ex) {
                createErrorRecord(ex);
            }
        }
    }

    private void createErrorRecord(Exception ex) {
        insert as system new PerformanceMeasureResult__c(
            Size__c = experiment.thisStep,
            SuiteName__c = experiment.suiteName,
            Result__c = ParentJobResult.UNHANDLED_EXCEPTION.name(),
            ExperimentName__c = experiment.getLabel(),
            ErrorDetail__c = ex.getTypeName() + ': ' + ex.getMessage() + '\n' + ex.getStackTraceString()
        );
    }
}
