/**
 * @author aidan@processity.ai
 * @date 25/06/2024
 * @description Measures CPU usage
 */

public class LimitsMeasure {

    private Integer startCpu;

    public LimitsMeasure() {
        this.startCpu = Limits.getCpuTime();
    }
    
    public Integer getResult() {
        return Limits.getCpuTime() - startCpu;
    }
}