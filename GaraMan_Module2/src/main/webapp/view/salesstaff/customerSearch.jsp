<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.CustomerDAO" %>
<%@ page import="garaman.dao.InvoiceDAO" %>
<%@ page import="garaman.model.Customer" %>
<%@ page import="garaman.model.Invoice" %>
<%@ page import="garaman.model.SalesStaff" %>
<%!
    /*
     * customerSearch.jsp (Hình 4.6, Hình 4.7, Bảng 4.6)
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
                showMessage(request, "Không tìm thấy khách hàng");
            }
        } catch (SQLException e) {
            // 7.1
            log("CustomerDAO.searchCustomer() thất bại", e);
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
    }

    /** Bước 15-22: lưu selectedCustomerId và gọi InvoiceDAO.getUnpaidInvoice(). */
    @SuppressWarnings("unchecked")
    private void loadUnpaidInvoices(HttpServletRequest request, HttpSession session, Long customerId) {
        session.removeAttribute(A_INVOICES);
        session.removeAttribute(A_INVOICE_ID);
        List<Customer> customers = (List<Customer>) session.getAttribute(A_CUSTOMERS);
        boolean listed = false;
        if (customers != null && customerId != null) {
            for (Customer c : customers) {
                if (customerId.equals(c.getId())) {
                    listed = true;
                    break;
                }
            }
        }
        if (!listed) {
            session.removeAttribute(A_CUSTOMER_ID);
            showMessage(request, "Không tìm thấy khách hàng");
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
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
    }

    /** Bước 24-25: kiểm tra hóa đơn thuộc khách hàng đang chọn rồi gọi invoiceDetail.jsp. */
    @SuppressWarnings("unchecked")
    private void openInvoice(HttpServletRequest request, HttpServletResponse response, HttpSession session,
                             Long invoiceId) throws java.io.IOException {
        List<Invoice> unpaidInvoices = (List<Invoice>) session.getAttribute(A_INVOICES);
        if (unpaidInvoices != null && invoiceId != null) {
            for (Invoice invoice : unpaidInvoices) {
                if (invoiceId.equals(invoice.getId())) {
                    session.setAttribute(A_INVOICE_ID, invoiceId);
                    response.sendRedirect("invoiceDetail.jsp?invoiceId=" + invoiceId);
                    return;
                }
            }
        }
        showMessage(request, "Hóa đơn không thuộc khách hàng đang chọn");
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

    /** Mã hiển thị theo Hình 4.6: KH + id (khách hàng), HD + id (hóa đơn). */
    private static String customerCode(Long id) {
        return "KH" + String.format("%02d", id);
    }

    private static String invoiceCode(Long id) {
        return "HD" + String.format("%03d", id);
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
%>
<%
    request.setCharacterEncoding("UTF-8");
    if (loggedInStaff(session) == null) {
        response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
        return;
    }

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
        if (response.containsHeader("Location")) {
            return;
        }
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
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 560px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .search-row { display: flex; align-items: center; gap: 8px; }
        .search-row input { flex: 1; padding: 4px 6px; font-size: 14px; }
        .btn { display: inline-block; margin: 8px 0; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; }
        h3 { font-size: 14px; margin: 16px 0 6px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #333; padding: 3px 6px; text-align: left; vertical-align: top; }
        .message { margin: 12px 0; padding: 6px 10px; border: 1px solid #c9a227; background: #fff8dc; }
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
