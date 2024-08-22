@IsTest
private class PerformanceTestAPITest {

    @IsTest
    private static void runWithoutTestSuite() {
        // Setup
        setRestContext();

        // Exercise
        PerformanceTestAPI.Response result = PerformanceTestAPI.executePerformanceSuite(null);

        // Verify
        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.areEqual('REQUIRED_PARAMETER_MISSING', result.status);
        Assert.areEqual('Missing suiteName(Apex class that implements PerformanceSuiteRunner interface)', result.message);
    }


    @IsTest
    private static void runInvalidTestSuite() {
        // Setup
        setRestContext();

        // Exercise
        PerformanceTestAPI.Response response = PerformanceTestAPI.executePerformanceSuite('InvalidSuite');

        // Verify
        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.areEqual('BAD_REQUEST', response.status);
        Assert.areEqual('InvalidSuite class does not implement PerformanceSuiteRunner interface.', response.message);
    }


    @IsTest
    private static void runValidTestSuite() {
        // Setup
        setRestContext();

        // Exercise
        PerformanceTestAPI.Response response = PerformanceTestAPI.executePerformanceSuite('PerformanceTestAPITest.TestPerformanceSuiteRunner');

        // Verify
        Assert.areEqual(200, RestContext.response.statusCode);
        Assert.areEqual(PerformanceTestingMode.QUEUEABLE_FROM_FINALIZER.name(), response.status);
        Assert.areEqual('TestPerformanceSuiteRunner Execution has started', response.message);
    }


    @IsTest
    private static void runTestSuiteWithException() {
        // Setup
        setRestContext();

        // Exercise
        PerformanceTestAPI.Response response = PerformanceTestAPI.executePerformanceSuite('PerformanceTestAPITest.BadPerformanceSuiteRunner');

        // Verify
        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.areEqual('Error', response.status);
        Assert.areEqual('Error Message', response.message);
    }



    // HELPER

    public class TestPerformanceSuiteRunner implements PerformanceSuiteRunner {
        public PerformanceSuiteResponse run() {
            return new PerformanceSuiteResponse('TestPerformanceSuiteRunner');
        }
    }

    public class BadPerformanceSuiteRunner implements PerformanceSuiteRunner {
        public PerformanceSuiteResponse run() {
            throw new IllegalArgumentException('Error Message');
        }
    }

    private static void setRestContext() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/PerformanceTestAPI/';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{}');

        RestContext.request = req;
        RestContext.response = res;
    }
}