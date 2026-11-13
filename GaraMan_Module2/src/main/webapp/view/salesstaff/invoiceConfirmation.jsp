<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.BusinessException" %>
<%@ page import="garaman.dao.InvoiceDAO" %>
<%@ page import="garaman.model.Invoice" %>
<%@ page import="garaman.model.InvoiceDetail" %>
<%@ page import="garaman.model.SalesStaff" %>
<%!
    /*
     * invoiceConfirmation.jsp (Hình 4.6, Hình 4.7, Bảng 4.6)
     *   outInvoiceTemplate: output; subConfirmButton: submit; subBackButton: link
     *   ẩn: invoiceId, invoice, loggedInStaff
     *   loadPreview(id); confirmInvoice(); backToInvoice()
     */

    /** Bước 73-78: gọi InvoiceDAO.getById() để hiển thị hóa đơn theo mẫu chuẩn. */
    private void loadPreview(HttpServletRequest request, Long id) {
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

    /**
     * Bước 80-86: gọi InvoiceDAO.confirmInvoice(); thành công → gọi lại invoiceDetail.jsp (loadInvoice).
     * 82.2: BusinessException → thông báo rõ mặt hàng thiếu, hóa đơn vẫn DRAFT.
     */
    private void confirmInvoice(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        try {
            InvoiceDAO invoiceDAO = new InvoiceDAO(DBConnection.getDataSource());
            invoiceDAO.confirmInvoice(invoiceId);
            response.sendRedirect("invoiceDetail.jsp?invoiceId=" + invoiceId);
        } catch (BusinessException e) {
            showMessage(request, e.getMessage());
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDAO.confirmInvoice() thất bại", e);
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
    }

    /** 78.1-78.2: nút Quay lại → về invoiceDetail.jsp, hóa đơn vẫn DRAFT. */
    private void backToInvoice(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        response.sendRedirect("invoiceDetail.jsp?invoiceId=" + request.getAttribute("invoiceId"));
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

    private static String invoiceCode(Long id) {
        return "HD" + String.format("%03d", id);
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
        response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
        return;
    }
    Long invoiceId = parseId(request.getParameter("invoiceId"));
    request.setAttribute("invoiceId", invoiceId);
    String action = request.getParameter("action");

    if ("backToInvoice".equals(action)) {
        backToInvoice(request, response);
        return;
    }
    if ("POST".equalsIgnoreCase(request.getMethod()) && "confirmInvoice".equals(action)) {
        // Bước 79-80: click Xác nhận -> confirmInvoice()
        confirmInvoice(request, response);
        if (response.containsHeader("Location")) return;
    }
    String message = (String) request.getAttribute("message");
    loadPreview(request, invoiceId);
    if (message != null) {
        request.setAttribute("message", message);
    }

    // render()
    Invoice invoice = (Invoice) request.getAttribute("invoice");
    message = (String) request.getAttribute("message");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Xác nhận hóa đơn</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 560px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .panel p { margin: 6px 0; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #333; padding: 3px 6px; text-align: left; vertical-align: top; }
        .total { text-align: right; font-weight: bold; margin: 10px 0; }
        .actions { display: flex; justify-content: space-between; margin-top: 12px; }
        .btn { display: inline-block; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; font-family: inherit; }
        form { margin: 0; }
        .message { margin: 12px 0; padding: 6px 10px; border: 1px solid #c9a227; background: #fff8dc; }
    </style>
</head>
<body>
<div class="panel">
    <h2>XÁC NHẬN HÓA ĐƠN</h2>

    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>

    <% if (invoice != null) { %>
    <div id="outInvoiceTemplate">
        <p><b>Mã hóa đơn:</b> <%= esc(invoiceCode(invoice.getId())) %></p>
        <p><b>Khách hàng:</b> <%= esc(invoice.getCustomer().getFullName()) %></p>
        <p><b>Điện thoại:</b> <%= esc(invoice.getCustomer().getPhone()) %></p>
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
        <p class="total">Tổng tiền: <%= esc(formatMoney(invoice.calculateTotal())) %> đ</p>
        <p>Vui lòng đối chiếu đầy đủ nội dung hóa đơn với khách hàng trước khi xác nhận.</p>
    </div>
    <% } %>

    <div class="actions">
        <% if (invoice != null) { %>
        <form method="post" action="invoiceConfirmation.jsp">
            <input type="hidden" name="action" value="confirmInvoice">
            <input type="hidden" name="invoiceId" value="<%= invoice.getId() %>">
            <button type="submit" id="subConfirmButton" class="btn">Xác nhận</button>
        </form>
        <% } %>
        <a id="subBackButton" class="btn" href="invoiceConfirmation.jsp?action=backToInvoice&amp;invoiceId=<%= invoiceId == null ? "" : invoiceId %>">Quay lại</a>
    </div>
</div>
</body>
</html>
