<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.BusinessException" %>
<%@ page import="garaman.dao.InvoiceDAO" %>
<%@ page import="garaman.model.Invoice" %>
<%@ page import="garaman.model.InvoiceDetail" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * invoiceDetail.jsp (Hình 3.5, Hình 3.6, Bảng 3.6, Bảng 3.7)
     *   outCustomerInfo; outInvoiceDate; outInvoiceDetailList; outTotalAmount;
     *   subAddButton: link; subConfirmInvoiceButton: link; subConfirmPaymentButton: submit; subPrintButton: submit
     *   ẩn: invoiceId, invoice, loggedInStaff, message
     *   loadInvoice(id); openAddItem(); openConfirmation(); confirmPayment(); printInvoice()
     * Nút được bật theo trạng thái (Bảng 3.7); máy chủ vẫn kiểm tra lại quyền và trạng thái ở từng yêu cầu.
     */

    private static final String MSG_ERROR = "Không thực hiện được thao tác, vui lòng thử lại";

    /** Bước 25-42: gọi InvoiceDAO.getById() và lưu invoice. */
    private void loadInvoice(HttpServletRequest request, Long id) {
        request.removeAttribute("invoice");
        if (id == null) {
            showMessage(request, "Hóa đơn không tồn tại");
            return;
        }
        try {
            InvoiceDAO invoiceDAO = new InvoiceDAO(DBConnection.getDataSource());
            Optional<Invoice> invoice = invoiceDAO.getById(id);
            if (invoice.isEmpty()) {
                showMessage(request, "Hóa đơn không tồn tại");
                return;
            }
            request.setAttribute("invoice", invoice.get());
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDAO.getById() thất bại", e);
            showMessage(request, MSG_ERROR);
        }
    }

    /** Bước 45-46: kiểm tra hóa đơn đang ở trạng thái DRAFT rồi gọi addItem.jsp, truyền invoiceId. */
    private void openAddItem(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        if (loadDraftInvoice(request, "Hóa đơn không còn ở trạng thái chưa chốt, không thể bổ sung")) {
            response.sendRedirect("addItem.jsp?invoiceId=" + request.getAttribute("invoiceId"));
        }
    }

    /** Bước 72-73: kiểm tra DRAFT rồi gọi invoiceConfirmation.jsp (loadPreview(invoiceId)). */
    private void openConfirmation(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        if (loadDraftInvoice(request, "Hóa đơn không còn ở trạng thái chưa chốt, không thể xác nhận hóa đơn")) {
            response.sendRedirect("invoiceConfirmation.jsp?invoiceId=" + request.getAttribute("invoiceId"));
        }
    }

    /**
     * Đọc lại hóa đơn từ CSDL; trả về true nếu hóa đơn đang ở DRAFT,
     * ngược lại hiển thị rejectMessage (hóa đơn đã đổi trạng thái) và trả về false.
     */
    private boolean loadDraftInvoice(HttpServletRequest request, String rejectMessage) {
        loadInvoice(request, (Long) request.getAttribute("invoiceId"));
        Invoice invoice = (Invoice) request.getAttribute("invoice");
        if (invoice == null) {
            return false;
        }
        if (!Invoice.DRAFT.equals(invoice.getStatus())) {
            showMessage(request, rejectMessage);
            return false;
        }
        return true;
    }

    /**
     * Bước 91-97: lấy paymentDate theo đồng hồ máy chủ, gọi InvoiceDAO.confirmPayment().
     * 93.2: lỗi → thông báo và tải lại hóa đơn.
     */
    private void confirmPayment(HttpServletRequest request) {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        try {
            InvoiceDAO invoiceDAO = new InvoiceDAO(DBConnection.getDataSource());
            invoiceDAO.confirmPayment(invoiceId, LocalDateTime.now());
            showMessage(request, "Thanh toán thành công");
        } catch (BusinessException e) {
            showMessage(request, e.getMessage());
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDAO.confirmPayment() thất bại", e);
            showMessage(request, MSG_ERROR);
        }
        loadInvoice(request, invoiceId);
    }

    /** Bước 99-102: đọc lại hóa đơn, kiểm tra PAID và dựng mẫu in. */
    private void printInvoice(HttpServletRequest request) {
        loadInvoice(request, (Long) request.getAttribute("invoiceId"));
        Invoice invoice = (Invoice) request.getAttribute("invoice");
        if (invoice == null) {
            return;
        }
        if (!Invoice.PAID.equals(invoice.getStatus())) {
            showMessage(request, "Hóa đơn chưa thanh toán, không thể in hóa đơn");
            return;
        }
        request.setAttribute("printMode", Boolean.TRUE);
    }

    /** showMessage(message): thông báo cho nhân viên. */
    private void showMessage(HttpServletRequest request, String message) {
        request.setAttribute("message", message);
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    // Phiên hết hạn: yêu cầu đăng nhập lại trước mọi thao tác
    if (!requireSalesStaff(request, response)) return;

    Long invoiceId = parseId(request.getParameter("invoiceId"));
    request.setAttribute("invoiceId", invoiceId);
    String action = request.getParameter("action");
    boolean post = "POST".equalsIgnoreCase(request.getMethod());

    if ("openAddItem".equals(action)) {
        // Bước 44-45: click Bổ sung -> openAddItem()
        openAddItem(request, response);
        if (redirected(response)) return;
    } else if ("openConfirmation".equals(action)) {
        // Bước 71-72: click Xác nhận hóa đơn -> openConfirmation()
        openConfirmation(request, response);
        if (redirected(response)) return;
    } else if (post && "confirmPayment".equals(action)) {
        // Bước 90-91: click Xác nhận thanh toán -> confirmPayment()
        confirmPayment(request);
    } else if (post && "printInvoice".equals(action)) {
        // Bước 98-99: click In hóa đơn -> printInvoice()
        printInvoice(request);
    } else {
        loadInvoice(request, invoiceId);
    }

    // render()
    Invoice invoice = (Invoice) request.getAttribute("invoice");
    String message = (String) request.getAttribute("message");
    boolean printMode = Boolean.TRUE.equals(request.getAttribute("printMode"));
    String status = invoice == null ? null : invoice.getStatus();
    // Quyền thao tác theo trạng thái hóa đơn (Bảng 3.7)
    boolean canAdd = Invoice.DRAFT.equals(status);
    boolean canConfirmInvoice = Invoice.DRAFT.equals(status);
    boolean canConfirmPayment = Invoice.CONFIRMED.equals(status);
    boolean canPrint = Invoice.PAID.equals(status);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - <%= printMode ? "Hóa đơn thanh toán" : "Chi tiết hóa đơn" %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/view/css/style.css">
    <style>
        .panel { max-width: 640px; }
        .panel p { margin: 6px 0; }
        .row { display: flex; justify-content: space-between; }
        table { margin-top: 10px; }
        .btn { font-family: inherit; }
        .gara { text-align: center; font-weight: bold; margin: 8px 0 12px; }
        @media print {
            .no-print { display: none; }
            .panel { border: none; }
        }
    </style>
</head>
<body>
<% if (printMode && invoice != null) { %>
<%-- Mẫu in hóa đơn (Hình 3.5: HÓA ĐƠN THANH TOÁN) --%>
<div class="panel">
    <h2>HÓA ĐƠN THANH TOÁN</h2>
    <div class="gara">GARA Ô TÔ GARAMAN</div>
    <p><b>Mã hóa đơn:</b> <%= esc(invoiceCode(invoice.getId())) %></p>
    <p><b>Khách hàng:</b> <%= esc(invoice.getCustomer().getFullName()) %></p>
    <p><b>Ngày thanh toán:</b> <%= esc(formatDate(invoice.getPaymentDate())) %></p>
    <p><b>Trạng thái: ĐÃ THANH TOÁN</b></p>
    <table>
        <thead>
        <tr><th>Nội dung</th><th>SL</th><th>Đơn giá</th><th>Thành tiền</th></tr>
        </thead>
        <tbody>
        <% for (InvoiceDetail d : invoice.getDetails()) { %>
        <tr>
            <td><%= esc(d.getItem().getName()) %></td>
            <td><%= d.getQuantity() %></td>
            <td><%= esc(formatMoney(d.getUnitPrice())) %></td>
            <td><%= esc(formatMoney(d.calculateSubtotal())) %></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <p class="total">Tổng thanh toán: <%= esc(formatMoney(invoice.calculateTotal())) %> đ</p>
    <div class="actions no-print">
        <button type="button" class="btn" onclick="window.print()">In</button>
        <a class="btn" href="invoiceDetail.jsp?invoiceId=<%= invoice.getId() %>">Đóng</a>
    </div>
</div>
<% } else { %>
<div class="panel">
    <h2>CHI TIẾT HÓA ĐƠN</h2>

    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>

    <% if (invoice != null) { %>
    <div id="outCustomerInfo">
        <div class="row">
            <p><b>Mã hóa đơn:</b> <%= esc(invoiceCode(invoice.getId())) %></p>
            <p id="outInvoiceDate"><b>Ngày lập:</b> <%= esc(formatDate(invoice.getCreatedDate())) %></p>
        </div>
        <div class="row">
            <p><b>Khách hàng:</b> <%= esc(invoice.getCustomer().getFullName()) %></p>
            <p><b>Mã KH:</b> <%= esc(customerCode(invoice.getCustomer().getId())) %></p>
        </div>
        <p><b>Điện thoại:</b> <%= esc(invoice.getCustomer().getPhone()) %></p>
        <p><b>Địa chỉ:</b> <%= esc(invoice.getCustomer().getAddress()) %></p>
        <p><b>Trạng thái:</b> <%= esc(statusLabel(invoice.getStatus())) %></p>
    </div>

    <table id="outInvoiceDetailList">
        <thead>
        <tr><th>Mã</th><th>Tên dịch vụ/phụ tùng</th><th>Loại</th><th>SL</th><th>Đơn giá</th><th>Thành tiền</th></tr>
        </thead>
        <tbody>
        <% for (InvoiceDetail d : invoice.getDetails()) { %>
        <tr>
            <td><%= esc(itemCode(d.getItem())) %></td>
            <td><%= esc(d.getItem().getName()) %></td>
            <td><%= esc(itemType(d.getItem())) %></td>
            <td><%= d.getQuantity() %></td>
            <td><%= esc(formatMoney(d.getUnitPrice())) %></td>
            <td><%= esc(formatMoney(d.calculateSubtotal())) %></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <p id="outTotalAmount" class="total">Tổng tiền: <%= esc(formatMoney(invoice.calculateTotal())) %> đ</p>

    <div class="actions">
        <% if (canAdd) { %>
        <a id="subAddButton" class="btn" href="invoiceDetail.jsp?action=openAddItem&amp;invoiceId=<%= invoice.getId() %>">Bổ sung</a>
        <% } else { %>
        <span id="subAddButton" class="btn disabled">Bổ sung</span>
        <% } %>
        <% if (canConfirmInvoice) { %>
        <a id="subConfirmInvoiceButton" class="btn" href="invoiceDetail.jsp?action=openConfirmation&amp;invoiceId=<%= invoice.getId() %>">Xác nhận hóa đơn</a>
        <% } else { %>
        <span id="subConfirmInvoiceButton" class="btn disabled">Xác nhận hóa đơn</span>
        <% } %>
    </div>
    <div class="actions">
        <form method="post" action="invoiceDetail.jsp">
            <input type="hidden" name="action" value="confirmPayment">
            <input type="hidden" name="invoiceId" value="<%= invoice.getId() %>">
            <button type="submit" id="subConfirmPaymentButton" class="btn"<%= canConfirmPayment ? "" : " disabled" %>>Xác nhận thanh toán</button>
        </form>
        <form method="post" action="invoiceDetail.jsp">
            <input type="hidden" name="action" value="printInvoice">
            <input type="hidden" name="invoiceId" value="<%= invoice.getId() %>">
            <button type="submit" id="subPrintButton" class="btn"<%= canPrint ? "" : " disabled" %>>In hóa đơn</button>
        </form>
    </div>
    <% } %>

    <div class="actions">
        <a class="btn" href="customerSearch.jsp">Quay lại</a>
    </div>
</div>
<% } %>
</body>
</html>
