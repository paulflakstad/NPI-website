<%-- 
    Document   : publications-annual-report
    Created on : Dec 13, 2013, 1:12:32 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="no.npolar.data.api.*,
                 no.npolar.util.CmsAgent,
                 java.text.Collator,
                 java.util.Calendar,
                 java.util.Comparator,
                 java.util.Collections,
                 java.util.GregorianCalendar,
                 java.util.HashMap,
                 java.util.Iterator,
                 java.util.List,
                 java.util.Locale,
                 java.util.Map,
                 java.util.ResourceBundle,
                 org.apache.commons.lang.StringUtils,
                 org.opencms.util.CmsHtmlExtractor,
                 org.opencms.util.CmsStringUtil,
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
public final static  String FACET_PREFIX = SearchFilter.PARAM_NAME_PREFIX;
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
 * Returns the sort string for the given cite string. For example, "von Quillfeldt"
 * will return "QUILLFELDT", "Nilsen" will return "NILSEN", and "Aars" will 
 * return "AARS".
 */
public static String getSortReady(String citeString) {
    if (citeString == null || CmsStringUtil.isEmptyOrWhitespaceOnly(citeString))
        return ""; // Nothing to work with ...
    
    int i = 0;
    while (true) {
        try {
            String letter = String.valueOf(citeString.charAt(i));
            if (StringUtils.isAllUpperCase(letter)) {
                try {
                    return letter + citeString.substring(i+1).toUpperCase(); // Uppercase letter - return it
                } catch (Exception ee) {
                    return letter.toUpperCase();
                }
            }
        } catch (Exception e) {
            break; // Evaluated all letters - break the endless loop
        }
        i++; // "Continue to next letter"
    }
    try {
        return String.valueOf(citeString).toUpperCase(); // Fallback to the cite string itself, but all uppercase
    } catch (Exception e) {
        return "A"; // Last resort (should never happen really)
    }
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

if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    try { cms.getRequestContext().setLocale(new Locale(loc)); } catch (Exception e) {}
}

String year = cms.getRequest().getParameter("year");
if (year == null || year.isEmpty()) {
    year = createYearParameter(currentYear);
} else {
    year = createYearParameter(year);
}

%>
<style type="text/css">
    .publications a {
        text-decoration: none;
        border-bottom: 1px solid rgba(21, 112, 177, 0.45);
        transition: all 0.3s ease-in-out;
    }
    .publications a:hover,  
    .publications a:focus {
        border-color: transparent;
    }
</style>
<form action="<%= cms.link(requestFileUri) %>" method="get">
    
    <label for="pubyear"><%= LABEL_YEAR_SELECT %>: </label>
    <select name="year" onchange="submit()" id="pubyear">
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
        
//
// Access the service
//

GroupedCollection<Publication> publications = null;
PublicationService pubService = null;
        
ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
try {
    pubService = new PublicationService(cms.getRequestContext().getLocale());
    pubService.addDefaultParameter(
            // Don't include drafts
            PublicationService.modNot(Publication.Key.DRAFT), 
            Publication.Val.DRAFT_TRUE
    ).addDefaultParameter(
            // Require state: published
            PublicationService.modFilter(Publication.Key.STATE), 
            Publication.Val.STATE_PUBLISHED
    ).addDefaultParameter(
            // No facets
            PublicationService.Param.FACETS, 
            PublicationService.ParamVal.FACETS_NONE
    ).addDefaultParameter(
            // Sort by last name,first name
            PublicationService.Param.SORT_BY,
            PublicationService.combine(PublicationService.Delimiter.AND, 
                    Publication.Key.PEOPLE+"."+Publication.Key.LNAME, 
                    Publication.Key.PEOPLE+"."+Publication.Key.FNAME)
    );
    pubService.setFreetextQuery(
            // Catch-all freetext query
            ""
    ).addFilter(
            // Filter on year
            Publication.Key.PUB_TIME,
            year
    ).addFilter(
            // Filter on NPI as organization
            Publication.Key.ORGS_ID,
            Publication.Val.ORG_NPI
    ).addParameter(
            // No limit on number of results
            PublicationService.Param.RESULTS_LIMIT,
            PublicationService.ParamVal.RESULTS_LIMIT_NO_LIMIT
    );
    // Done setting the service parameters
    
    // Get the publications
    publications = pubService.getPublications();
    
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




// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------

if (COMMENTS) out.println("<!-- Ready to output HTML, " + publications.size() + " publication(s) in this set. -->");
if (!publications.isEmpty()) {
    %>
    <h2><%= publications.size() %> <%= labels.getString(Labels.PUB_0).toLowerCase() %> for <%= year.substring(0,4) %></h2>
    <%
    
    final Comparator<Publication> COMPARATOR_CITESTRING =
            new Comparator<Publication>() {
                //@Override
                public int compare(Publication pub1, Publication pub2) {
                    //Collator comparer = Collator.getInstance(new Locale("no")); // Norwegian; put Æ Ø, Å and Aa last
                    Collator comparer = Collator.getInstance(new Locale("en")); // English; place Æ Ø and Å last, but Aa is sorted normally
                    try {
                        return comparer.compare(
                                getSortReady(CmsHtmlExtractor.extractText(pub1.toString(), "utf-8")), 
                                getSortReady(CmsHtmlExtractor.extractText(pub2.toString(), "utf-8"))
                        );
                    } catch (Exception e) {
                        return comparer.compare(getSortReady(pub1.toString()), getSortReady(pub2.toString()));
                    }
                }
            };
    
    
    // Get types of publications
    Iterator<String> iTypes = publications.getTypesContained().iterator();
    while (iTypes.hasNext()) {
        String listType = iTypes.next();
        //out.println("<div class=\"toggleable open\">");
        %>
        <div class="toggleable open">
        <%
        List<Publication> pubGroup = publications.getListGroup(listType);
        
        Collections.sort(pubGroup, COMPARATOR_CITESTRING);
        //Collections.sort(pubGroup, Publication.COMPARATOR_CITESTRING);
        
        Iterator<Publication> iPubs = pubGroup.iterator();
        if (iPubs.hasNext()) {
            //out.println("<h2>" + cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListByType(listType).size() + ")</h2>");
            %>
            <a class="toggletrigger" href="javascript:void(0);">
                <%= cms.labelUnicode("label.np.pubtype.".concat(listType)) %> (<%= publications.getListGroup(listType).size() %>)
            </a>
            <div class="toggletarget publications">
            <%
            boolean clean = "yes".equals(request.getParameter("clean"));
            
            if (!clean){
                // Use list only for online purposes (and <p> tags for "offline" purposes)
                %>
                <ul class="fullwidth line-items">
                <%
            }
            
            while (iPubs.hasNext()) {
                Publication p = iPubs.next();
                
                // Check if this is a part-contribution (e.g. chapter in a book
                // or report): If yes, AND if the parent (e.g. the complete 
                // book/report) is also published by the NPI, then SKIP THIS ONE
                if (p.isPartContribution()) {
                    try {
                        Publication parent = new PublicationService(locale).get(p.getParentId());
                        String parentPublisher = parent.getPublisher();
                        if (StringUtils.containsIgnoreCase(parentPublisher, "Norwegian Polar Institute") || StringUtils.containsIgnoreCase(parentPublisher, "Norsk Polarinstitutt")) {
                            out.println("<!--\nskipped (parent already in list):\n" + p.getTitle() + "\n-->");
                            continue;
                        }
                    } catch (Exception e) {}
                }
                
                String citeString = p.toString();
                if (clean) {
                    // NB: Requires the Jsoup library! 
                    // (It's included in the NPI forms module)
                    org.jsoup.nodes.Document doc = org.jsoup.Jsoup.parse(citeString);
                    org.jsoup.safety.Whitelist whitelist = 
                            org.jsoup.safety.Whitelist.simpleText()
                            .addTags("span", "em", "br")
                            .addAttributes("span", "style", "class", "id")
                            .addAttributes("em", "style", "class", "id");
                    
                    citeString = org.jsoup.Jsoup.clean(doc.html(), whitelist)
                            .replaceAll("\\n", "")
                            .replace("<br />DOI: ", "DOI:&nbsp;")
                            .replaceAll("npi\\\"\\>", "npi\" style=\"font-weight:bold;\">");
                }
                // Use <p> for "offline" purposes, otherwise use a list item
                out.println((clean ? "<p>" : "<li>") + citeString + (clean ? "</p>" : "</li>"));
            }
            
            if (!clean) {
                %>
                </ul>
                <%
            }
            %>
            </div>
            <%
        }
        %>
        </div>
        <%
    }
}
else {
    %>
    <!-- No publications found on " + <%= pubService.getLastServiceURL() %> + " -->
    <%
}
%>