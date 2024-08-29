/**
 * @author aidan@processity.ai
 * @date 10/07/2024
 * @description Runs a PerformanceScenario with the given size and repetitions. If thenRun() is set with another
 * PerformanceExperiment, then this other one is started after this one completes
 */

public with sharing class PerformanceExperiment implements Queueable {
    private Integer stepSize;
    private Integer endSize;
    private Integer repetitions;
    private Integer thisRepetition;
    private Integer totalExecutions;

    private String experimentType;
    private String serializedThenRun;

    private PerformanceScenario experiment;
    private PerformanceExperiment thenRun;

    public String suiteName { get; private set; }
    public Integer thisStep { get; private set; }
    public PerformanceTestingMode mode { get; private set; }

    public void execute() {
        if (mode == PerformanceTestingMode.PLATFORM_EVENTS) {
            run();
        } else {
            runQueueable();
        }
    }

    public void executeNext() {
        incrementCounters();

        if (mode == PerformanceTestingMode.PLATFORM_EVENTS) {
            chainNextExecution();
        } else {
            requeueIfNecessary();
        }
    }

    public void run() {
        PerformanceMetrics metrics = new PerformanceScenarioRunner(experiment).runAndReturnMetrics(thisStep);

        insert as system new PerformanceMeasureResult__c(
            Size__c = thisStep,
            SuiteName__c = suiteName,
            ExperimentName__c = getLabel(),
            Result__c = ParentJobResult.SUCCESS.name(),
            HeapSizeInKB__c = metrics.heapSize,
            RealTimeInMs__c = metrics.realTime,
            CpuTimeInMs__c = metrics.cpuTime
        );
        executeNext();
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new PerformanceExperimentFinalizer(this));

        // Note: when mode is queueable finalizer, run will be called from finalizer
        if (mode == PerformanceTestingMode.QUEUEABLE) {
            run();
        }
    }

    public override String toString() {
        experimentType = PerformanceScenario.getClassNameOf(experiment);
        serializedThenRun = thenRun != null ? thenRun.toString() : null;
        return JSON.serialize(this);
    }

    public String getLabel() {
        return experiment.getLabel();
    }

    private void runQueueable() {
        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.minimumQueueableDelayInMinutes = 0;
        asyncOptions.maximumQueueableStackDepth = getRequiredStackDepth();
        System.enqueueJob(this, asyncOptions);
    }

    private void requeueIfNecessary() {
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

    private void chainNextExecution() {
        if (thisStep <= endSize) {
            publishEvent(this.toString(), false);
        } else if (thenRun != null) {
            publishEvent(thenRun.toString(), false);
        } else {
            createCompletedRecord();
            publishEvent(null, true);
        }
    }

    private void incrementCounters() {
        ++thisRepetition;
        if (thisRepetition >= repetitions) {
            thisRepetition = 0;
            thisStep += stepSize;
        }
    }

    private void createCompletedRecord() {
        insert as system new PerformanceMeasureResult__c(
            Size__c = thisStep,
            Result__c = 'COMPLETED',
            SuiteName__c = suiteName,
            ExperimentName__c = getLabel()
        );
    }

    private void publishEvent(String context, Boolean isFinal) {
        new Flow.Interview.Performance_Measure_Orcestrator(new Map<String, Object>{ 'serializedExperiment' => context })
            .start();
        PerformanceExperiment next = nextExecution();
        PerformanceExperimentEvent__e event = new PerformanceExperimentEvent__e(
            IsFinal__c = isFinal,
            SuiteName__c = suiteName,
            ExperimentName__c = getLabel(),
            NextStepSize__c = next?.thisStep,
            NextExperimentName__c = next?.getLabel(),
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

    private PerformanceExperiment nextExecution() {
        if (thisStep <= endSize) {
            return this;
        } else if (thenRun != null) {
            return thenRun;
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

    public inherited sharing class Builder {
        private final PerformanceExperiment instance;

        public Builder() {
            instance = new PerformanceExperiment();
        }

        public Builder(String jsonString) {
            instance = new PerformanceExperiment();

            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            String experimentType = (String) jsonMap.get('experimentType');
            Type concreteType = Type.forName(experimentType);

            instance.experiment = (PerformanceScenario) JSON.deserialize(
                                                            JSON.serialize(jsonMap.get('experiment')),
                                                            concreteType
                                                        );

            setEndSize((Integer) jsonMap.get('endSize'));
            setStepSize((Integer) jsonMap.get('stepSize'));
            setStartSize((Integer) jsonMap.get('thisStep'));
            setSuiteName((String) jsonMap.get('suiteName'));
            setRepetitions((Integer) jsonMap.get('repetitions'));
            setThenRun((String) jsonMap.get('serializedThenRun'));
            setThisRepetition((Integer) jsonMap.get('thisRepetition'));
            setTotalExecutions((Integer) jsonMap.get('totalExecutions'));
            setMode(PerformanceTestingMode.valueOf((String) jsonMap.get('mode')));
        }

        public PerformanceExperiment getInstance() {
            return instance;
        }

        public Builder setThisRepetition(Integer thisRepetition) {
            instance.thisRepetition = thisRepetition;
            return this;
        }

        public Builder setStartSize(Integer startSize) {
            instance.thisStep = startSize;
            return this;
        }

        public Builder setStepSize(Integer stepSize) {
            instance.stepSize = stepSize;
            return this;
        }

        public Builder setMode(PerformanceTestingMode mode) {
            instance.mode = mode;
            return this;
        }

        public Builder setTotalExecutions(Integer totalExecutions) {
            instance.totalExecutions = totalExecutions;
            return this;
        }

        public Builder setEndSize(Integer endSize) {
            instance.endSize = endSize;
            return this;
        }

        public Builder setRepetitions(Integer repetitions) {
            instance.repetitions = repetitions;
            instance.thisRepetition = 0;
            return this;
        }

        public Builder setSuiteName(String suiteName) {
            instance.suiteName = suiteName;
            return this;
        }

        public Builder setExperiment(PerformanceScenario experiment) {
            instance.experiment = experiment;
            return this;
        }

        public Builder setThenRun(PerformanceExperiment thenRun) {
            instance.thenRun = thenRun;
            return this;
        }

        public Builder setThenRun(String serializedThenRun) {
            instance.thenRun = serializedThenRun != null ? new Builder(serializedThenRun).getInstance() : null;
            return this;
        }
    }
}
