package garaman.model;

/**
 * Lớp thực thể trừu tượng Staff kế thừa Member (Hình 3.6).
 */
public abstract class Staff extends Member {

    private String position;

    public Staff() {
    }

    public String getPosition() {
        return position;
    }

    public void setPosition(String position) {
        this.position = position;
    }
}
