/**
 * @author aidan@processity.ai
 * @date 10/07/2024
 * @description A scenario to be performance tested. As you'd expect, setup() is called beforehand, run() is measured,
 * then teardown() in called
 */

public interface PerformanceScenario {
    void setup(Integer size);
    void run();
    void teardown();
}