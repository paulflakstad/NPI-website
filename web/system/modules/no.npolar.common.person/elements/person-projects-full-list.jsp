<%-- 
    Document   : person-projects-full-list
    Created on : Jan 27, 2014, 12:36:20 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="no.npolar.util.*,
                 no.npolar.data.api.*,
                 no.npolar.data.api.util.*,
                 java.net.URLEncoder,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
                 org.opencms.file.CmsObject,
                 org.opencms.main.OpenCms,
                 org.opencms.staticexport.CmsLinkManager,
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
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();

// Make sure to use the given locale, if present
if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    locale = new Locale(loc);
    try { cms.getRequestContext().setLocale(locale); } catch (Exception e) {}
}

// E-mail address (required)
String email = cms.getRequest().getParameter("email");
//email = "christina.pedersen@npolar.no";
if (email == null || email.isEmpty()) {
    // crash
    out.println("<!-- Missing identifier. An identifier is required in order to view a person's publications. -->");
    return; // IMPORTANT!
} else if (!email.contains("@")) {
    email = email.concat("@npolar.no");
}
email = URLEncoder.encode(email, "utf-8");

String projectTypes = cms.getRequest().getParameter("projecttypes");

final String URI_DETAIL = loc.equalsIgnoreCase("no") ? "/no/prosjekter/detaljer" : "/en/projects/details";

// Needed to show additional info to logged-in users
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Output "debug" info?
final boolean DEBUG = false;

//
// Parameters to use in the request to the service:
//
Map<String, String[]> params = new HashMap<String, String[]>();
params.put("q"                  , new String[]{ "" }); // Catch-all query
params.put("filter-people.email", new String[]{ email }); // Filter by this person's identifier
params.put("sort"               , new String[]{ "-start_date" }); // Sort by start date, descending
//params.put("format"             , new String[]{ "json" }); // Explicitly request the a response in JSON format
params.put("limit"              , new String[]{ "all" }); // Limit the results
params.put("filter-draft"       , new String[]{ "no" }); // Don't include projects flagged as drafts
if (projectTypes != null && !projectTypes.isEmpty())
    params.put("filter-state", new String[]{ projectTypes });

//
// Fetch projects
//
 
GroupedCollection<Project> projects = null;
try {
    ProjectService service = new ProjectService(cms.getRequestContext().getLocale());
    projects = service.getProjects(params);
    if (DEBUG) { out.println("Read " + (projects == null ? "null" : projects.size()) + " projects from service URL <a href=\"" + service.getLastServiceURL() + "\" target=\"_blank\">" + service.getLastServiceURL() + "</a>."); }
} catch (Exception e) {
    out.println("An unexpected error occured while constructing the projects list.");
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
    return; // IMPORTANT!
}


// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------
if (projects != null && !projects.isEmpty()) {
    //out.println("<h2 class=\"toggletrigger\">" + cms.labelUnicode("label.np.publist.heading") + "</h2>");
    %>
    <a class="toggletrigger" href="javascript:void(0);"><%= cms.labelUnicode("label.np.projectlist.heading") %></a>
    <div class="toggletarget collapsed">
    <%
    // Get types of publications
    Iterator<String> iTypes = projects.getTypesContained().iterator();
    while (iTypes.hasNext()) {
        String listType = iTypes.next();
        Iterator<Project> iProjects = projects.getListGroup(listType).iterator();
        if (iProjects.hasNext()) {
            %>
            <h3><%= cms.labelUnicode("label.np." + listType) + " (" + projects.getListGroup(listType).size() + ")" %></h3>
            <ul class="fullwidth indent line-items">
            <%
            while (iProjects.hasNext()) {
                Project p = iProjects.next();
                %>
                <li>
                    <a href="<%= cms.link(URI_DETAIL.concat("?pid=").concat(p.getId())) %>"><%= p.getTitle() + (p.getTitleAbbrev().isEmpty() ? "" : " (" + p.getTitleAbbrev() + ")") %></a>
                    <span class="timespan"><%= p.getDuration(true) %></span>
                </li>
                <%
            }
            %>
            </ul>
            <%
        }
    }
    %>
    </div>
    
    <%
    /*
    // person-publications-full-list.jsp is including the script, don't do it twice 
    <script type="text/javascript">
        $('.toggleable.collapsed > .toggletarget').slideUp(1);
        $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>');
        $('.toggleable > .toggletrigger').click(
            function() {
                $(this).next('.toggletarget').slideToggle(500);
                //$(this).children().first().toggleClass('icon-up-open-big').toggleClass('icon-down-open-big');
                $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big');
            });
    </script>*/
}
else {
    // No projects found on serviceUrl 
    if (DEBUG) { out.println("No projects. Publications = " + (projects == null ? "null" : projects.size()) + "."); }
}
%>