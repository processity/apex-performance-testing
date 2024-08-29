public with sharing class StringDotEqualsIgnoreCase extends StringComparisonScenario {
    public override void run() {
        Integer size = firstTexts.size();

        for(Integer i = 0; i < size; i++) {
            Boolean isEqual = firstTexts[i].equalsIgnoreCase(secondTexts[i]);
        }
    }

    public override String getLabel() {
        return 'String.equalsIgnoreCase';
    }
}