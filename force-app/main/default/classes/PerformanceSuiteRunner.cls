/**
 * @author anmol@processity.ai
 * @date 27/08/2024
 * @description An interface all performance suite needs to implement in order to be called from Res API / CLI
 */

@NamespaceAccessible
public interface PerformanceSuiteRunner {
    PerformanceSuite.Response run();
}
