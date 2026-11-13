package garaman.model;

/**
 * Lớp thực thể Service kế thừa Item (Hình 4.7).
 */
public class Service extends Item {

    private Integer estimatedDuration;

    public Service() {
    }

    public Integer getEstimatedDuration() {
        return estimatedDuration;
    }

    public void setEstimatedDuration(Integer estimatedDuration) {
        this.estimatedDuration = estimatedDuration;
    }
}
