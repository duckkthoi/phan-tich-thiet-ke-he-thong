<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.CustomerDAO" %>
<%@ page import="garaman.dao.InvoiceDAO" %>
<%@ page import="garaman.model.Customer" %>
<%@ page import="garaman.model.Invoice" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * customerSearch.jsp (Hình 3.5, Hình 3.6, Bảng 3.6)
     *   inCustomerName; subSearch; outCustomerList; outUnpaidInvoiceList
     *   ẩn: customerName, customers, selectedCustomerId, unpaidInvoices, selectedInvoiceId
     *   searchCustomers(name); loadUnpaidInvoices(customerId); openInvoice(invoiceId)
     * Thuộc tính ẩn được giữ trong phiên của nhân viên để quay lại trang không mất danh sách.
     */
    private static final String A_NAME = "customerSearch.customerName";
    private static final String A_CUSTOMERS = "customerSearch.customers";
    private static final String A_CUSTOMER_ID = "customerSearch.selectedCustomerId";
    private static final String A_INVOICES = "customerSearch.unpaidInvoices";
    private static final String A_INVOICE_ID = "customerSearch.selectedInvoiceId";

    private static final String MSG_ERROR = "Không thực hiện được thao tác, vui lòng thử lại";
    private static final String MSG_NO_CUSTOMER = "Không tìm thấy khách hàng";

    /** Bước 6-13: chuẩn hóa, kiểm tra tên rồi gọi CustomerDAO.searchCustomer(). */
    private void searchCustomers(HttpServletRequest request, HttpSession session, String name) {
        name = name == null ? "" : name.trim();
        session.setAttribute(A_NAME, name);
        session.removeAttribute(A_CUSTOMERS);
        session.removeAttribute(A_CUSTOMER_ID);
        session.removeAttribute(A_INVOICES);
        session.removeAttribute(A_INVOICE_ID);
        if (name.isEmpty()) {
            showMessage(request, "Vui lòng nhập tên khách hàng");
            return;
        }
        try {
            CustomerDAO customerDAO = new CustomerDAO(DBConnection.getDataSource());
            List<Customer> customers = customerDAO.searchCustomer(name);
            session.setAttribute(A_CUSTOMERS, customers);
            if (customers.isEmpty()) {
                // 12.1
                showMessage(request, MSG_NO_CUSTOMER);
            }
        } catch (SQLException e) {
            // 7.1
            log("CustomerDAO.searchCustomer() thất bại", e);
            showMessage(request, MSG_ERROR);
        }
    }

    /** Bước 15-22: lưu selectedCustomerId và gọi InvoiceDAO.getUnpaidInvoice(). */
    @SuppressWarnings("unchecked")
    private void loadUnpaidInvoices(HttpServletRequest request, HttpSession session, Long customerId) {
        session.removeAttribute(A_INVOICES);
        session.removeAttribute(A_INVOICE_ID);
        // Chỉ chấp nhận khách hàng có trong kết quả tìm kiếm hiện tại
        List<Customer> customers = (List<Customer>) session.getAttribute(A_CUSTOMERS);
        boolean listed = customerId != null && customers != null
                && customers.stream().anyMatch(c -> customerId.equals(c.getId()));
        if (!listed) {
            session.removeAttribute(A_CUSTOMER_ID);
            showMessage(request, MSG_NO_CUSTOMER);
            return;
        }
        session.setAttribute(A_CUSTOMER_ID, customerId);
        try {
            InvoiceDAO invoiceDAO = new InvoiceDAO(DBConnection.getDataSource());
            List<Invoice> unpaidInvoices = invoiceDAO.getUnpaidInvoice(customerId);
            session.setAttribute(A_INVOICES, unpaidInvoices);
            if (unpaidInvoices.isEmpty()) {
                // 21.1
                showMessage(request, "Khách hàng không có hóa đơn cần thanh toán");
            }
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDAO.getUnpaidInvoice() thất bại", e);
            showMessage(request, MSG_ERROR);
        }
    }

    /** Bước 24-25: kiểm tra hóa đơn thuộc khách hàng đang chọn rồi gọi invoiceDetail.jsp. */
    @SuppressWarnings("unchecked")
    private void openInvoice(HttpServletRequest request, HttpServletResponse response, HttpSession session,
                             Long invoiceId) throws java.io.IOException {
        List<Invoice> unpaidInvoices = (List<Invoice>) session.getAttribute(A_INVOICES);
        boolean listed = invoiceId != null && unpaidInvoices != null
                && unpaidInvoices.stream().anyMatch(inv -> invoiceId.equals(inv.getId()));
        if (!listed) {
            showMessage(request, "Hóa đơn không thuộc khách hàng đang chọn");
            return;
        }
        session.setAttribute(A_INVOICE_ID, invoiceId);
        response.sendRedirect("invoiceDetail.jsp?invoiceId=" + invoiceId);
    }

    /** showMessage(message): thông báo cho nhân viên. */
    private void showMessage(HttpServletRequest request, String message) {
        request.setAttribute("message", message);
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    if (!requireSalesStaff(request, response)) return;

    String action = request.getParameter("action");
    if (request.getParameter("subSearch") != null) {
        // Bước 5-6: submit gọi chính trang này -> searchCustomers(name)
        searchCustomers(request, session, request.getParameter("customerName"));
    } else if ("loadUnpaidInvoices".equals(action)) {
        // Bước 14-15: chọn khách hàng theo mã -> loadUnpaidInvoices(customerId)
        loadUnpaidInvoices(request, session, parseId(request.getParameter("customerId")));
        @SuppressWarnings("unchecked")
        List<Invoice> loaded = (List<Invoice>) session.getAttribute(A_INVOICES);
        if (loaded != null && loaded.size() == 1) {
            // Bước 23: khách chỉ có một hóa đơn -> hệ thống chọn trực tiếp
            openInvoice(request, response, session, loaded.get(0).getId());
            return;
        }
    } else if ("openInvoice".equals(action)) {
        // Bước 23-24: chọn hóa đơn -> openInvoice(invoiceId)
        openInvoice(request, response, session, parseId(request.getParameter("invoiceId")));
        if (redirected(response)) return;
    } else if (session.getAttribute(A_CUSTOMER_ID) != null) {
        // Quay lại từ invoiceDetail.jsp: đọc lại danh sách hóa đơn chưa thanh toán của khách đang chọn
        loadUnpaidInvoices(request, session, (Long) session.getAttribute(A_CUSTOMER_ID));
    }

    // render()
    String customerName = (String) session.getAttribute(A_NAME);
    @SuppressWarnings("unchecked")
    List<Customer> customers = (List<Customer>) session.getAttribute(A_CUSTOMERS);
    Long selectedCustomerId = (Long) session.getAttribute(A_CUSTOMER_ID);
    @SuppressWarnings("unchecked")
    List<Invoice> unpaidInvoices = (List<Invoice>) session.getAttribute(A_INVOICES);
    String message = (String) request.getAttribute("message");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Tìm khách hàng</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/view/css/style.css">
    <style>
        .panel { max-width: 560px; }
        .btn { margin: 8px 0; }
    </style>
</head>
<body>
<div class="panel">
    <h2>TÌM KHÁCH HÀNG</h2>

    <form method="get" action="customerSearch.jsp">
        <div class="search-row">
            <label for="inCustomerName">Tên khách hàng:</label>
            <input type="text" id="inCustomerName" name="customerName" value="<%= esc(customerName) %>">
        </div>
        <button type="submit" id="subSearch" name="subSearch" value="1" class="btn">Tìm kiếm</button>
    </form>

    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>

    <% if (customers != null && !customers.isEmpty()) { %>
    <h3>Danh sách khách hàng</h3>
    <table id="outCustomerList">
        <thead>
        <tr><th>Mã</th><th>Họ tên</th><th>Điện thoại</th><th>Chọn</th></tr>
        </thead>
        <tbody>
        <% for (Customer c : customers) { %>
        <tr>
            <td><%= esc(customerCode(c.getId())) %></td>
            <td><%= esc(c.getFullName()) %></td>
            <td><%= esc(c.getPhone()) %></td>
            <td><a href="customerSearch.jsp?action=loadUnpaidInvoices&amp;customerId=<%= c.getId() %>">Chọn</a></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <% } %>

    <% if (selectedCustomerId != null && unpaidInvoices != null && !unpaidInvoices.isEmpty()) { %>
    <h3>Hóa đơn cần thanh toán của <%= esc(customerCode(selectedCustomerId)) %></h3>
    <table id="outUnpaidInvoiceList">
        <thead>
        <tr><th>Mã HĐ</th><th>Ngày lập</th><th>Trạng thái</th><th>Chọn</th></tr>
        </thead>
        <tbody>
        <% for (Invoice inv : unpaidInvoices) { %>
        <tr>
            <td><%= esc(invoiceCode(inv.getId())) %></td>
            <td><%= esc(formatDate(inv.getCreatedDate())) %></td>
            <td><%= esc(statusLabel(inv.getStatus())) %></td>
            <td><a href="customerSearch.jsp?action=openInvoice&amp;invoiceId=<%= inv.getId() %>">Chọn</a></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <% } %>

    <a class="btn" href="salesStaffMain.jsp">Về trang chủ</a>
</div>
</body>
</html>
