/**
 * @author aidan@processity.ai
 * @date 23/07/2024
 */

@IsTest
public class PerformanceExperimentTest {
    static final List<Integer> sizes = new List<Integer>();
    static Integer runs = 0;
    static Integer teardowns = 0;

    @IsTest
    static void normalBehaviour() {
        TestPerformanceScenario testPerformanceScenario = new TestPerformanceScenario();
        PerformanceExperiment experiment = new PerformanceExperiment.Builder()
                                                .setSuiteName('PerformanceExperimentTest')
                                                .setExperiment(testPerformanceScenario)
                                                .setStartSize(0)
                                                .setStepSize(1)
                                                .setEndSize(4)
                                                .setMode(PerformanceTestingMode.QUEUEABLE)
                                                .setRepetitions(2)
                                                .getInstance();

        Test.startTest();
        experiment.execute();
        Test.stopTest();

        Assert.isTrue(assertTestPerformanceScenario(0, 1, 4, 2));
    }

    @IsTest
    static void chaining() {
        TestPerformanceScenario testPerformanceScenario = new TestPerformanceScenario();
        PerformanceExperiment experiment = new PerformanceExperiment.Builder()
                                                .setSuiteName('PerformanceExperimentTest')
                                                .setExperiment(testPerformanceScenario)
                                                .setStartSize(0)
                                                .setStepSize(1)
                                                .setEndSize(2)
                                                .setMode(PerformanceTestingMode.QUEUEABLE)
                                                .setRepetitions(2)
                                                .setThenRun(
                                                    new PerformanceExperiment.Builder()
                                                        .setSuiteName('PerformanceExperimentTest')
                                                        .setExperiment(testPerformanceScenario)
                                                        .setStartSize(3)
                                                        .setStepSize(1)
                                                        .setEndSize(4)
                                                        .setMode(PerformanceTestingMode.QUEUEABLE)
                                                        .setRepetitions(2)
                                                        .getInstance()
                                                )
                                                .getInstance();

        Test.startTest();
        experiment.execute();
        Test.stopTest();

        Assert.isTrue(assertTestPerformanceScenario(0, 1, 4, 2));
    }

    public static Boolean assertTestPerformanceScenario(
        Integer startSize,
        Integer stepSize,
        Integer endSize,
        Integer repetitions
    ) {
        List<PerformanceMeasureResult__c> results = [
            SELECT ExperimentName__c, Size__c, Result__c, CpuTimeInMs__c, RealTimeInMs__c, HeapSizeInKB__c
            FROM PerformanceMeasureResult__c
            WHERE Result__c = 'SUCCESS'
            ORDER BY Size__c ASC
        ];

        for (PerformanceMeasureResult__c thisResult : results) {
            Assert.isTrue(thisResult.CpuTimeInMs__c >= 0);
            Assert.isTrue(thisResult.RealTimeInMs__c >= 0);
            Assert.isTrue(thisResult.HeapSizeInKB__c >= 0);
            Assert.areEqual(TestPerformanceScenario.class.getName(), thisResult.ExperimentName__c);
            Assert.areEqual(ParentJobResult.SUCCESS.name(), thisResult.Result__c);
        }

        Integer totalExecutions = ((endSize - startSize + 1) / stepSize) * repetitions;

        Assert.areEqual(totalExecutions, PerformanceExperimentTest.runs);
        Assert.areEqual(totalExecutions, PerformanceExperimentTest.teardowns);
        for (Integer i = 0; i <= endSize; i += stepSize) {
            for (Integer j = 0; j < repetitions; j++) {
                Assert.areEqual(i, PerformanceExperimentTest.sizes[i * repetitions + j]);
                Assert.areEqual(i, results[i * repetitions + j].Size__c);
            }
        }

        return true;
    }

    @IsTest
    static void failureInSetup() {
        Assert.isTrue(failureIn(FailureMode.SETUP, 'Failed in Setup'));
    }
    @IsTest
    static void failureInRun() {
        Assert.isTrue(failureIn(FailureMode.RUN, 'Failed in Run'));
    }
    @IsTest
    static void failureInTeardown() {
        Assert.isTrue(failureIn(FailureMode.TEARDOWN, 'Failed in Teardown'));
    }

    //PMD false positive, no need to handle the exception, we're testing failure and finalizers
    @SuppressWarnings('PMD.EmptyCatchBlock')
    static Boolean failureIn(FailureMode modeToFailIn, String expectedMessage) {
        FailingPerformanceScenario failingPerformanceScenario = new FailingPerformanceScenario(modeToFailIn);
        PerformanceExperiment experiment = new PerformanceExperiment.Builder()
                                                .setSuiteName('PerformanceExperimentTest')
                                                .setExperiment(failingPerformanceScenario)
                                                .setStartSize(0)
                                                .setEndSize(2)
                                                .setStepSize(1)
                                                .setMode(PerformanceTestingMode.QUEUEABLE)
                                                .setRepetitions(2)
                                                .getInstance();

        try {
            Test.startTest();
            experiment.execute();
            Test.stopTest();
        } catch (IllegalArgumentException e) {
            // Do nothing, we just want the finalizers to run
        }

        // A second AsyncJob shows that the finalizer has re-queued the experiment. Apex tests won't run it, so we
        // can't look for the actual result
        String apexClassName = PerformanceExperiment.class.getName();
        Integer pos = apexClassName.indexOf('.');
        apexClassName = pos < 0 ? apexClassName : apexClassName.substring(pos + 1);
        Assert.areEqual(2, [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :apexClassName].size());

        List<PerformanceMeasureResult__c> results = [
            SELECT ExperimentName__c, ErrorDetail__c, Size__c, Result__c
            FROM PerformanceMeasureResult__c
            ORDER BY Size__c ASC
        ];

        Assert.areEqual(FailingPerformanceScenario.class.getName(), results[0].ExperimentName__c);
        Assert.areEqual(ParentJobResult.UNHANDLED_EXCEPTION.name(), results[0].Result__c);
        Assert.isTrue(results[0].ErrorDetail__c.contains(expectedMessage));
        return true;
    }

    public class TestPerformanceScenario extends PerformanceScenario {
        // Note that sizes, runs, and teardowns cannot be instance variables because this instance gets
        // serialised when the PerformanceExperiment Queueable runs, meaning that it's no longer the same
        // instance we created in the test method

        public override void setup(Integer size) {
            PerformanceExperimentTest.sizes.add(size);
        }

        public override void run() {
            PerformanceExperimentTest.runs++;
        }

        public override void teardown() {
            PerformanceExperimentTest.teardowns++;
        }
    }

    public enum FailureMode {
        SETUP,
        RUN,
        TEARDOWN
    }

    public class FailingPerformanceScenario extends PerformanceScenario {
        private FailureMode currentFailureMode;

        public FailingPerformanceScenario(FailureMode currentFailureMode) {
            this.currentFailureMode = currentFailureMode;
        }

        public override void setup(Integer size) {
            if (currentFailureMode == FailureMode.SETUP) {
                currentFailureMode = null;
                throw new IllegalArgumentException('Failed in Setup');
            }
        }

        public override void run() {
            if (currentFailureMode == FailureMode.RUN) {
                currentFailureMode = null;
                throw new IllegalArgumentException('Failed in Run');
            }
        }

        public override void teardown() {
            if (currentFailureMode == FailureMode.TEARDOWN) {
                currentFailureMode = null;
                throw new IllegalArgumentException('Failed in Teardown');
            }
        }
    }
}
