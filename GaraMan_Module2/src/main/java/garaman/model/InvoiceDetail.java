package garaman.model;

import java.math.BigDecimal;

/**
 * Lớp thực thể InvoiceDetail (Hình 4.7). subtotal là thuộc tính dẫn xuất, không lưu:
 * tính bằng calculateSubtotal() = quantity × unitPrice.
 */
public class InvoiceDetail {

    private Long id;
    private Integer quantity;
    private BigDecimal unitPrice;
    private Invoice invoice;
    private Item item;
    private Technician technician;

    public InvoiceDetail() {
    }

    /** Thành tiền của dòng, tính từ đơn giá đã lưu trên dòng, không truy cập CSDL. */
    public BigDecimal calculateSubtotal() {
        if (quantity == null || unitPrice == null) {
            return BigDecimal.ZERO;
        }
        return unitPrice.multiply(BigDecimal.valueOf(quantity.longValue()));
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }

    public Invoice getInvoice() {
        return invoice;
    }

    public void setInvoice(Invoice invoice) {
        this.invoice = invoice;
    }

    public Item getItem() {
        return item;
    }

    public void setItem(Item item) {
        this.item = item;
    }

    public Technician getTechnician() {
        return technician;
    }

    public void setTechnician(Technician technician) {
        this.technician = technician;
    }
}
