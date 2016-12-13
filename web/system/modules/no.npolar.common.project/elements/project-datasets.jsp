<%-- 
    Document   : project-datasets - based on project-publications-full-list
    Created on : Dec 12, 2016
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="no.npolar.data.api.*" %>
<%@page import="no.npolar.data.api.util.*" %>                
<%@page import="no.npolar.util.CmsAgent" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.List" %>
<%@page import="java.util.ArrayList" %>
<%@page import="java.util.Map" %>
<%@page import="java.util.HashMap" %>
<%@page import="java.util.Locale" %>
<%@page import="java.util.Iterator" %>
<%@page import="java.util.ResourceBundle" %>
<%@page import="org.opencms.file.CmsObject" %>
<%@page import="org.opencms.file.CmsUser" %>
<%@page import="org.opencms.main.OpenCms" %>
<%@page import="org.opencms.security.CmsRole" %>
<%@page session="true" pageEncoding="utf-8" trimDirectiveWhitespaces="true" %>
<%!
/**
 * Gets an exception's stack trace as a String.
 */
public String getStackTrace(Exception e) {
    //String trace = "<h3>" + e.toString() + "</h3><h4>" + e.getCause() + ": " + e.getMessage() + "</h4>";
    String trace = "<h4>" + e.toString() + " (" + e.getCause() + ")</h4>";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}
%><%
CmsAgent cms            = new CmsAgent(pageContext, request, response);
Locale locale           = cms.getRequestContext().getLocale();
String loc              = request.getParameter("locale");

// Make sure to use the given locale, if present
if (loc != null)  {
    try { 
        locale = new Locale(loc);
        cms.getRequestContext().setLocale(locale); 
    } catch (Exception e) {}
}

// Needed to show additional info to logged-in users
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Output "debug" info?
final boolean DEBUG = false;
// The datasets URI, f.ex. 
// http://api.npolar.no/dataset/?filter-sets=N-ICE2015&filter-links.rel=data&q=&not-draft=yes
final String DATASETS_URI = request.getParameter("uri");


DatasetService s = new DatasetService(locale);
List<Dataset> entries = null;

// Fetch datasets
try {
    Map<String, String> serviceParams = APIUtil.getParametersInQueryString(DATASETS_URI);
    for (String pname : serviceParams.keySet()) {
        s.addParameter(pname, serviceParams.get(pname));
    }
    // Ensure no query string
    s.setFreetextQuery("");
    // Ensure no drafts
    s.setAllowDrafts(false);
    // Ensure no facets
    s.addDefaultParameter( 
            APIService.Param.FACETS,
            APIService.ParamVal.FACETS_NONE
    );
    // Order by release time
    s.addDefaultParameter(
            APIService.Param.SORT_BY,
            APIService.modReverse(Dataset.Key.PUB_TIME)
    );
    entries = s.getDatasetList();
    out.println("<!-- API URL: " + s.getLastServiceURL() + " -->");
} catch (Exception e) {
    out.println("<!-- ERROR: " + e.getMessage() + " -->");
}
// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------
if (entries != null && !entries.isEmpty()) { %>
    <ul class="list--serp">
    <% for (Dataset entry : entries) { %>
        <li class="serp-item">
            <a href="<%= entry.getHumanURL(s) %>"><%= entry.getTitleClosed() %></a> 
            <time class="tag tag--time" datetime="<%= entry.getPubTime().substring(0,10) %>"><%= entry.getPubTime().substring(0,10) %></time>
        </li>
    <% } %>
    </ul> 
<% } else { %>
    <p><em><%= cms.labelUnicode("label.np.list.datasets.none") %></em></p>
<% } %>