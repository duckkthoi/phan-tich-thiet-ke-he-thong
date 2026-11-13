<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    PHẦN NGOÀI MODULE NHẬN THANH TOÁN (gói view/member): đăng xuất, hủy phiên rồi về trang đăng nhập.
--%>
<%
    session.invalidate();
    response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
%>
