<%-- 
    Document   : wai.css
    Created on : 25.mai.2011, 12:36:42
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*,
                org.opencms.file.CmsObject,
		java.util.*,
                no.npolar.util.CmsAgent"
%><%
//CmsAgent cms = new CmsAgent(pageContext, request, response);
//CmsObject cmso = cms.getCmsObject();
HttpSession sess = request.getSession();

// Set font-size
if (sess.getAttribute("fs") != null) {
    String fs = (String)sess.getAttribute("fs");
    out.println("body {");
    out.print("\tfont-size:");
    if ("fs".equalsIgnoreCase("M")) {
        out.println("100%;");
    }
    else if (fs.equalsIgnoreCase("L")) {
        out.println("120%;");
    }
    else if (fs.equalsIgnoreCase("XL")) {
        out.println("140%;");
    } 
    else {
        out.println("100%;");
    }
    out.println("}");
}
%>
