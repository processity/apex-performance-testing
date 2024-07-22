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
    private PerformanceScenario experiment;
    
    private Integer thisRepetition;
    private PerformanceExperiment thenRun;

    public String experimentName {get; private set;}
    public Integer thisStep {get; private set;}
    
    public PerformanceExperiment setStartSize(Integer startSize) {
        thisStep = startSize;
        return this;
    }

    public PerformanceExperiment setStepSize(Integer stepSize) {
        this.stepSize = stepSize;
        return this;
    }

    public PerformanceExperiment setEndSize(Integer endSize) {
        this.endSize = endSize;
        return this;
    }

    public PerformanceExperiment setRepetitions(Integer repetitions) {
        this.repetitions = repetitions;
        thisRepetition = 0;
        return this;
    }

    public PerformanceExperiment setExperimentName(String experimentName) {
        this.experimentName = experimentName;
        return this;
    }

    public PerformanceExperiment setExperiment(PerformanceScenario experiment) {
        this.experiment = experiment;
        return this;
    }
    
    public PerformanceExperiment thenRun(PerformanceExperiment thenRun) {
        this.thenRun = thenRun;
        return this;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new PerformanceExperimentFinalizer(this));
        
        experiment.setup(thisStep);
        LimitsMeasure measure = new LimitsMeasure();
        experiment.run();
        Integer cpuTime = measure.getResult();
        experiment.teardown();
        
        insert new PerformanceMeasureResult__c(
                ExperimentName__c = experimentName,
                Size__c = thisStep,
                CpuTimeInMs__c = cpuTime,
                Result__c = ParentJobResult.SUCCESS.name()
        );
        
        incrementCounters();
        requeueIfNecessary();
    }

    public void requeueIfNecessary() {
        AsyncOptions options = new AsyncOptions();
        options.minimumQueueableDelayInMinutes = 0;
        if(!AsyncInfo.hasMaxStackDepth()) {
            options.maximumQueueableStackDepth = getRequiredStackDepth();
        }
        if (thisStep <= endSize) {
            System.enqueueJob(this, options);
        } else {
            if (thenRun != null) {
                System.enqueueJob(thenRun, options);
            }
        }
    }

    public void incrementCounters() {
        ++thisRepetition;
        if (thisRepetition >= repetitions) {
            thisRepetition = 0;
            thisStep += stepSize;
        }
    }
    
    private Integer getRequiredStackDepth() {
        return repetitions * (endSize - thisStep + stepSize)/stepSize + (thenRun?.getRequiredStackDepth() ?? 1);
    }

    public void run() {
        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.minimumQueueableDelayInMinutes = 0;
        asyncOptions.maximumQueueableStackDepth = getRequiredStackDepth();
        System.enqueueJob(this, asyncOptions);
    }
}