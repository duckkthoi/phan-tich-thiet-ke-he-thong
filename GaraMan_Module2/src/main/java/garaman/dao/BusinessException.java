package garaman.dao;

/**
 * Lỗi nghiệp vụ do DAO ném ra sau khi rollback giao dịch (kịch bản 60.1, 82.1, 93.1):
 * vượt tồn kho, hóa đơn không ở trạng thái hợp lệ... Thông điệp được hiển thị cho người dùng.
 */
public class BusinessException extends Exception {

    private static final long serialVersionUID = 1L;

    public BusinessException(String message) {
        super(message);
    }
}
