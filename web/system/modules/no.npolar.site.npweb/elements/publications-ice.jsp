<%-- 
    Document   : publications-ice, based on publications-annual-report
    Created on : Jan 15, 2014, 9:51:15 AM
    Author     : flakstad
--%><%@page import="no.npolar.data.api.*,
                 no.npolar.util.CmsAgent,
                 java.net.URLEncoder,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
                 java.util.Calendar,
                 java.util.GregorianCalendar,
                 org.opencms.main.OpenCms,
                 org.opencms.security.CmsRole" session="true"
%><%!
public static Map<String, String> translations = new HashMap<String, String>();

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
public String translate(String s) {
    String translation = translations.get(s);
    return translation != null ? translation : s;
}

/** Facet (filter) parameter name prefix. */
//public final static  String FACET_PREFIX = "filter-";
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

translations.put("N-ICE", "N-ICE");
translations.put("ICE Fluxes", loc.equalsIgnoreCase("no") ? "ICE-havis" : "ICE Fluxes");
translations.put("ICE Antarctica", loc.equalsIgnoreCase("no") ? "ICE-Antarktis" : "ICE Antarctica");
translations.put("ICE Ecosystems", loc.equalsIgnoreCase("no") ? "ICE-økosystemer" : "ICE Ecosystems");
//translations.put("", loc.equalsIgnoreCase("no") ? "" : "");


if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    try { cms.getRequestContext().setLocale(new Locale(loc)); } catch (Exception e) {}
}

String year = cms.getRequest().getParameter("year");
if (year != null && !year.isEmpty()) {
    //out.println("<!-- Required parameter 'year' was missing. Unable to continue. -->");
    //return;
    if (year.length() == 4)
        year = createYearParameter(year);
} else {
    year = null;
}

/*String year = cms.getRequest().getParameter("year");
if (year == null) {
    //year = "2014";
    //out.println("<!-- Nothing to work with here... -->");
    //return;
} 
else {
    try {
        Integer.valueOf(year);
    } catch (Exception e) {
        year = null; // Year was not a number ? ditch it
    }
}*/

%>
<form action="<%= cms.link(requestFileUri) %>" method="get">
    <label for="pubyear"><%= LABEL_YEAR_SELECT %>: </label>
    <!--<select name="<%= SearchFilter.PARAM_NAME_PREFIX + Publication.JSON_KEY_PUB_TIME %>" onchange="submit()" id="pubyear">-->
    <select name="year" onchange="submit()" id="pubyear">
        <option value=""><%= LABEL_YEAR_SELECT_OPT_ALL %></option>
        <%
        //*
        for (int yOpt = 2014; yOpt >= 1970; yOpt--) {
            String paramYearValue = createYearParameter(yOpt);
            //String paramYearValue = "" + yOpt + "-01-01T00:00:00Z.." + yOpt + "-12-31T23:59:59Z";
            out.println("<option value=\"" + yOpt/*paramYearValue*/ + "\"" 
                        + (paramYearValue.equals(year) ? " selected=\"selected\"" : "") + ">" 
                            + yOpt
                        + "</option>");
        }
        //*/
        %>
    </select>
    <!--<%= loc.equalsIgnoreCase("no") ? "Årstall" : "Year" %>: -->
    <!--<select id="ysel" name="year" onchange="submit()">-->
        <%
        /*for (int i = 2014; i >= 2009; i--)
            out.println("<option value=\"" + i + "\"" + (String.valueOf(i).equals(year) ? " selected=\"selected\"" : "") + ">" + i + "</option>");*/
        %>
    <!--</select>-->
</form>

<%

final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
final int LIMIT = 9999;

// Available ICE programmes
String[] iceProgs = new String[] { 
                                    "N-ICE"
                                    ,"ICE Antarctica"
                                    ,"ICE Fluxes"
                                    ,"ICE Ecosystems" 
                                };
// Loop the ICE programmes
for (int j = 0; j < iceProgs.length; j++) {
    
    // Parameters used to specify a particular results list
    Map<String, String[]> params = new HashMap<String, String[]>();
    params.put(APIService.PARAM_QUERY, new String[]{ "" }); // Catch-all search term
    params.put(APIService.PARAM_SORT_BY, new String[]{ APIService.PARAM_VAL_PREFIX_REVERSE.concat(Publication.JSON_KEY_PUB_TIME) }); // Sort by publish time
    params.put(APIService.PARAM_RESULTS_COUNT, new String[]{ Integer.toString(LIMIT) }); // Limit results
    params.put(APIService.PARAM_MODIFIER_NOT.concat(Publication.JSON_KEY_DRAFT), new String[]{ Publication.JSON_VAL_DRAFT_TRUE }); // Don't include drafts
    params.put(SearchFilter.PARAM_NAME_PREFIX.concat(Publication.JSON_KEY_STATE), new String[]{ Publication.JSON_VAL_STATE_PUBLISHED + "|" + Publication.JSON_VAL_STATE_ACCEPTED }); // Require state: published or accepted
    params.put(SearchFilter.PARAM_NAME_PREFIX.concat(Publication.JSON_KEY_PROGRAMMES), new String[] { URLEncoder.encode(iceProgs[j], "utf-8") }); // Require the particular ICE programme currently in the loop
    
    if (year != null) { params.put(SearchFilter.PARAM_NAME_PREFIX.concat(Publication.JSON_KEY_PUB_TIME), new String[] { year }); } // If a year was selected by the user, limit results to that year
    
    // Collection to hold matching publications
    GroupedCollection<Publication> publications = null;
    PublicationService pubService = null;
    try {
        pubService = new PublicationService(cms.getRequestContext().getLocale());
        publications = pubService.getPublications(params);
        if (COMMENTS) { out.println("Read " + (publications == null ? "null" : publications.size()) + " publications from service URL <a href=\"" + pubService.getLastServiceURL() + "\" target=\"_blank\">" + pubService.getLastServiceURL() + "</a>."); }
    } catch (Exception e) {
        out.println("An unexpected error occured while constructing the publications list.");
        if (LOGGED_IN_USER) {
            out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                        + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                            + getStackTrace(e) 
                        + "</div>");
        }
        return; // Abort mission!
    }



    // -------------------------------------------------------------------------
    // HTML output
    //--------------------------------------------------------------------------
    
    out.println("<!--\nAPI URL:\n" + pubService.getLastServiceURL() + "\n-->");
    if (COMMENTS) out.println("<!-- Ready to output HTML, " + publications.size() + " publication(s) in this set. -->");
    
    if (!publications.isEmpty()) {
        %>
        <div class="toggleable collapsed">
            <h2 class="toggletrigger"><%= cms.labelUnicode("label.np.publist.heading") %> for <%= translate(iceProgs[j]) %> (<%= publications.size() %>)</h2>
            <div class="toggletarget">
            <%
            // Get types of publications
            Iterator<String> iTypes = publications.getTypesContained().iterator();
            while (iTypes.hasNext()) {
                String listType = iTypes.next();
                Iterator<Publication> iPubs = publications.getListGroup(listType).iterator();
                if (iPubs.hasNext()) {
                    %>
                    <h3><%= cms.labelUnicode("label.np.pubtype." + listType) %> (<%= publications.getListGroup(listType).size() %>)</h3>
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
        </div>
        <%
    }
    else {
        %>
        <h4><em>0 <%= cms.labelUnicode("label.np.publist.heading").toLowerCase() %> for <%= translate(iceProgs[j]) %></em></h4>
        <%
    }
}
/*<script type="text/javascript">
    $('.toggleable.collapsed > .toggletarget').slideUp(1);
    $('.toggleable.open > .toggletrigger').append(' <em class="icon-up-open-big"></em>');
    $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>');
    $('.toggleable > .toggletrigger').click(function() { $(this).next('.toggletarget').slideToggle(500); $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big'); });
</script>*/
%>
