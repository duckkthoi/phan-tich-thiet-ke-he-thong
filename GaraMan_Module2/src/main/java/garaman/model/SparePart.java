package garaman.model;

/**
 * Lớp thực thể SparePart kế thừa Item (Hình 4.7).
 */
public class SparePart extends Item {

    private Integer quantityInStock;

    public SparePart() {
    }

    public Integer getQuantityInStock() {
        return quantityInStock;
    }

    public void setQuantityInStock(Integer quantityInStock) {
        this.quantityInStock = quantityInStock;
    }
}
