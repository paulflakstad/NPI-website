<%-- 
    Document   : footerlinks
    Created on : 18.mar.2011, 13:26:47
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="java.util.Locale,
                java.util.HashMap,
                no.npolar.util.CmsAgent"
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
Locale loc                  = cms.getRequestContext().getLocale();
//final String LINKLIST       = "../../no.npolar.common.linklist/elements/linklist.jsp";
%>
<div class="span1">
    <%
    out.println(cms.getContent("/footer-0.html", "body", loc));
    /*
    HashMap footerLinksParam = new HashMap();
    footerLinksParam.put("resourceUri", "/footer-1.html");
    cms.include(LINKLIST, "main", false, footerLinksParam);
    */
    %>
</div>
<div class="span1">
    <%
    // THIS DOESN'T WORK, because the editor won't allow the empty html elements
    // we rely on for icons (icon font) - e.g. <i class="icon-twitter"></i>
    //out.println(cms.getContent("/footer-buttons.html", "body", loc));
    // So, instead we use plain text files, one for each language
    cms.include("/" + loc.toString() + "/footer-social-media-buttons.html");
    /*
    footerLinksParam.clear();
    footerLinksParam.put("resourceUri", "/footer-4.html");
    cms.include(LINKLIST, "main", false, footerLinksParam);
    */
    %>
</div>