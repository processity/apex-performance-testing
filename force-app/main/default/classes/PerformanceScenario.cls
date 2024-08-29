/**
 * @author aidan@processity.ai
 * @date 10/07/2024
 * @description A scenario to be performance tested. As you'd expect, setup() is called beforehand, run() is measured,
 * then teardown() in called
 */

@NamespaceAccessible
public abstract class PerformanceScenario {
    protected Integer size;

    public virtual void setup(Integer size) {
        this.size = size;
    }

    public abstract void run();

    public virtual void teardown() {
        this.size = null;
    }

    public virtual String getLabel() {
        return getClassNameOf(this);
    }


    // This is crazy-ugly, but works even for inner classes
    // https://salesforce.stackexchange.com/questions/3385/can-i-determine-the-class-name-of-an-object-instance-at-run-time/384185#384185
    @SuppressWarnings('PMD.UnusedLocalVariable')
    public static String getClassNameOf(Object performanceScenario) {
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
