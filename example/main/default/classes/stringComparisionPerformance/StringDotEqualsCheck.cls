public with sharing class StringDotEqualsCheck extends StringComparisionScenario {
    public override void run() {
        Integer size = firstTexts.size();

        for(Integer i = 0; i < size; i++) {
            Boolean isEqual = firstTexts[i].equals(secondTexts[i]);
        }
    }

    public override String getLabel() {
        return 'String.equals';
    }
}