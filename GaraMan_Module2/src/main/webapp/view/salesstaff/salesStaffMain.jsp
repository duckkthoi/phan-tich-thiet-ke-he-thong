<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="garaman.model.SalesStaff" %>
<%!
    /*
     * salesStaffMain.jsp (Hình 4.6, Hình 4.7, Bảng 4.6)
     *   subPaymentMenu: link; ẩn: loggedInStaff: SalesStaff
     *   openPayment(): void -> kiểm tra phiên và quyền SalesStaff, mở trang tìm khách hàng
     */

    /** Bước 2-3: kiểm tra phiên đăng nhập và quyền SalesStaff của loggedInStaff rồi gọi customerSearch.jsp. */
    private void openPayment(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws java.io.IOException {
        if (loggedInStaff(session) == null) {
            response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
            return;
        }
        // Mở phiên tìm kiếm mới: xóa thuộc tính ẩn của lần tìm trước
        session.removeAttribute("customerSearch.customerName");
        session.removeAttribute("customerSearch.customers");
        session.removeAttribute("customerSearch.selectedCustomerId");
        session.removeAttribute("customerSearch.unpaidInvoices");
        session.removeAttribute("customerSearch.selectedInvoiceId");
        response.sendRedirect(request.getContextPath() + "/view/salesstaff/customerSearch.jsp");
    }

    private static SalesStaff loggedInStaff(HttpSession session) {
        Object staff = session == null ? null : session.getAttribute("loggedInStaff");
        if (staff instanceof SalesStaff && SalesStaff.POSITION.equals(((SalesStaff) staff).getPosition())) {
            return (SalesStaff) staff;
        }
        return null;
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
%>
<%
    // Bước 1-2: nhân viên click subPaymentMenu -> trang gọi openPayment() của chính nó
    if ("openPayment".equals(request.getParameter("action"))) {
        openPayment(request, response, session);
        return;
    }
    SalesStaff staff = loggedInStaff(session);
    if (staff == null) {
        response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
        return;
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Trang chủ nhân viên</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 360px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .btn { display: inline-block; margin: 6px 0; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; }
    </style>
</head>
<body>
<div class="panel">
    <h2>TRANG CHỦ NHÂN VIÊN</h2>
    <p><b>Nhân viên:</b> <%= esc(staff.getFullName()) %></p>
    <a id="subPaymentMenu" class="btn" href="<%= ctx %>/view/salesstaff/salesStaffMain.jsp?action=openPayment">Thanh toán</a><br>
    <a class="btn" href="<%= ctx %>/view/member/logout.jsp">Đăng xuất</a>
</div>
</body>
</html>
