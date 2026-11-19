<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.BusinessException" %>
<%@ page import="garaman.dao.InvoiceDAO" %>
<%@ page import="garaman.model.Invoice" %>
<%@ page import="garaman.model.InvoiceDetail" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * invoiceConfirmation.jsp (Hình 3.5, Hình 3.6, Bảng 3.6)
     *   outInvoiceTemplate: output; subConfirmButton: submit; subBackButton: link
     *   ẩn: invoiceId, invoice, loggedInStaff
     *   loadPreview(id); confirmInvoice(); backToInvoice()
     */

    private static final String MSG_ERROR = "Không thực hiện được thao tác, vui lòng thử lại";

    /**
     * Bước 73-78: gọi InvoiceDAO.getById() để hiển thị hóa đơn theo mẫu chuẩn.
     * Không ghi đè thông báo đã có (ví dụ lỗi chốt hóa đơn vừa xảy ra).
     */
    private void loadPreview(HttpServletRequest request, Long id) {
        request.removeAttribute("invoice");
        if (id == null) {
            showMessageIfNone(request, "Hóa đơn không tồn tại");
            return;
        }
        try {
            InvoiceDAO invoiceDAO = new InvoiceDAO(DBConnection.getDataSource());
            Optional<Invoice> invoice = invoiceDAO.getById(id);
            if (invoice.isEmpty()) {
                showMessageIfNone(request, "Hóa đơn không tồn tại");
                return;
            }
            request.setAttribute("invoice", invoice.get());
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDAO.getById() thất bại", e);
            showMessageIfNone(request, MSG_ERROR);
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
            showMessage(request, MSG_ERROR);
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

    private void showMessageIfNone(HttpServletRequest request, String message) {
        if (request.getAttribute("message") == null) {
            showMessage(request, message);
        }
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    if (!requireSalesStaff(request, response)) return;

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
        if (redirected(response)) return;
    }
    loadPreview(request, invoiceId);

    // render()
    Invoice invoice = (Invoice) request.getAttribute("invoice");
    String message = (String) request.getAttribute("message");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Xác nhận hóa đơn</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/view/css/style.css">
    <style>
        .panel { max-width: 560px; }
        .panel p { margin: 6px 0; }
        table { margin-top: 10px; }
        .btn { font-family: inherit; }
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
        <a id="subBackButton" class="btn" href="invoiceConfirmation.jsp?action=backToInvoice&amp;invoiceId=<%= idOrEmpty(invoiceId) %>">Quay lại</a>
    </div>
</div>
</body>
</html>
