<%-- 
    Document   : projects-service-provided
    Description: Lists publications using the data.npolar.no API.
    Created on : Mar 12, 2013, 5:32:42 PM
    Author     : flakstad
--%><%@page import="java.util.ResourceBundle, 
                    no.npolar.data.api.*,
                    no.npolar.data.api.util.APIUtil,
                    no.npolar.util.CmsAgent,
                    no.npolar.util.SystemMessenger,
                    java.io.PrintWriter,
                    java.util.Locale,
                    java.net.URLEncoder,
                    org.opencms.file.CmsObject,
                    org.opencms.util.CmsStringUtil,
                    java.util.List,
                    java.util.Map,
                    java.util.HashMap,
                    java.util.Iterator"
                contentType="text/html" 
                pageEncoding="UTF-8" 
                session="true"
 %><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final String DETAILS_URI = loc.equalsIgnoreCase("no") ? "detaljer" : "details";

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();

final String LABEL_SEARCHBOX_HEADING = loc.equalsIgnoreCase("no") ? "Søk i prosjekter" : "Search projects";

//final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");

// This holds translations
ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);

// Create the service instance that will talk to the API 
ProjectService service = new ProjectService(locale);

// Test service 
// ToDo: The error message should be moved to workplace.properies or something
final String ERROR_MSG_NO_SERVICE = loc.equalsIgnoreCase("no") ? 
        ("<h2>Vel, dette skulle ikke skje&nbsp;&hellip;</h2>"
            + "<p>Sideinnholdet som skulle vært her kan dessverre ikke vises akkurat nå, på grunn av en midlertidig feil.</p>"
            + "<p>Vi liker heller ikke dette, og håper å ha alt i orden igjen snart.</p>"
            + "<p>Prøv gjerne å laste inn siden på nytt om litt.</p>"
            + "<p style=\"font-style:italic;\">Skulle feilen vedvare, setter vi pris på det om du tar deg tid til å <a href=\"mailto:web@npolar.no\">sende oss en kort notis om dette</a>.")
        :
        ("<h2>Well this shouldn't happen&nbsp;&hellip;</h2>"
            + "<p>The content that should appear here can't be displayed at the moment, due to a temporary error.</p>"
            + "<p>We hate it when this happens, and hope to have everything sorted out shortly.</p>"
            + "<p>Please try reloading this page in a little while.</p>"
            + "<p style=\"font-style:italic;\">If the error persist, we would appreciate it if you could take the time to <a href=\"mailto:web@npolar.no\">send us a short note about this</a>.</p>");

try {
    boolean isAvailable = APIUtil.testAvailability(service.getServiceBaseURL().concat("?q="), new int[]{200}, 5000, 3);
    if (!isAvailable) {
        out.println("<div class=\"error message message--error\">" + ERROR_MSG_NO_SERVICE + "</div>");
        try {
            SystemMessenger.sendStandardError(
                    SystemMessenger.DEFAULT_INTERVAL, 
                    "last_err_notification_projects", 
                    application, 
                    cms, 
                    "web@npolar.no", 
                    "no-reply@npolar.no", 
                    "Projects");
        } catch (Exception e) { 
            out.println("\n<!-- \nError sending email notification about problems with this page: " + e.getMessage() + " \n-->");
        }
        return;
    }
} catch (Exception e) {}

// Set defaults
// (No need to filter out drafts, as that is the default setting)
service.addDefaultParameter(
        // Define what fields we want filters for
        ProjectService.Param.FACETS, 
        ProjectService.Delimiter.AND, 
        Project.Key.AREA,
        Project.Key.STATE,
        Project.Key.TOPICS,
        Project.Key.TYPE
).addDefaultParameter(
        // Get all possible filters (not just "greatest hits")
        ProjectService.Param.FACETS_SIZE,
        ProjectService.ParamVal.FACETS_SIZE_MAX
);

try {
    Map<String, String[]> params = new HashMap(request.getParameterMap());
    
    // ToDo: Is encoding absolutely necessary here???
    Iterator<String> iParam = params.keySet().iterator();
    while (iParam.hasNext()) {
        String key = iParam.next();
        //*
        String[] val = params.get(key);
        for (int iVal = 0; iVal < val.length; iVal++) {
            val[iVal] = URLEncoder.encode(val[iVal], "utf-8");
        }
        params.put(key, val);
        //*/
    }
    
    if (!params.containsKey(ProjectService.Param.QUERY)) {
        service.setFreetextQuery("");
    }
    //else {
    //    service.setFreetextQuery(URLEncoder.encode(params.get("q")[0], "utf-8"));
    //}
    
    List<Project> list = service.getProjectList(params);
    //out.println("<h1>Matched " + pubService.getTotalResults() + " publications (" + pubList.size() + " per page), " 
    //        + (pubService.isUserFiltered() ? "" : " NOT") + " filtered by user.</h1>");
    
    //out.println("<h4>" + pubService.getLastServiceURL() + "</h4>");
    
    SearchFilterSets filterSets = service.getFilterSets();
    String lastSearchPhrase = service.getLastSearchPhrase();
    int totalResults = service.getTotalResults();

        // Query 
        %>
        <div class="searchbox-big search-widget search-widget--filterable">
            <h2><%= LABEL_SEARCHBOX_HEADING %></h2>
            <form action="<%= cms.link(requestFileUri) %>" method="get">
                <div class="searchbox">
                    <input class="searchbox__search-query search-query" name="q" type="search" value="<%= lastSearchPhrase == null ? "" : CmsStringUtil.escapeHtml(lastSearchPhrase) %>" />
                    <input class="searchbox__search-button search-button" type="submit" value="<%= LABEL_SEARCH %>" />
                </div>
                <input name="start" type="hidden" value="0" />
            <%
            if (!filterSets.isEmpty()) {
                out.println(filterSets.toHtml(LABEL_FILTERS, cms, labels));
            }
            %>
            </form>
        </div>
        <div id="filters-details"></div>
        <%
            

    if (totalResults > 0) {
        %>
        <h2 style="color:#999; border-bottom:1px solid #eee;">
            <span id="totalResultsCount"><%= totalResults %></span> <%= LABEL_MATCHES.toLowerCase() %>
        </h2>

        <% if (!ONLINE) { %>
        <div id="admin-msg" style="margin:1em 0; background: #eee; color: #444; padding:1em; font-family: monospace; font-size:1.2em;"></div>
        <% } %>

        <ul class="fullwidth line-items blocklist">
            <%
            Iterator<Project> iList = list.iterator();
            while (iList.hasNext()) {
                Project item = iList.next();
                String uri = DETAILS_URI.concat("?pid=").concat(item.getId());
                String title = item.getTitle() + (item.getTitleAbbrev().isEmpty() ? "" : " (" +item.getTitleAbbrev() + ")");
                %>
                <li>
                    <h3 style="margin-top:0;"><a href="<%= uri %>"><%= title %></a></h3>
                    <% if (!item.getDescription().isEmpty()) { %>
                    <p><%= (item.getType().isEmpty() ? "" : "<span class=\"tag\" style=\"background:#eee; color:#333; padding:0.2em; font-size:0.9em;\">" + item.getType() + "</span> ") + CmsStringUtil.trimToSize(item.getDescription(), 300, " &hellip;") %></p>
                    <% } %>
                </li>
                <%
            }  
            %>
        </ul>
        
        <%
        // Standard pagination
        SearchResultsPagination pagination = new SearchResultsPagination(service, requestFileUri);
        out.println(pagination.getPaginationHtml());
    }
    else {
        out.println("<h2 style=\"color:#999;\">" + LABEL_NO_MATCHES + "</h2>");
    }
//*  
} catch (Exception e) {
    out.println("<div class=\"paragraph\"><p>");
    if (loc.equalsIgnoreCase("no")) {
        out.println("En feil oppsto ved uthenting av prosjekter. Vennligst prøv å oppdater siden, prøv et annet søk, eller kom tilbake senere.</p><p>Skulle feilen vedvare, setter vi pris på det om du tar deg tid til å <a href=\"mailto:web@npolar.no\">sende oss en kort notis om dette</a>.");
    } else {
        out.println("An error occured while fetching the projects. Please try refreshing the page, try a different search, or come back later.</p><p>If the error persist, we would appreciate it if you could take the time to <a href=\"mailto:web@npolar.no\">send us a short note about this</a>.");
    }
    out.println("</p></div>");
    if (!ONLINE) {
        out.println("Service URL was: <a href=\"" + service.getLastServiceURL() + "\">" + service.getLastServiceURL() + "</a>");
        e.printStackTrace(response.getWriter());
    }
}
//*/
%>