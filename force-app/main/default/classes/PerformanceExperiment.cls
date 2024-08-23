/**
 * @author aidan@processity.ai
 * @date 10/07/2024
 * @description Runs a PerformanceScenario with the given size and repetitions. If thenRun() is set with another
 * PerformanceExperiment, then this other one is started after this one completes
 */

@NamespaceAccessible
public with sharing class PerformanceExperiment implements Queueable {
    private Integer stepSize;
    private Integer endSize;
    private Integer repetitions;
    private Integer thisRepetition;
    private Integer totalExecutions;
    
    private String experimentType;
    private String serializedThenRun;
    
    public PerformanceScenario experiment;
    public PerformanceExperiment thenRun;

    public String suiteName { get; private set; }
    public String experimentName { get; private set; }
    public Integer thisStep { get; private set; }
    public PerformanceTestingMode mode { get; private set; }

    @NamespaceAccessible
    public PerformanceExperiment setStartSize(Integer startSize) {
        thisStep = startSize;

        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setStepSize(Integer stepSize) {
        this.stepSize = stepSize;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setMode(PerformanceTestingMode mode) {
        this.mode = mode;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setTotalExecutions(Integer totalExecutions) {
        this.totalExecutions = totalExecutions;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setEndSize(Integer endSize) {
        this.endSize = endSize;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setRepetitions(Integer repetitions) {
        this.repetitions = repetitions;
        thisRepetition = 0;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setSuiteName(String suiteName) {
        this.suiteName = suiteName;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setExperimentName(String experimentName) {
        this.experimentName = experimentName;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment setExperiment(PerformanceScenario experiment) {
        this.experiment = experiment;
        return this;
    }

    @NamespaceAccessible
    public PerformanceExperiment thenRun(PerformanceExperiment thenRun) {
        this.thenRun = thenRun;
        return this;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new PerformanceExperimentFinalizer(this));
        if (mode == PerformanceTestingMode.QUEUEABLE) {
            run();
        }
    }

    public static PerformanceExperiment deserialize(String jsonString) {
        PerformanceExperiment result = new PerformanceExperiment();
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        String experimentType = (String) jsonMap.get('experimentType');

        try {
            Type concreteType = Type.forName(experimentType);
            result.experiment = (PerformanceScenario) JSON.deserialize(
                JSON.serialize(jsonMap.get('experiment')),
                concreteType
            );
        } catch (Exception e) {
            throw new IllegalArgumentException('Invalid interfaceType: ' + experimentType);
        }

        result.thisStep = (Integer) jsonMap.get('thisStep');
        result.stepSize = (Integer) jsonMap.get('stepSize');
        result.endSize = (Integer) jsonMap.get('endSize');
        result.repetitions = (Integer) jsonMap.get('repetitions');
        result.thisRepetition = (Integer) jsonMap.get('thisRepetition');
        result.totalExecutions = (Integer) jsonMap.get('totalExecutions');
        result.mode = PerformanceTestingMode.valueOf((String) jsonMap.get('mode'));

        String serializedThenRun = (String) jsonMap.get('serializedThenRun');

        result.thenRun = serializedThenRun != null ? PerformanceExperiment.deserialize(serializedThenRun) : null;
        result.suiteName = (String) jsonMap.get('suiteName');
        result.experimentName = (String) jsonMap.get('experimentName');
        return result;
    }

    public override String toString() {
        experimentType = getClassNameOf(experiment);
        serializedThenRun = thenRun != null ? thenRun.toString() : null;
        return JSON.serialize(this);
    }

    public void requeueIfNecessary() {
        AsyncOptions options = new AsyncOptions();
        options.minimumQueueableDelayInMinutes = 0;
        if (!AsyncInfo.hasMaxStackDepth()) {
            options.maximumQueueableStackDepth = getRequiredStackDepth();
        }

        if (thisStep <= endSize) {
            System.enqueueJob(this, options);
        } else if (thenRun != null) {
            System.enqueueJob(thenRun, options);
        } else {
            createCompletedRecord();
        }
    }

    public void runQueueable() {
        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.minimumQueueableDelayInMinutes = 0;
        asyncOptions.maximumQueueableStackDepth = getRequiredStackDepth();
        System.enqueueJob(this, asyncOptions);
    }

    public void run() {
        Integer cpuTime = new PerformanceScenarioRunner(experiment, mode).runAndReturnCpuTime(thisStep);

        insert as system new PerformanceMeasureResult__c(
            SuiteName__c = suiteName,
            ExperimentName__c = experiment.getLabel(),
            Size__c = thisStep,
            CpuTimeInMs__c = cpuTime,
            Result__c = ParentJobResult.SUCCESS.name()
        );
        executeNext();
    }

    public void executeNext() {
        incrementCounters();

        if (mode == PerformanceTestingMode.PLATFORM_EVENTS) {
            chainNextExecution();
        } else {
            requeueIfNecessary();
        }
    }

    public void chainNextExecution() {
        if (thisStep <= endSize) {
            publishEvent(this.toString(), false);
        } else if (thenRun != null) {
            publishEvent(thenRun.toString(), false);
        } else {
            createCompletedRecord();
            publishEvent(null, true);
        }
    }

    public void incrementCounters() {
        ++thisRepetition;
        if (thisRepetition >= repetitions) {
            thisRepetition = 0;
            thisStep += stepSize;
        }
    }

    private void createCompletedRecord() {
        insert as system new PerformanceMeasureResult__c(
            SuiteName__c = suiteName,
            ExperimentName__c = experiment.getLabel(),
            Result__c = 'COMPLETED',
            Size__c = thisStep
        );
    }

    private void publishEvent(String context, Boolean isFinal) {
        new Flow.Interview.Performance_Measure_Orcestrator(new Map<String, Object>{ 'serializedExperiment' => context })
            .start();

        PerformanceExperimentEvent__e event = new PerformanceExperimentEvent__e(
            IsFinal__c = isFinal,
            SuiteName__c = suiteName,
            ExperimentName__c = experiment.getLabel(),
            NextStepSize__c = getNextStepSize(),
            NextExperimentName__c = getNextExperimentName(),
            totalExecutions__c = totalExecutions
        );
        
        if(Test.isRunningTest()) {
            PerformanceExperimentEvent.executeExperiment(new List<String> { context });
        } else {
            Database.SaveResult sr = EventBus.publish(event);
            if (!sr.isSuccess()) {
                Database.Error err = sr.getErrors()[0];
                throw new IllegalArgumentException('Error Code: ' + err.getStatusCode() + ' - ' + err.getMessage());
            }   
        }
    }

    private String getNextExperimentName() {
        if (thisStep + 1 <= endSize) {
            return this.experiment.getLabel();
        } else if (thenRun != null) {
            return thenRun.experimentName;
        }

        return null;
    }

    private Integer getNextStepSize() {
        if (thisStep + 1 <= endSize) {
            return this.thisStep;
        } else if (thenRun != null) {
            return thenRun.thisStep;
        }

        return null;
    }

    private Integer getRequiredStackDepth() {
        return repetitions * (endSize - thisStep + stepSize) / stepSize + (thenRun?.getRequiredStackDepth() ?? 1);
    }

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
}
