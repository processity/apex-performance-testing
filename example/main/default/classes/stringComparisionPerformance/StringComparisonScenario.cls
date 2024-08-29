public abstract class StringComparisonScenario extends PerformanceScenario {
    protected List<String> firstTexts;
    protected List<String> secondTexts;
    private static final String CHARACTERS = 'abcdefghijklmnopqrstuvwxyz'.repeat(50);

    public override void setup(Integer size) {
        firstTexts = new List<String>(size);
        secondTexts = new List<String>(size);

        for (Integer i = 0; i < size; i++) {
            firstTexts[i] = CHARACTERS;
            secondTexts[i] = CHARACTERS;
        }
    }
}
