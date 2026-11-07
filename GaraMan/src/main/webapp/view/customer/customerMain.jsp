<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%!
    /*
     * customerMain.jsp (Hình 4.5, Bảng 4.5)
     *   subSearchMenu: link
     *   openItemSearch(): void  -> gọi trang itemSearch.jsp (không yêu cầu đăng nhập)
     */
    private void openItemSearch(HttpServletResponse response) throws java.io.IOException {
        response.sendRedirect("itemSearch.jsp");
    }
%>
<%
    // Bước 1-3: khách hàng click subSearchMenu -> trang gọi openItemSearch() của chính nó
    if ("openItemSearch".equals(request.getParameter("action"))) {
        openItemSearch(response);
        return;
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Trang chủ</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 360px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .btn { display: inline-block; margin: 6px 0; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; }
        .btn[disabled] { cursor: default; }
    </style>
</head>
<body>
<div class="panel">
    <h2>GARAMAN — TRANG CHỦ</h2>
    <p>Chào mừng quý khách đến với GaraMan.</p>
    <a id="subSearchMenu" class="btn" href="<%= request.getContextPath() %>/view/customer/customerMain.jsp?action=openItemSearch">Tìm dịch vụ/phụ tùng</a><br>
    <%-- "Đặt lịch hẹn" thuộc module khác (appointment.jsp), chưa nằm trong phạm vi module này --%>
    <button class="btn" type="button" disabled>Đặt lịch hẹn</button>
</div>
</body>
</html>
