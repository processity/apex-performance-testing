/**
 * @author aidan@processity.ai
 * @date 25/06/2024
 * @description Measures CPU usage
 */

public class CpuLimitsMeasure implements LimitMeasure {
    private Integer startCpu;
    public CpuLimitsMeasure() {
        this.startCpu = Limits.getCpuTime();
    }

    public Integer getResult() {
        return Limits.getCpuTime() - startCpu;
    }
}
