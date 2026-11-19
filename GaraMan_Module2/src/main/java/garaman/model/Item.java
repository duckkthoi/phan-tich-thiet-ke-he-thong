package garaman.model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Lớp thực thể trừu tượng Item (Hình 3.6). Đối tượng được tạo luôn là Service hoặc SparePart.
 */
public abstract class Item {

    private Long id;
    private String name;
    private String description;
    private BigDecimal price;
    private List<InvoiceDetail> invoiceDetails = new ArrayList<>();

    public Item() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public List<InvoiceDetail> getInvoiceDetails() {
        return invoiceDetails;
    }

    public void setInvoiceDetails(List<InvoiceDetail> invoiceDetails) {
        this.invoiceDetails = invoiceDetails;
    }
}
