public with sharing class CurrentTimeLimitMeasure implements LimitMeasure {
    private Long startTime;

    public CurrentTimeLimitMeasure() {
        this.startTime = System.currentTimeMillis();
    }

    public Integer getResult() {
        return Integer.valueOf(System.currentTimeMillis() - startTime);
    }
}
