<%-- 
    Document   : publications-annual-report
    Created on : Dec 13, 2013, 1:12:32 PM
    Author     : flakstad
--%><%@page import="java.util.Collections"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ResourceBundle"%>
<%@page import="no.npolar.data.api.*,
                 no.npolar.util.CmsAgent,
                 java.util.Calendar,
                 java.util.GregorianCalendar,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
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

/** Facet (filter) parameter name prefix. */
public final static  String FACET_PREFIX = "filter-";
/** A string which, when appended at the end of a 4-character year string (e.g. "2014"), will create a normalized timestamp string representing the beginning of that year. */
public static final String PARAM_VAL_PART_YEAR_BEGIN = "-01-01T00:00:00Z";
/** A string which, when appended at the end of a 4-character year string (e.g. "2014"), will create a normalized timestamp string representing the end of that year. */
public static final String PARAM_VAL_PART_YEAR_END = "-12-31T23:59:59Z";
/** The string used to separate the two values in a ranged parameter. */
public static final String PARAM_VAL_RANGE_DELIMITER = "..";

/**
 * Creates a normalized year parameter string based on the given year.
 * @param year A 4-character year string, e.g. "2014" or "1337".
 * @return a normalized year parameter string, ready to use in API requests.
 */
public static String createYearParameter(String year) {
    try {
        if (year == null || year.length() != 4)
            throw new Exception();
        Integer.parseInt(year);
    } catch (Exception e) { 
        throw new IllegalArgumentException("A string representation of a 4-digit year is required."); 
    }
    return year + PARAM_VAL_PART_YEAR_BEGIN + PARAM_VAL_RANGE_DELIMITER + year + PARAM_VAL_PART_YEAR_END;
}
/**
 * @see
 */
public static String createYearParameter(int year) {
    return createYearParameter(String.valueOf(year));
}
%><%
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
String requestFileUri   = cms.getRequestContext().getUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();
Calendar nowCal         = new GregorianCalendar(locale);
int currentYear         = nowCal.get(Calendar.YEAR);

final boolean COMMENTS  = false;

final String LABEL_YEAR_SELECT = loc.equalsIgnoreCase("no") ? "År" : "Year";
final String LABEL_YEAR_SELECT_OPT_ALL = loc.equalsIgnoreCase("no") ? "Alle år" : "All years";

if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    try { cms.getRequestContext().setLocale(new Locale(loc)); } catch (Exception e) {}
}

String year = cms.getRequest().getParameter("year");
if (year == null || year.isEmpty()) {
    //out.println("<!-- Required parameter 'year' was missing. Unable to continue. -->");
    //return;
    year = createYearParameter(currentYear);
} else {
    year = createYearParameter(year);
}

//String yearAPIParam = year + "-01-01T00:00:00Z.." + year + "-12-31T23:59:59Z";

%>
<form action="<%= cms.link(requestFileUri) %>" method="get">
    
    <label for="pubyear"><%= LABEL_YEAR_SELECT %>: </label>
    <!--<select name="<%= FACET_PREFIX + Publication.JSON_KEY_PUB_TIME %>" onchange="submit()" id="pubyear">-->
    <select name="year" onchange="submit()" id="pubyear">
        <!--<option value=""><%= LABEL_YEAR_SELECT_OPT_ALL %></option>-->
        <%
        //*
        for (int yOpt = new GregorianCalendar().get(Calendar.YEAR); yOpt >= 1970; yOpt--) {
            String paramYearValue = createYearParameter(yOpt);
            //String paramYearValue = "" + yOpt + "-01-01T00:00:00Z.." + yOpt + "-12-31T23:59:59Z";
            out.println("<option value=\"" + yOpt + "\"" 
                        + (paramYearValue.equals(year) ? " selected=\"selected\"" : "") + ">" 
                            + yOpt
                        + "</option>");
        }
        //*/
        %>
    </select>
</form>

<%

final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
//final int LIMIT = 9999;

//
// Parameters: Used when querying the service.
//
Map<String, String[]> params = new HashMap<String, String[]>();
params.put("q", new String[]{ "" }); // Use a catch-all search phrase
params.put("filter-published_sort", new String[] { year }); // Filter on the given year (or the current year, if no year was given)
//params.put("filter-published-year", new String[] { year }); // Filter on the given year (or the current year, if no year was given)
//params.put("sort", new String[]{ "-publication_year" }); // Sort by publish year, descending
//params.put("sort", new String[]{ "-published-year,-published-date" }); // Sort by publish year, descending
//params.put("sort", new String[]{ "people.last_name,people.first_name" }); // Sort by name
params.put("filter-organisations.id", new String[] { "npolar.no" }); // Filter on checked "Yes, publication is affiliated to NP activity" (require this box was checked)
params.put("limit", new String[]{ "all" }); // Set an entry limit
//params.put("filter-draft", new String[]{ "no" }); // Don't allow drafts
//params.put("filter-state", new String[]{ "published" }); // Allow only published publications

Map<String, String[]> defaultParams = new HashMap<String, String[]>();
defaultParams.put("not-draft",              new String[]{ "yes" }); // Don't include drafts
defaultParams.put("filter-state",           new String[]{ Publication.JSON_VAL_STATE_PUBLISHED }); // Require state: published
//defaultParams.put("filter-state",           new String[]{ Publication.JSON_VAL_STATE_PUBLISHED + "|" + Publication.JSON_VAL_STATE_ACCEPTED }); // Require state: published or accepted
defaultParams.put("facets",                 new String[]{ "false" }); // No facets
defaultParams.put("sort",                   new String[]{ "people.last_name,people.first_name" }); // Sort by name
//defaultParams.put("sort",                   new String[]{ "-published-year,-published-date" }); // Sort by publish date, descending (and this is the sort parameter for that)

//
// Access the service
//

GroupedCollection<Publication> publications = null;
PublicationService pubService = null;
ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
try {
    pubService = new PublicationService(cms.getRequestContext().getLocale());
    pubService.setDefaultParameters(defaultParams);
    publications = pubService.getPublications(params);
    
    out.println("<!-- \nAPI URL: \n" + pubService.getLastServiceURL() + " \n-->");
    
    if (COMMENTS) { out.println("Read " + (publications == null ? "null" : publications.size()) + " publications from service URL <a href=\"" + pubService.getLastServiceURL() + "\" target=\"_blank\">" + pubService.getLastServiceURL() + "</a>."); }
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

int totalResults = -1;


// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------
if (COMMENTS) out.println("<!-- Ready to output HTML, " + publications.size() + " publication(s) in this set. -->");
if (!publications.isEmpty()) {
    out.println("<h2>" + publications.size() + " " + labels.getString(Labels.PUB_0).toLowerCase() + " for " + year.substring(0,4) + "</h2>");
    
    // Get types of publications
    Iterator<String> iTypes = publications.getTypesContained().iterator();
    while (iTypes.hasNext()) {
        String listType = iTypes.next();
        //out.println("<div class=\"toggleable open\">");
        out.println("<div class=\"toggleable collapsed\">");
        List pubGroup = publications.getListGroup(listType);
        
        Collections.sort(pubGroup, Publication.COMPARATOR_CITESTRING);
        
        Iterator<Publication> iPubs = pubGroup.iterator();
        if (iPubs.hasNext()) {
            //out.println("<h2>" + cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListByType(listType).size() + ")</h2>");
            out.println("<a class=\"toggletrigger\" href=\"javascript:void(0);\">"
                                + cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListGroup(listType).size() + ")"
                        + "</a>");
            
            out.println("<div class=\"toggletarget\">");
            
            out.println("<ul class=\"fullwidth line-items\">");
            while (iPubs.hasNext()) {
                String citeString = iPubs.next().toString();
                if ("yes".equals(request.getParameter("clean"))) {
                    // NB: Requires the Jsoup library! (It's included in the NPI forms module)
                    org.jsoup.nodes.Document doc = org.jsoup.Jsoup.parse(citeString);
                    org.jsoup.safety.Whitelist whitelist = 
                            org.jsoup.safety.Whitelist.simpleText()
                            .addTags("span", "em", "br")
                            .addAttributes("span", "style", "class", "id")
                            .addAttributes("em", "style", "class", "id");
                    
                    citeString = org.jsoup.Jsoup.clean(doc.html(), whitelist).replaceAll("\\n", "");
                }
                out.println("<li>" + citeString + "</li>");
            }
            out.println("</ul>");
            
            out.println("</div>");
        }
        out.println("</div>");
    }
    /*<script type="text/javascript">
    $('.toggleable.collapsed > .toggletarget').slideUp(1);
    $('.toggleable.open > .toggletrigger').append(' <em class="icon-up-open-big"></em>');
    $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>');
    $('.toggleable > .toggletrigger').click(function() { $(this).next('.toggletarget').slideToggle(500); $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big'); });
    </script>*/
    %>
    <%
}
else {
    out.println("<!-- No publications found on " + pubService.getLastServiceURL() + " -->");
}
%>