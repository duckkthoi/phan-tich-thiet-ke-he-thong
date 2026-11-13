<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.BusinessException" %>
<%@ page import="garaman.dao.InvoiceDAO" %>
<%@ page import="garaman.model.Invoice" %>
<%@ page import="garaman.model.InvoiceDetail" %>
<%@ page import="garaman.model.Item" %>
<%@ page import="garaman.model.SalesStaff" %>
<%@ page import="garaman.model.Service" %>
<%!
    /*
     * invoiceDetail.jsp (Hình 4.6, Hình 4.7, Bảng 4.6, Bảng 4.7)
     *   outCustomerInfo; outInvoiceDate; outInvoiceDetailList; outTotalAmount;
     *   subAddButton: link; subConfirmInvoiceButton: link; subConfirmPaymentButton: submit; subPrintButton: submit
     *   ẩn: invoiceId, invoice, loggedInStaff, message
     *   loadInvoice(id); openAddItem(); openConfirmation(); confirmPayment(); printInvoice()
     * Nút được bật theo trạng thái (Bảng 4.7); máy chủ vẫn kiểm tra lại quyền và trạng thái ở từng yêu cầu.
     */

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
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
    }

    /** Bước 45-46: kiểm tra hóa đơn đang ở trạng thái DRAFT rồi gọi addItem.jsp, truyền invoiceId. */
    private void openAddItem(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        loadInvoice(request, invoiceId);
        Invoice invoice = (Invoice) request.getAttribute("invoice");
        if (invoice != null && Invoice.DRAFT.equals(invoice.getStatus())) {
            response.sendRedirect("addItem.jsp?invoiceId=" + invoiceId);
        } else if (invoice != null) {
            showMessage(request, "Hóa đơn không còn ở trạng thái chưa chốt, không thể bổ sung");
        }
    }

    /** Bước 72-73: kiểm tra DRAFT rồi gọi invoiceConfirmation.jsp (loadPreview(invoiceId)). */
    private void openConfirmation(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        loadInvoice(request, invoiceId);
        Invoice invoice = (Invoice) request.getAttribute("invoice");
        if (invoice != null && Invoice.DRAFT.equals(invoice.getStatus())) {
            response.sendRedirect("invoiceConfirmation.jsp?invoiceId=" + invoiceId);
        } else if (invoice != null) {
            showMessage(request, "Hóa đơn không còn ở trạng thái chưa chốt, không thể xác nhận hóa đơn");
        }
    }

    /**
     * Bước 91-97: lấy paymentDate theo đồng hồ máy chủ, gọi InvoiceDAO.confirmPayment().
     * 93.2: lỗi → thông báo và tải lại hóa đơn.
     */
    private void confirmPayment(HttpServletRequest request) {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        LocalDateTime paymentDate = LocalDateTime.now();
        try {
            InvoiceDAO invoiceDAO = new InvoiceDAO(DBConnection.getDataSource());
            invoiceDAO.confirmPayment(invoiceId, paymentDate);
            showMessage(request, "Thanh toán thành công");
        } catch (BusinessException e) {
            showMessage(request, e.getMessage());
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDAO.confirmPayment() thất bại", e);
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
        loadInvoice(request, invoiceId);
    }

    /** Bước 99-102: đọc lại hóa đơn, kiểm tra PAID và dựng mẫu in. */
    private void printInvoice(HttpServletRequest request) {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        loadInvoice(request, invoiceId);
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

    private static SalesStaff loggedInStaff(HttpSession session) {
        Object staff = session == null ? null : session.getAttribute("loggedInStaff");
        if (staff instanceof SalesStaff && SalesStaff.POSITION.equals(((SalesStaff) staff).getPosition())) {
            return (SalesStaff) staff;
        }
        return null;
    }

    private static Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static String esc(Object value) {
        if (value == null) return "";
        String s = value.toString();
        StringBuilder sb = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '&': sb.append("&amp;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }

    /** Mã hiển thị theo Hình 4.6. */
    private static String invoiceCode(Long id) {
        return "HD" + String.format("%03d", id);
    }

    private static String customerCode(Long id) {
        return "KH" + String.format("%02d", id);
    }

    private static String itemCode(Item item) {
        return (item instanceof Service ? "DV" : "PT") + String.format("%02d", item.getId());
    }

    private static String itemType(Item item) {
        return item instanceof Service ? "Dịch vụ" : "Phụ tùng";
    }

    private static String statusLabel(String status) {
        if (Invoice.DRAFT.equals(status)) return "Chưa chốt";
        if (Invoice.CONFIRMED.equals(status)) return "Đã chốt, chưa thanh toán";
        if (Invoice.PAID.equals(status)) return "Đã thanh toán";
        return status;
    }

    private static String formatDate(LocalDateTime dateTime) {
        return dateTime == null ? "" : dateTime.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }

    private static String formatMoney(BigDecimal amount) {
        if (amount == null) return "";
        DecimalFormatSymbols symbols = new DecimalFormatSymbols();
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        return new DecimalFormat("#,##0", symbols).format(amount);
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    if (loggedInStaff(session) == null) {
        // Phiên hết hạn: yêu cầu đăng nhập lại trước mọi thao tác
        response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
        return;
    }
    Long invoiceId = parseId(request.getParameter("invoiceId"));
    request.setAttribute("invoiceId", invoiceId);
    String action = request.getParameter("action");
    boolean post = "POST".equalsIgnoreCase(request.getMethod());

    if ("openAddItem".equals(action)) {
        // Bước 44-45: click Bổ sung -> openAddItem()
        openAddItem(request, response);
        if (response.containsHeader("Location")) return;
    } else if ("openConfirmation".equals(action)) {
        // Bước 71-72: click Xác nhận hóa đơn -> openConfirmation()
        openConfirmation(request, response);
        if (response.containsHeader("Location")) return;
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
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 640px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .panel p { margin: 6px 0; }
        .row { display: flex; justify-content: space-between; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #333; padding: 3px 6px; text-align: left; vertical-align: top; }
        .total { text-align: right; font-weight: bold; margin: 10px 0; }
        .actions { display: flex; justify-content: space-between; margin-top: 12px; }
        .btn { display: inline-block; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; font-family: inherit; }
        .btn.disabled, .btn[disabled] { border-color: #bbb; background: #eee; color: #999; cursor: default; }
        form { margin: 0; }
        .gara { text-align: center; font-weight: bold; margin: 8px 0 12px; }
        .message { margin: 12px 0; padding: 6px 10px; border: 1px solid #c9a227; background: #fff8dc; }
        @media print {
            .no-print { display: none; }
            .panel { border: none; }
        }
    </style>
</head>
<body>
<% if (printMode && invoice != null) { %>
<%-- Mẫu in hóa đơn (Hình 4.6: HÓA ĐƠN THANH TOÁN) --%>
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
