<%-- 
    Document   : topic-publications
    Created on : Feb 5, 2014, 11:14:18 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="java.util.ResourceBundle"%>
<%@page import="no.npolar.data.api.*,
                 no.npolar.util.CmsAgent,
                 java.net.URLEncoder,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsUser,
                 org.opencms.main.OpenCms,
                 org.opencms.security.CmsRole" session="true"
%><%!
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
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
//CmsObject cmso          = cms.getCmsObject();
//String requestFileUri   = cms.getRequestContext().getUri();
//String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();

// Make sure to use the given locale, if present
if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    locale = new Locale(loc);
    try { cms.getRequestContext().setLocale(locale); } catch (Exception e) {}
}

// E-mail address (required)
String topic = cms.getRequest().getParameter("topic");
if (topic == null || topic.isEmpty()) {
    // crash
    out.println("<!-- Missing identifier. An identifier is required in order to view topic publications. -->");
    return; // IMPORTANT!
}
topic = URLEncoder.encode(topic, "utf-8");

// Needed to show additional info to logged-in users
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Output "debug" info?
final boolean DEBUG = false;

final int LIMIT = 5;

PublicationService service = null;
try {
    service = new PublicationService(locale);
} catch (Exception e) {
    // Unable to access the publication service
    return;
}

//
// Parameters to use in the request to the service:
//
HashMap<String, String[]> params = new HashMap<String, String[]>();
params.put("q"                  , new String[]{ "" }); // Catch-all query
params.put("filter-topics"      , new String[]{ topic }); // Filter by a theme identifier
params.put("sort"               , new String[]{ "-published-year" }); // Sort by publish year, descending
params.put("limit"              , new String[]{ String.valueOf(LIMIT) }); // Limit the results

ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);

// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------
try {
    List<Publication> publications = service.getPublicationList(params);
    if (publications != null && !publications.isEmpty()) {
        %>
        <ul>
        <%
        Iterator<Publication> i = publications.iterator();
        while (i.hasNext()) {
            Publication publication = i.next();
            %>
            <li><span class="tag" style="display:inline-block; color:#666; background:#eee; padding:0.1em 0.2em; font-size:0.9em;"><%= labels.getString("publication.type.".concat(publication.getType())) %></span> <%= publication.toString() %></li>
            <%
        }
        %>
        </ul>
        <%
    }
} catch (Exception e) {
    // Error printing publications
}
%>