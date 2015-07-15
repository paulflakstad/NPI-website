<%-- 
    Document   : menu-subitems
    Created on : Apr 24, 2014, 2:13:29 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@ page import="no.npolar.util.*,
                 no.npolar.common.menu.*,
                 java.util.Locale,
                 java.util.List,
                 java.util.Iterator,
                 org.opencms.jsp.*, org.opencms.file.CmsResource" session="true" 
%><%
// Create a JSP action element, and get the URI of the requesting file (the one that includes this menu)
CmsAgent cms = new CmsAgent(pageContext, request, response);
Menu menu = null;
Iterator i = null;

if (request.getSession().getAttribute("menu") != null) {
    menu = (Menu)request.getSession().getAttribute("menu");
}

if (menu != null) {
    List subItems = menu.getCurrent().getSubItems();
    if (subItems != null) {
        i = subItems.iterator();
        MenuItem item = null;
        if (subItems.size() > 0) {
            out.println("<ul>");
            while (i.hasNext()) {
                item = (MenuItem)i.next();
                if (item != null)
                out.println("<li><a href=\"" + item.getUrl() + "\">" + 
                                item.getNavigationText() + "</a></li>");

            }
            out.println("</ul>");
        }
    }
}
%>