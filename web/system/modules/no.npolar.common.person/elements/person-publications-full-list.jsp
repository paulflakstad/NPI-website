<%-- 
    Document   : person-publications-full-list
    Created on : Dec 13, 2013, 11:05:32 AM
    Author     : Paul-Inge Flakstad
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

public String idFromEmail(String email) {
    if (email.contains("%40npolar.no"))
        return email.replace("%40npolar.no", "");
    else if (email.contains("@npolar.no"))
        return email.replace("@npolar.no", "");
    else
        return email;
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
String email = cms.getRequest().getParameter("email");
if (email == null || email.isEmpty()) {
    // crash
    out.println("<!-- Missing identifier. An identifier is required in order to view a person's publications. -->");
    return; // IMPORTANT!
} else if (!email.contains("@")) {
    email = email.concat("@npolar.no");
}
// Suddenly caused trouble ... outcommented for now ...
//email = URLEncoder.encode(email, "utf-8");

String pubTypes = cms.getRequest().getParameter("pubtypes");

// Needed to show additional info to logged-in users
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Output "debug" info?
final boolean DEBUG = false;
PublicationService pubService = null;

try {
    // Set up the publication service
    pubService = new PublicationService(cms.getRequestContext().getLocale());
    
    // Add all default settings
    pubService.setAllowDrafts(
            false
    ).addDefaultParameter(
            PublicationService.modFilter(Publication.Key.STATE), 
            PublicationService.Delimiter.OR,
            Publication.Val.STATE_PUBLISHED,
            Publication.Val.STATE_ACCEPTED
    ).addDefaultParameter(
            PublicationService.Param.FACETS,
            PublicationService.ParamVal.FACETS_NONE
    ).addDefaultParameter(
            PublicationService.Param.SORT_BY,
            PublicationService.modReverse(Publication.Key.PUB_TIME)
    ).addDefaultParameter(
            // Specifying the fields here, in order to reduce response size
            PublicationService.Param.FIELDS,
            PublicationService.Delimiter.AND,
            Publication.Key.ID,
            Publication.Key.DOI, 
            Publication.Key.TITLE,
            Publication.Key.TYPE,
            Publication.Key.STATE,
            Publication.Key.PUB_TIME,
            Publication.Key.VOLUME,
            Publication.Key.ISSUE,
            Publication.Key.ARTICLE_NUMBER,
            Publication.Key.PAGE_COUNT,
            Publication.Key.JOURNAL,
            Publication.Key.CONF,
            Publication.Key.PAGES,
            Publication.Key.PEOPLE,
            Publication.Key.ORGS,
            Publication.Key.LINKS,
            Publication.Key.COMMENT
    );
    
    // Add all "freely modifiable" settings
    pubService.addParameter(
            PublicationService.Param.RESULTS_LIMIT, 
            PublicationService.ParamVal.RESULTS_LIMIT_NO_LIMIT
    ).addParameter(
            PublicationService.modFilter(PublicationService.combine(PublicationService.Delimiter.CHILD, Publication.Key.PEOPLE, Publication.Key.EMAIL)),
            email
    );
    
    // The personal pages in the CMS has an option to include only certain types 
    // of publications, so add a filter if this is used
    if (pubTypes != null && !pubTypes.isEmpty()) {
        pubService.addParameter(
                PublicationService.modFilter(Publication.Key.TYPE), 
                pubTypes
        );
    }
    
    // Set freetext query empty => catch all
    pubService.setFreetextQuery("");
    
} catch (Exception e) {
    out.println("Unable to retrieve publications list. Please try again later.");
    if (LOGGED_IN_USER) {
    out.println("<h3>ERROR configuring publication service instance!</h3>");
        out.println("<p>Seeing as you're logged in, here's what happened:</p>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
    return;
}

/*
//
// Parameters to use in the request to the service:
//
Map<String, String[]> params = new HashMap<String, String[]>();
// Catch-all query
params.put(APIService.PARAM_QUERY, new String[]{ "" });
// Limitless number of results
params.put(APIService.PARAM_RESULTS_COUNT, new String[]{ "all" });
// Filter by this person's identifier
params.put(
        SearchFilter.PARAM_NAME_PREFIX.concat("people.email"), 
        new String[]{ email }
); 
// Filter by the publication type (if specified)
if (pubTypes != null && !pubTypes.isEmpty()) {
    params.put(
            SearchFilter.PARAM_NAME_PREFIX.concat(Publication.JSON_KEY_TYPE), 
            new String[]{ pubTypes }
    );
}
//*/

//params.put("sort"               , new String[]{ "-published-year" }); // Sort by publish year, descending
//params.put("sort"               , new String[]{ "-published-year,-published-date" }); // Sort by publish date, descending (and this is the sort parameter for that)
//params.put("facets"             , new String[]{ "false" }); // No facets 
//params.put("filter-state"       , new String[]{ "published" }); // Must be published
//params.put("filter-draft"       , new String[]{ "no" }); // Must be published (does not work, entries with a missing "draft" flag will also be included)

/*
// Set custom default parameters (needed because the standard default sort parameter is no good)
// ToDo: Fix parameter handling in class library, sort out:
//          - default parameters (should be fallbacks for non-existing but needed parameters, overridden as soon as a value is given)
//          - "hidden" parameters (not visible to the user in the URL) - is this the same as "default parameters"?
//          - unmodifiable parameters (should be unmodifiable) - e.g. format=json
Map<String, String[]> defaultParams = new HashMap<String, String[]>();
// Don't include drafts ("draft=no" will not work - entries *missing* "draft" field will also be included)
defaultParams.put("not-draft", new String[]{ "yes" });
// Fetch only published or accepted publications
defaultParams.put(
        SearchFilter.PARAM_NAME_PREFIX.concat(Publication.JSON_KEY_STATE), 
        new String[]{ Publication.JSON_VAL_STATE_PUBLISHED + "|" + Publication.JSON_VAL_STATE_ACCEPTED }
); 
// No facets
defaultParams.put(APIService.PARAM_FACETS, new String[]{ "false" });
// Sort by publish time, descending
defaultParams.put("sort", new String[]{ "-" + Publication.JSON_KEY_PUB_TIME });
// Only fetch necessary fields (currently no way to exclude fields, so we must define the ones we want instead)
defaultParams.put(
        APIService.PARAM_FIELDS, //"fields",   
        new String[]{
            Publication.JSON_KEY_ID 
            + ",_" + Publication.JSON_KEY_ID 
            + "," + Publication.JSON_KEY_DOI 
            + "," + Publication.JSON_KEY_TITLE
            + "," + Publication.JSON_KEY_TYPE  
            + "," + Publication.JSON_KEY_STATE
            + "," + Publication.JSON_KEY_PUB_ACCURACY 
            + "," + Publication.JSON_KEY_PUB_TIME 
            + "," + Publication.JSON_KEY_VOLUME
            + "," + Publication.JSON_KEY_ISSUE
            //+ ",suppl" // is this needed?
            //+ ",art_no" // is this needed?
            + "," + Publication.JSON_KEY_PAGE_COUNT 
            + "," + Publication.JSON_KEY_JOURNAL
            + "," + Publication.JSON_KEY_CONF
            + "," + Publication.JSON_KEY_PAGES
            + "," + Publication.JSON_KEY_PEOPLE
            + "," + Publication.JSON_KEY_ORGS
            //+ ",isbn" // is this needed?
            //+ ",issn" // is this needed?
            + "," + Publication.JSON_KEY_LINKS
            + ","  + Publication.JSON_KEY_COMMENT
        });


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
    // Create the "publication service" instance
    //PublicationService pubService = new PublicationService(locale);
    
    // Set custom defaults
    //pubService.setDefaultParameters(defaultParams);
    
    // Get publications
    publications = pubService.getPublications();
    //publications = pubService.getPublications(params);
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
    <a class="toggletrigger" tabindex="0"><%= cms.labelUnicode("label.np.publist.heading") %></a>
    <div class="toggletarget" style="display:none;">
    <%
    // Get types of publications
    Iterator<String> iTypes = publications.getTypesContained().iterator();
    while (iTypes.hasNext()) {
        String listType = iTypes.next();
        ArrayList<Publication> pubs = publications.getListGroup(listType);
        Iterator<Publication> iPubs = pubs.iterator();
        
        // Remove "unwanted" entries (applies only to certain types of publications, 
        // and in particular part-contributions where this person is also the 
        // author/editor of the "parent" publication)
        if (listType.equals(Publication.Type.BOOK.toString()) || listType.equals(Publication.Type.REPORT.toString())) {
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
        
        if (iPubs.hasNext()) {
            int listSize = publications.getListGroup(listType).size();
            String listHeading = listType;
            try { listHeading = labels.getString(Labels.PUB_TYPE_PREFIX_0 + listType + (listSize > 1 ? ".plural" : "")); } catch (Exception e) {}
            %>
            <h3><%= listHeading + " (" + listSize + ")" %></h3>
            <ul class="fullwidth indent line-items">
            <%
            while (iPubs.hasNext()) {
                %>
                <li><%= iPubs.next().toString() %></li>
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
}
else {
    // No publications found on serviceUrl 
    %>
    <div class="toggletrigger inactive" style="color:#aaa; cursor:initial;"><%= cms.labelUnicode("label.np.publist.heading.none") %></div>
    <%
    if (DEBUG) { out.println("No publications. Publications = " + (publications == null ? "null" : publications.size()) + "."); }
}
%>