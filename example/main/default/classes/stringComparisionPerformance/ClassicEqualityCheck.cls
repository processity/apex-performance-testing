public with sharing class ClassicEqualityCheck extends StringComparisonScenario {
    public override void run() {
        Integer size = firstTexts.size();

        for(Integer i = 0; i < size; i++) {
            Boolean isEqual = firstTexts[i] == secondTexts[i];
        }
    }

    public override String getLabel() {
        return 'Classic =';
    }
}