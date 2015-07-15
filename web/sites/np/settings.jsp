<%-- 
    Document   : settings
    Created on : Sep 10, 2013, 2:04:26 PM
    Author     : flakstad
--%><%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.main.OpenCms,
                org.opencms.xml.content.*,
                org.opencms.db.CmsResourceState,
		java.util.*,
                java.text.SimpleDateFormat,
                no.npolar.common.menu.*,
                no.npolar.util.CmsAgent"
%><%
HttpSession sess            = request.getSession();

String pinnedNavParam = request.getParameter("pinned_nav");
if (pinnedNavParam == null) {
    if (sess.getAttribute("pinned_nav") == null) {
        pinnedNavParam = "false"; // No stored value, set default value
    } 
    else {
        pinnedNavParam = sess.getAttribute("pinned_nav").toString(); // Stored value
    }
}



String cmsResInfoParam = request.getParameter("cms_res_info");
if (cmsResInfoParam == null) {
    if (sess.getAttribute("cms_res_info") == null) {
        cmsResInfoParam = "true"; // No stored value, set default value
    } 
    else {
        cmsResInfoParam = sess.getAttribute("cms_res_info").toString(); // Stored value
    }
}


sess.setAttribute("pinned_nav", pinnedNavParam);
sess.setAttribute("cms_res_info", cmsResInfoParam);
%>