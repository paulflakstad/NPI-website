<%-- 
    Document   : project-publications-full-list - based on /system/modules/no.npolar.common.person/elements/person-publications-full-list
    Created on : Oct 8, 2015, 4:08:17 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="no.npolar.data.api.*,
                 no.npolar.util.CmsAgent,
                 java.net.URLEncoder,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
                 java.util.ResourceBundle,
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

/*
public String idFromEmail(String email) {
    if (email.contains("%40npolar.no"))
        return email.replace("%40npolar.no", "");
    else if (email.contains("@npolar.no"))
        return email.replace("@npolar.no", "");
    else
        return email;
}
//*/
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

// Project ID (required)
String id = cms.getRequest().getParameter("id");
if (id == null || id.isEmpty()) {
    // crash
    out.println("<!-- Missing identifier, which is required in order to list a project's publications. -->");
    return; // IMPORTANT!
} 
id = "https://data.npolar.no/project/" + id; // Make the ID the full URL to the project

// Suddenly caused trouble ... outcommented for now ...
//email = URLEncoder.encode(email, "utf-8");

String pubTypes = cms.getRequest().getParameter("pubtypes");

// Needed to show additional info to logged-in users
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Output "debug" info?
final boolean DEBUG = false;

/*
//
// Parameters to use in the request to the service:
//
Map<String, String[]> params = new HashMap<String, String[]>();
params.put("q",                 new String[]{ "" }); // Catch-all query
params.put("filter-links.href", new String[]{ id }); // Filter by an identifier
params.put("limit",             new String[]{ "all" }); // Fetch everything
if (pubTypes != null && !pubTypes.isEmpty())
    params.put("filter-publication_type", new String[]{ pubTypes });
//params.put("sort"               , new String[]{ "-published-year" }); // Sort by publish year, descending
//params.put("sort"               , new String[]{ "-published-year,-published-date" }); // Sort by publish date, descending (and this is the sort parameter for that)
//params.put("facets"             , new String[]{ "false" }); // No facets 
//params.put("filter-state"       , new String[]{ "published" }); // Must be published
//params.put("filter-draft"       , new String[]{ "no" }); // Must be published (does not work, entries with a missing "draft" flag will also be included)
//*/

/*
// Set custom default parameters (needed because the standard default sort parameter is no good)
// ToDo: Fix parameter handling in class library, sort out:
//          - default parameters (should be fallbacks for non-existing but needed parameters, overridden as soon as a value is given)
//          - "hidden" parameters (not visible to the user in the URL) - is this the same as "default parameters"?
//          - unmodifiable parameters (should be unmodifiable) - e.g. format=json
Map<String, String[]> defaultParams = new HashMap<String, String[]>();
//defaultParams.put("not-draft",              new String[]{ "yes" }); // Don't include drafts ("draft=no" will not work, as entries with a missing "draft" flag will also be included)
defaultParams.put("filter-state",           new String[]{ "published|accepted|submitted" }); // Limit publications by state
defaultParams.put("facets",                 new String[]{ "false" }); // No facets
defaultParams.put("sort",                   new String[]{ "-published_sort" }); // Sort by publish time, descending
//defaultParams.put("fields",                 new String[]{ "id,_id,title,publication_type,state,published_helper,published_sort,volume,issue,suppl,art_no,page_count,journal,conference,pages,people,organisations,isbn,issn,links,comment" }); // Don't include unnecessary fields (currently no syntax to exlude fields, so we need an exhaustive list of the ones we want)
//defaultParams.put("sort",                   new String[]{ "-published-year,-published-date" }); // Sort by publish date, descending (and this is the sort parameter for that)
//defaultParams.put("q",                      new String[]{ "" }); // Catch-all query (this is set in regular params)
//defaultParams.put("limit",                  new String[]{ "all" }); // Fetch everything (this is set in regular params)
//defaultParams.put("filter-people.email",    new String[]{ email }); // Filter by this person's identifier (this is set in regular params)
//defaultParams.put("filter-draft",           new String[]{ "no" }); // Don't include drafts (does not work, entries with a missing "draft" flag will also be included)
//*/




//
// Fetch publications
//
GroupedCollection<Publication> publications = null;
try {
    PublicationService pubService = new PublicationService( new Locale("en") );
    pubService.addDefaultFilter(
            Publication.Key.STATE, 
            PublicationService.Delimiter.OR,
            Publication.Val.STATE_PUBLISHED, 
            Publication.Val.STATE_ACCEPTED,
            Publication.Val.STATE_SUBMITTED
    ).addDefaultParameter(
            PublicationService.Param.FACETS, 
            PublicationService.ParamVal.FACETS_NONE
    ).addDefaultParameter(
            PublicationService.Param.SORT_BY,
            APIService.modReverse(Publication.Key.PUB_TIME)
    ).addFilter(
            APIService.combine(
                    APIService.Delimiter.CHILD, 
                    Publication.Key.LINKS, 
                    Publication.Key.LINK_HREF
            ), 
            id
    ).addParameter(
            PublicationService.Param.RESULTS_LIMIT, 
            PublicationService.ParamVal.RESULTS_LIMIT_NO_LIMIT
    );
    pubService.setFreetextQuery("");
            
    
    if (pubTypes != null && !pubTypes.isEmpty()) {
        pubService.addFilter(Publication.Key.TYPE, pubTypes);
    }
    
    
    
    // Get publications
    publications = pubService.getPublications();
    out.println("<!-- API URL: " + pubService.getLastServiceURL() + " -->");
    if (DEBUG) { out.println("Read " + (publications == null ? "null" : publications.size()) + " publications from service URL <a href=\"" + pubService.getLastServiceURL() + "\" target=\"_blank\">" + pubService.getLastServiceURL() + "</a>."); }
} catch (Exception e) {
    out.println("An unexpected error occured while constructing the publications list.");
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
if (publications != null && !publications.isEmpty()) {
    ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
    //out.println("<h2 class=\"toggletrigger\">" + cms.labelUnicode("label.np.publist.heading") + "</h2>");
    %>
    <!--<a class="toggletrigger" href="javascript:void(0);"><%= cms.labelUnicode("label.np.publist.heading") %></a>-->
    <!--<div class="toggletarget" style="display:none;">-->
    <!--<h2 class="toggler"><%= cms.labelUnicode("label.np.publist.heading") %></h2>-->
    <!--<div class="toggleable" id="project__publications">-->
    <%
    // Get types of publications
    Iterator<String> iTypes = publications.getTypesContained().iterator();
    while (iTypes.hasNext()) {
        String listType = iTypes.next();
        ArrayList<Publication> pubs = publications.getListGroup(listType);
        Iterator<Publication> iPubs = pubs.iterator();
        /*
        // Remove unwanted stuff
        if (listType.equals(Publication.TYPE_BOOK) || listType.equals(Publication.TYPE_REPORT)) { // Do this for these types only
            while (iPubs.hasNext()) { // Loop all publications in this group
                Publication p = iPubs.next(); // Get the next publication
                if (p.isPartContribution()) { // Require part-contribution (e.g. report in report series or chapter in book)
                    List<PublicationContributor> contributors = p.getPeople(); // Get all contributors
                    Iterator<PublicationContributor> iContr = contributors.iterator();
                    while (iContr.hasNext()) {
                        PublicationContributor pubContrib = iContr.next(); // Get the next contributor
                        if (DEBUG) { out.println("<!-- Evaluating ID: '" + pubContrib.getID() + "' ... (current ID from email is '" + idFromEmail(email) + "') -->"); }
                        if (idFromEmail(email).equals(pubContrib.getID())) { // If this is the person we're listing for ...
                            if (DEBUG) { out.println("<!-- The ID is the current person -->"); }
                            boolean removeEntry = false; // Remove this publication from the list?
                            try { 
                                // The publication should be removed if this person is an editor (in this case, this means (s)he is an editor of the "parent" publication)
                                removeEntry =  pubContrib.hasRoleOnly(Publication.JSON_VAL_ROLE_EDITOR);
                            } catch (Exception e) {
                                if (DEBUG) { out.println("<!-- Caught exception: " + e.getMessage() + " -->"); }
                            }
                            if (removeEntry) {
                                if (DEBUG) { out.println("<!-- " + pubContrib.getFirstName() + " is editor of parent publication: REMOVING " + p.getTitle() + " -->"); }
                                iPubs.remove();
                                break; // Break out
                            } else {
                                if (DEBUG) { out.println("<!-- " + pubContrib.getFirstName() + " had a role different from or more than editor. -->"); }
                            }
                        }
                    }
                }
            }
            iPubs = pubs.iterator(); // Reset iterator
            
        }
        //*/
        
        if (iPubs.hasNext()) {
            int listSize = publications.getListGroup(listType).size();
            %>
            <h3><%= labels.getString("publication.type." + listType + (listSize > 1 ? ".plural" : "")) + " (" + listSize + ")" %></h3>
            <!--<h3><%= cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListGroup(listType).size() + ")" %></h3>-->
            <div class="indent">
                <ul class="list--serp">
                <%
                while (iPubs.hasNext()) {
                    %>
                    <li class="serp-item"><%= iPubs.next().toString() %></li>
                    <%
                }
                %>
                </ul>
            </div>
            <%
        }
    }
    %>
    <!--</div>-->
    <%
}
else {
    // No publications found on serviceUrl 
    %>
    <p><em><%= cms.labelUnicode("label.np.list.publications.none") %></em></p>
    <%
    if (DEBUG) { out.println("No publications. Publications = " + (publications == null ? "null" : publications.size()) + "."); }
}
%>