/**
 * @author amol@processity.ai
 * @date 27/08/2024
 * @description Rest API to execute Performance suite by its name
 */

@RestResource(UrlMapping='/PerformanceTestAPI/*')
global with sharing class PerformanceTestAPI {
    @HttpPost
    global static Response executePerformanceSuite(String suiteName) {
        if (String.isBlank(suiteName)) {
            RestContext.response.statusCode = 400;
            return new Response(
                'REQUIRED_PARAMETER_MISSING',
                'Missing suiteName(Apex class that implements PerformanceSuiteRunner interface)'
            );
        }

        Response result;

        try {
            Type runnerType = Type.forName(suiteName);
            if (runnerType != null && PerformanceSuiteRunner.class.isAssignableFrom(runnerType)) {
                PerformanceSuiteRunner runnerInstance = (PerformanceSuiteRunner) runnerType.newInstance();

                PerformanceSuite.Response suiteResponse = runnerInstance.run();
                RestContext.response.statusCode = 200;
                result = new Response(
                    suiteResponse.label,
                    suiteResponse.mode.toString(),
                    suiteResponse.label + ' Execution has started',
                    suiteResponse.totalExecutions
                );
            } else {
                RestContext.response.statusCode = 400;
                result = new Response(
                    'BAD_REQUEST',
                    suiteName + ' class does not implement PerformanceSuiteRunner interface.'
                );
            }
        } catch (Exception ex) {
            RestContext.response.statusCode = 400;
            result = new Response('Error', ex.getMessage());
        }

        return result;
    }

    global class Response {
        public String status;
        public String message;
        public String suiteLabel;
        public Integer totalExecutions;

        public Response(String status, String message) {
            this.status = status;
            this.message = message;
        }

        public Response(String suiteLabel, String status, String message, Integer totalExecutions) {
            this.suiteLabel = suiteLabel;
            this.status = status;
            this.message = message;
            this.totalExecutions = totalExecutions;
        }
    }
}