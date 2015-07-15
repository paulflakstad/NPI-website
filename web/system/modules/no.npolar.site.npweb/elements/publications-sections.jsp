<%-- 
    Document   : publications-sections, based on publications-ice
    Created on : Aug 13, 2014, 2:13:00 PM
    Author     : Paul-Inge Flakstad, NPI
--%><%@page import="no.npolar.data.api.*,
                 no.npolar.util.CmsAgent,
                 java.net.URLEncoder,
                 java.util.Calendar,
                 java.util.GregorianCalendar,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
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

/**
 * Creates a normalized year parameter string based on the given year.
 * @param yearLow A 4-character year string, e.g. "2014" or "1337", representing the low end of the range. Cannot be null.
 * @param yearHigh A 4-character year string, e.g. "2014" or "1337", representing the high end of the range. Can be null (in which case the range will be the entire low year).
 * @return a normalized year parameter string, ready to use in API requests.
 */
public static String createYearRangeParameter(String yearLow, String yearHigh) {
    if (yearHigh == null)
        return createYearParameter(yearLow);
    try {
        if (yearLow == null || yearLow.length() != 4 || yearHigh.length() != 4)
            throw new Exception();
    } catch (Exception e) {
        throw new IllegalArgumentException("One (or both) of the arguments could not be interpreted as a year. Each argument must be a string of 4 digits.");
    }
    try {
        int yl = Integer.parseInt(yearLow);
        int yh = Integer.parseInt(yearHigh);
        if (yh < yl)
            throw new Exception();
    } catch (Exception e) {
        throw new IllegalArgumentException("Something failed while attempting to rip apart the space-time continuum.</p>"
                + "<p>Please <strong>adjust the start/end year</strong> to save the universe from destruction.");
    }
    return yearLow + PARAM_VAL_PART_YEAR_BEGIN + PARAM_VAL_RANGE_DELIMITER + yearHigh + PARAM_VAL_PART_YEAR_END;
}
/**
 * @see
 */
public static String createYearRangeParameter(int yearLow, int yearHigh) {
    if (yearHigh == -1)
        return createYearParameter(String.valueOf(yearLow));
    return createYearRangeParameter(String.valueOf(yearLow), String.valueOf(yearHigh));
}

public static boolean isInteger(String s) {
    if (s == null || s.isEmpty())
        return false;
    try { Integer.parseInt(s); } catch(NumberFormatException e) { return false; }
    return true;
}
%><%
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
String requestFileUri   = cms.getRequestContext().getUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();


final boolean COMMENTS  = false;

final String LABEL_YEAR_SELECT_HEADING = loc.equalsIgnoreCase("no") ? "Velg tidsperiode" : "Select time range";
final String LABEL_YEAR_SELECT = loc.equalsIgnoreCase("no") ? "År" : "Year";
final String LABEL_YEAR_SELECT_OPT_ALL = loc.equalsIgnoreCase("no") ? "Alle år" : "All years";
final String LABEL_RANGE_FROM = loc.equalsIgnoreCase("no") ? "Fra " : "From ";
final String LABEL_RANGE_TO = loc.equalsIgnoreCase("no") ? " til " : " to ";
final String LABEL_RANGE_UPDATE = loc.equalsIgnoreCase("no") ? "Oppdater" : "Update";
final String LABEL_RANGE_INFO_START = loc.equalsIgnoreCase("no") ? "Lister nå alt" : "Currently listing everything";

translations.put("N-ICE", "N-ICE");
translations.put("ICE Fluxes", loc.equalsIgnoreCase("no") ? "ICE-havis" : "ICE Fluxes");
translations.put("ICE Antarctica", loc.equalsIgnoreCase("no") ? "ICE-Antarktis" : "ICE Antarctica");
translations.put("ICE Ecosystems", loc.equalsIgnoreCase("no") ? "ICE-økosystemer" : "ICE Ecosystems");
translations.put("Biodiversity", loc.equalsIgnoreCase("no") ? "Biodiversitet" : "Biodiversity");
translations.put("Environmental pollutants", loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Environmental pollutants");
translations.put("Geology and geophysics", loc.equalsIgnoreCase("no") ? "Geologi og geofysikk" : "Geology and geophysics");
translations.put("Oceans and sea ice", loc.equalsIgnoreCase("no") ? "Hav og havis" : "Oceans and sea ice");
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

Calendar todayCal = new GregorianCalendar();

final String PARAM_NAME_YLOW = "ylow";
final String PARAM_NAME_YHIGH = "yhigh";

final int LIMIT_YLOW = 2009;
final int LIMIT_YHIGH = todayCal.get(Calendar.YEAR);

// Year parameters 
int ylow = -1;
int yhigh = -1;
// Update range years from params, if needed
if (isInteger(request.getParameter(PARAM_NAME_YLOW)))
    ylow = Integer.valueOf(request.getParameter(PARAM_NAME_YLOW)).intValue();
if (isInteger(request.getParameter(PARAM_NAME_YHIGH)))
    yhigh = Integer.valueOf(request.getParameter(PARAM_NAME_YHIGH)).intValue();

if (ylow > -1) {
    try {
        year = createYearRangeParameter(ylow, yhigh);
    } catch (Exception e) {
        out.println("<h2>Whoops ..!</h2>");
        out.println("<p>" + e.getMessage() + "</p>");
        return;
    }
}

%>
<!--
<div class="searchbox-big">
    <h2><%= LABEL_YEAR_SELECT_HEADING %></h2>
    <form action="<%= cms.link(requestFileUri) %>" method="get">
        <label for="pubyear"><%= LABEL_YEAR_SELECT %>: </label>
        <select name="year" onchange="submit()" id="pubyear">
            <option value=""><%= LABEL_YEAR_SELECT_OPT_ALL %></option>
            <%
            for (int yOpt = LIMIT_YHIGH; yOpt >= LIMIT_YLOW; yOpt--) {
                String paramYearValue = createYearParameter(yOpt);
                out.println("<option value=\"" + yOpt + "\"" 
                            + (paramYearValue.equals(year) ? " selected=\"selected\"" : "") + ">" // Selected?
                                + yOpt
                            + "</option>");
            }
            %>
        </select>
    </form>
</div>
-->
            
<div class="searchbox-big" id="range-tools" style="">
    <h2><%= LABEL_YEAR_SELECT_HEADING %></h2>
    <!--<p class="smalltext" style="background:#06d; color:#fff; padding:0.2em 1em;"><%= LABEL_RANGE_INFO_START %><%= ylow > -1 ? (" "+LABEL_RANGE_FROM.toLowerCase()+" "+ylow) : "" %><%= yhigh > ylow ? (LABEL_RANGE_TO+yhigh) : "" %>.</p>-->
    <form action="<%= cms.link(requestFileUri) %>" method="get">   
        <%= LABEL_RANGE_FROM %><input type="number" value="<%= ylow > -1 ? ylow : "" %>" maxlength="4" pattern="[0-9]*" name="<%= PARAM_NAME_YLOW %>" id="range-year-low" style="padding:0.5em; border:1px solid #ddd; width:4em; font-size:1.25em;" /> 
	<%= LABEL_RANGE_TO %><input type="number" value="<%= yhigh > -1 ? yhigh : "" %>" maxlength="4" pattern="[0-9]*" name="<%= PARAM_NAME_YHIGH %>" id="range-year-high" style="padding:0.5em; border:1px solid #ddd; width:4em; font-size:1.25em;" />
        <div id="range-slider" style="margin: 2em 40px 0;"></div> 
        <br />
        <input type="submit" value="<%= LABEL_RANGE_UPDATE %>" style="margin-top:1em;" />
    </form>
</div>
<p style="font-weight:bold; text-align:center;"><%= LABEL_RANGE_INFO_START %><%= ylow > -1 ? (" "+LABEL_RANGE_FROM.toLowerCase()+" "+ylow) : "" %><%= yhigh > ylow ? (LABEL_RANGE_TO+yhigh) : "" %>:</p>
<%

final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
final int LIMIT = 9999;

// Available programmes
String[] programmes = new String[] { 
                                    "N-ICE"
                                    ,"ICE Antarctica"
                                    ,"ICE Fluxes"
                                    ,"ICE Ecosystems"
                                    ,"Biodiversity"
                                    ,"Environmental pollutants"
                                    ,"Geology and geophysics"
                                    ,"Oceans and sea ice"
                                };
// Loop the programmes
for (int j = 0; j < programmes.length; j++) {
    
    // Parameters used to specify a particular results list
    Map<String, String[]> params = new HashMap<String, String[]>();
    params.put("q", new String[]{ "" }); // Catch-all search term
    params.put("sort", new String[]{ "-published_sort" }); // Sort by publish time
    params.put("limit", new String[]{ Integer.toString(LIMIT) }); // Limit results
    params.put("not-draft", new String[]{ "yes" }); // Don't include drafts
    params.put("filter-state", new String[]{ Publication.JSON_VAL_STATE_PUBLISHED + "|" + Publication.JSON_VAL_STATE_ACCEPTED }); // Require state: published or accepted
    params.put("filter-programme", new String[] { URLEncoder.encode(programmes[j], "utf-8") }); // Require the particular programme currently in the loop
    
    if (year != null) { params.put("filter-published_sort", new String[] { year }); } // If a year was selected by the user, limit results to that year
    
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
        out.println("<div class=\"toggleable collapsed\">");
        out.println("<h2 class=\"toggletrigger\" style=\"margin-top:2px;\">" + translate(programmes[j]) + " (" + publications.size() + ")</h2>");
        out.println("<div class=\"toggletarget\">");
        // Get types of publications
        Iterator<String> iTypes = publications.getTypesContained().iterator();
        while (iTypes.hasNext()) {
            String listType = iTypes.next();
            Iterator<Publication> iPubs = publications.getListGroup(listType).iterator();
            if (iPubs.hasNext()) {
                out.println("<div class=\"toggleable collapsed\">");
                out.println("<h3 class=\"toggletrigger\" style=\"margin:0 0 2px 1em; font-size:1.25em;\">" + cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListGroup(listType).size() + ")</h3>");
                out.println("<div class=\"toggletarget\" style=\"margin:-2px 0 2px 1.25em;\">");
                out.println("<ul class=\"fullwidth indent line-items\">");
                while (iPubs.hasNext()) {
                    out.println("<li>" + iPubs.next().toString() + "</li>");
                }
                out.println("</ul>");
                out.println("</div>");
                out.println("</div>");
            }
        }
        out.println("</div>");
        out.println("</div>");
    }
    else {
        out.println("<h2 class=\"toggletrigger\" style=\"color:#bbb; margin-top:2px;\">" + translate(programmes[j]) + " (0)</h2>");
    }
}

/*<script type="text/javascript">
    $('.toggleable.collapsed > .toggletarget').slideUp(1);
    $('.toggleable.open > .toggletrigger').append(' <em class="icon-up-open-big"></em>');
    $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>');
    $('.toggleable > .toggletrigger').click(function() { $(this).next('.toggletarget').slideToggle(500); $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big'); });
</script>*/
%>
<script type="text/javascript">
$('#range-slider').noUiSlider({
    range: {
        'min': <%= LIMIT_YLOW %>,
        'max': <%= LIMIT_YHIGH %>
    }
    ,start: [<%= ylow > -1 ? ylow : String.valueOf(LIMIT_YLOW) %>,<%= yhigh > -1 ? yhigh : String.valueOf(LIMIT_YHIGH) %>]
    ,connect: true
    ,step:1
    ,serialization: {
        lower: [
            $.Link({
                target: $('#range-year-low'),
                format: { decimals: 0 }
            })
        ],
        upper: [
            $.Link({
                target: $('#range-year-high'),
                format: { decimals: 0 }
            })
        ]
    }
});
</script>
