/**
 * @author anmol@processity.ai
 * @date 27/08/2024
 * @description Generates Performance metrics for a given experiment
 */

public with sharing class PerformanceMetrics {
    public String errorMessage;
    public Integer cpuTime;
    public Double realTime;
    public Double heapSize;

    private Integer startCpuTime;
    private Double startRealTime;
    private Integer startHeapSize;

    public PerformanceMetrics(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public PerformanceMetrics() {
        startCpuTime = Limits.getCpuTime();
        startRealTime = System.currentTimeMillis();
        startHeapSize = Limits.getHeapSize();
    }

    public void setResult() {
        cpuTime = Limits.getCpuTime() - startCpuTime;
        realTime = System.currentTimeMillis() - startRealTime;
        heapSize = Limits.getHeapSize() - startHeapSize;

        reset();
    }

    private void reset() {
        startCpuTime = null;
        startRealTime = null;
        startHeapSize = null;
    }
}