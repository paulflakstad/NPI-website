<%-- 
    Document   : publications-loader
    Created on : Apr 27, 2016, 11:29:47 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="no.npolar.data.api.*" %>
<%@page import="no.npolar.data.api.util.APIUtil" %>
<%@page import="no.npolar.util.CmsAgent" %>
<%@page import="no.npolar.util.SystemMessenger" %>
<%@page import="org.apache.commons.lang.StringUtils" %>
<%@page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@page import="org.markdown4j.Markdown4jProcessor" %>
<%@page import="java.util.Set" %>
<%@page import="java.io.PrintWriter" %>
<%@page import="org.opencms.jsp.CmsJspActionElement" %>
<%@page import="java.io.IOException" %>
<%@page import="java.util.Locale" %>
<%@page import="java.net.URLDecoder" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="org.opencms.main.OpenCms" %>
<%@page import="org.opencms.util.CmsStringUtil" %>
<%@page import="org.opencms.util.CmsRequestUtil" %>
<%@page import="java.io.InputStreamReader" %>
<%@page import="java.io.BufferedReader" %>
<%@page import="java.net.URLConnection" %>
<%@page import="java.net.URL" %>
<%@page import="java.net.HttpURLConnection" %>
<%@page import="java.util.ArrayList" %>
<%@page import="java.util.Arrays" %>
<%@page import="java.util.GregorianCalendar" %>
<%@page import="java.util.Calendar" %>
<%@page import="java.util.List" %>
<%@page import="java.util.Date" %>
<%@page import="java.util.Map" %>
<%@page import="java.util.HashMap" %>
<%@page import="java.util.Iterator" %>
<%@page import="java.util.ResourceBundle" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="org.opencms.file.CmsObject" %>
<%@page import="org.opencms.file.CmsProject" %>
<%@page import="org.opencms.file.CmsResource" %>
<%@page import="org.opencms.json.JSONArray" %>
<%@page import="org.opencms.json.JSONObject" %>
<%@page import="org.opencms.json.JSONException" %>
<%@page import="org.opencms.mail.CmsSimpleMail" %>
<%@page contentType="text/html" %>
<%@page pageEncoding="UTF-8" %>
<%@page session="true" %>
<%@page trimDirectiveWhitespaces="true" %>
<%!
    /**
     * Gets a string containing the last name(s) of a publication's main 
     * contributor(s).
     * <p>
     * A maximum of 3 names are included. If there are more contributors, only 
     * the main contributor's name is included, and "et al." is appended.
     * <p>
     * A "contributor" is either an author or an editor. Authors supercede 
     * editors - we use editor name(s) only if the list of authors is empty.
     */
    public static String getContributorsShort(List<PublicationContributor> contribs, String suffixSingular, String suffixPlural) {
        String s = "";
        if (!contribs.isEmpty()) {

            boolean trimmed = false;
            int numContribs = contribs.size();
            String suffix = numContribs > 1 ? suffixPlural : suffixSingular;
            if (numContribs > 3) {
                contribs = contribs.subList(0, 1);
                trimmed = true;
                numContribs = contribs.size();
            }

            Iterator<PublicationContributor> iContribs = contribs.iterator();
            int contribNo = 0;
            while (iContribs.hasNext()) {
                PublicationContributor contrib = iContribs.next();
                s += contrib.getLastName();
                if (numContribs == 1 && trimmed) {
                    s += " et al.";
                } else if (iContribs.hasNext()) { 
                    s += ++contribNo == (numContribs-1) ? " &amp; " : ", ";
                }
            }
            if (suffix != null) {
                s += " " + suffix;
            }
        }
        return s;
    }
    /* Map storage for default parameters. */
    //static Map<String, String> dp = new HashMap<String, String>();
    /* Stop words. */
    //static List<String> sw = new ArrayList<String>();

    /*
    protected static String toParameterString(Map<String, String[]> params, String ... exclusions) {
        if (params.isEmpty()) {
            return "";
        }

        List<String> e = new ArrayList<String>(0);
        for (String exclusion : exclusions) {
            e.add(exclusion);
        }

        String s = "";
        Iterator<String> i = params.keySet().iterator();
        while (i.hasNext()) {
            String key = i.next(); // e.g. "facets" (parameter name)
            if (e.contains(key)) {
                continue;
            }
            String[] values = params.get(key); // e.g. get the parameter value(s) for "facets"
            s += key + "=" + APIService.combine(APIService.Delimiter.AND, values) + (i.hasNext() ? "&" : "");
        }
        return s;
    }
    */

    /**
     * Gets a particular parameter value.
     * 
     * If no such parameter exists, an empty string is returned.
     */
    public static String getParameter(CmsAgent cms, String paramName) {
        String param = cms.getRequest().getParameter(paramName);
        return param != null ? param : "";
    }

    /**
     * Converts the given string from markdown to html.
     */
    public static String markdownToHtml(String s) {
        try { return new Markdown4jProcessor().process(s); } catch (Exception e) { return s + "\n<!-- Could not process this as markdown -->"; }
    }

    /**
     * Checks if the given string represents an integer.
     */
    public static boolean isInteger(String s) {
        if (s == null || s.isEmpty())
            return false;
        try { Integer.parseInt(s); } catch(NumberFormatException e) { return false; }
        return true;
    }

    /**
     * Converts the given low and high years to a normalized time range string, 
     * which can be used as a parameter value in requests for publications.
     * 
     * @param yearLo The lower bound year (inclusive).
     * @param yearHi The upper bound year (inclusive).
     * @return A normalized time range string, based on the low and high years.
     */ 
    public static String normalizeTimestampFilterValue(int yearLo, int yearHi) {
        String yearRangeFilterVal = "";
        try {
            if (yearLo > -1) {
                yearRangeFilterVal +=
                        yearLo + "-01-01T00:00:00Z" 
                        + (yearHi > -1 ? ".." : ""); 
            }
            if (yearHi > -1) {
                yearRangeFilterVal += 
                        (yearLo < 0 ? yearHi + "-01-01T00:00:00Z.." : "") 
                        + yearHi + "-12-31T23:59:59Z";
            }
        } catch (Exception e) {}
        return yearRangeFilterVal;
    }

    /**
     * Gets any and all "filter-xxx" parameters present in the given map.
     */
    public static Map<String, String[]> getFilterParams(Map<String, String[]> parameters) {
        Map<String, String[]> params = new HashMap<String, String[]>(parameters);
        List<String> keysToRemove = new ArrayList<String>();
        for (String key : params.keySet()) {
            if (!key.startsWith(SearchFilter.PARAM_NAME_PREFIX)) {
                keysToRemove.add(key);
            }
        }
        for (String key : keysToRemove) {
            params.remove(key);
        }
        return params;
    }

    /**
     * Shortcut method.
     */
    public static SearchFilterSets getFiltersInParams(CmsJspActionElement cms, SearchFilterSets filterSets, String ... paramToExclude) {
        
        return getFiltersInParams(
            CmsRequestUtil.createParameterMap(APIUtil.toParameterString(cms.getRequest().getParameterMap(), paramToExclude)),
            //cms.getRequest().getParameterMap(),
            filterSets,
            cms.getRequestContext().getLocale(),
            cms.getRequestContext().getUri()
        );
    }

    /**
     * Creates search filters, contained in filter sets, from the "filter-xxx"
     * parameters present in the given map, and injects them into the given
     * search filter set.
     * 
     * This method useful in particular when a user has activated filters, and 
     * then applies a time filter which results in zero hits. In that case, the 
     * active filters are not exposed by the Data Centre, and consequently there 
     * is no "native" way to display them, so that the user may deactivate them.
     * 
     * ToDo: Move this functionality to the library.
     * 
     * @param parameters  The relevant parameters, typically the current request's query string
     * @param filterSets  The initial filter sets (typically empty), which this method will return, possibly with filters added
     * @param locale  The locale to use when translating filter texts etc.
     * @param pageUri  The path to the current page (without query string)
     */
    public static SearchFilterSets getFiltersInParams(Map<String, String[]> parameters, SearchFilterSets filterSets, Locale locale, String pageUri) {

        Map<String, String[]> fp = getFilterParams(parameters);
        if (fp != null && !fp.isEmpty()) {

            Iterator<String> itr = fp.keySet().iterator();
            while (itr.hasNext()) {
                // Get e.g. "filter-topic" - this filter's name in the URL query string
                String filterParamName = itr.next();
                // Retain e.g. "topic" - the name of the field to filter on
                String filterName = filterParamName.substring(SearchFilter.PARAM_NAME_PREFIX.length());

                // Ensure the filter set exists
                if (filterSets.getByName(filterName) == null) {
                    filterSets.add( new SearchFilterSet(filterName, locale) );
                }

                // Get the filter set we're about to modify
                SearchFilterSet filterSet = filterSets.getByName(filterName);

                // For each active filter, we want a "remove this filter" link.
                //
                // So, if we imagine we're filtering on "topic":
                //
                // A.)
                // Current URI: ...?filter-topic=climate&foo=bar        (filtering on a single term; "climate")
                // Filter  URI: ...?foo=bar                             (removes the active filter)
                //
                // B.)
                // Current URI: ...?filter-topic=climate,marine&foo=bar (filtering on multiple terms; "climate" and "marine")
                // Filter1 URI: ...?filter-topic=climate&foo=bar        (removes the active filter for the term "marine")
                // Filter2 URI: ...?filter-topic=marine&foo=bar         (removes the active filter for the term "climate")
                

                // Get a query string WITHOUT this "filter-xxx" parameter - it 
                // will from the base for all our "deactivate this filter" links
                String filterDeactivateUri = APIUtil.toParameterString(parameters, filterParamName);
                // We have to decode URI-encoded commas, "å"-letters etc.
                try {
                    //filterDeactivateUri = filterDeactivateUri.replaceAll("%2C", ",");
                    filterDeactivateUri = URLDecoder.decode(filterDeactivateUri, "utf-8");
                } catch(Exception e) {}


                // Get the "filter-xxx" parameter's value (should always be just 1 string)
                String filterParamValue = fp.get(filterParamName)[0];
                // We have to decode URI-encoded commas, "å"-letters etc.
                try { 
                    //filterParamValue = filterParamValue.replaceAll("%2C", ",");
                    filterParamValue = URLDecoder.decode(filterParamValue, "utf-8");
                } catch(Exception e) {}

                // This MAY be a multiple-term value (comma-separated) ...
                String[] filterTerms = filterParamValue.split(",");
                for (String filterTerm : filterTerms) {
                    
                    String filterUri = null;

                    // Multiple terms
                    if (filterParamValue.contains(",")) {
                        filterUri = pageUri + "?"
                                + (filterDeactivateUri.isEmpty() ? "" : filterDeactivateUri.concat("&"))
                                + filterParamName + "=" + removeFilterTerm(filterParamValue, filterTerm);
                    } 
                    // Single term
                    else {
                        filterUri = pageUri + (filterDeactivateUri.isEmpty() ? "" : "?".concat(filterDeactivateUri));
                    }

                    // We need a JSONObject in order to use a constructor that
                    // is able to set the "isActive" flag correctly
                    JSONObject filterObj = new JSONObject();
                    try { filterObj.put("term", filterTerm); } catch (Exception e) {}
                    try { filterObj.put("count", 0); } catch (Exception e) {}
                    try { filterObj.put("uri", filterUri); } catch (Exception e) {}

                    String referenceUri = pageUri.concat("?" + APIUtil.toParameterString(parameters));
                    //String referenceUri = pageUri.concat("?" + APIUtil.toParameterString(parameters).replaceAll("%2C", ","));
                    try {
                        referenceUri = pageUri.concat("?" + URLDecoder.decode(APIUtil.toParameterString(parameters), "utf-8"));
                    } catch (Exception e) {}
                    
                    // Add one (active) filter for each term
                    filterSet.add(
                        new SearchFilter(
                            filterName,
                            filterObj,
                            referenceUri
                        )
                    );
                }
            }
        }

        return filterSets;
    }

    /**
     * Removes a filter term from a string of multiple, comma-separated terms.
     */
    public static String removeFilterTerm(String original, String term) {
        String s = original.replace(term, "");
        s = s.replaceAll("(^,|,$)", "");
        s = s.replaceAll(",,", ",");
        return s;
    }
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();

// Set custom defined request URI
String requestFileUri = request.getParameter("base");
if (requestFileUri == null || requestFileUri.isEmpty()) {
    requestFileUri = cms.getRequestContext().getUri();
}
cms.getRequestContext().setUri(requestFileUri);

// Set custom defined locale, fallback to default
Locale requestedLocale = null;
try {
    requestedLocale = new Locale(request.getParameter("locale"));
    cms.getRequestContext().setLocale(requestedLocale);
} catch (Exception ignore) {}

Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

// Set flag indicating if the filters section should be expanded or not
final boolean FILTERS_EXPANDED = Boolean.valueOf(request.getParameter("expandedfilters"));

final boolean ONLINE = cmso.getRequestContext().getCurrentProject().isOnlineProject();

final String LABEL_SEARCHBOX_HEADING = loc.equalsIgnoreCase("no") ? "Søk i publikasjoner" : "Search publications";

final String LABEL_YEAR_SELECT = loc.equalsIgnoreCase("no") ? "År" : "Year";
final String LABEL_YEAR_SUBMIT = loc.equalsIgnoreCase("no") ? "Aktiver årstallsfilter" : "Activate year filter";

//final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");
final String LABEL_RESET_FILTERS = cms.label("label.np.filters.reset");


final String YLOW = "ylow";
final String YHIGH = "yhigh";

// Year parameters 
int ylow = -1;
int yhigh = -1;
// Update range years from params, if needed
if (isInteger(request.getParameter(YLOW))) {
    ylow = Integer.valueOf(request.getParameter(YLOW)).intValue();
}
if (isInteger(request.getParameter(YHIGH))) {
    yhigh = Integer.valueOf(request.getParameter(YHIGH)).intValue();
}

// Calendar used in year filtering
Calendar todayCal = new GregorianCalendar();
int yearRangeMin = 1970;
int yearRangeMax = todayCal.get(Calendar.YEAR);
boolean disableYearRangeControls = false;

ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
PublicationService pubService = new PublicationService(locale);

// Test service 
// ToDo: Use a servlet context variable instead of a helper file in the e-mail routine.
//       Also, the error message should be moved to workplace.properies or something
//       The whole "test the API availability" procedure should also be moved to a central location.
int responseCode = 0;
// ToDo: Load message from file system
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
    boolean isAvailable = APIUtil.testAvailability(pubService.getServiceBaseURL().concat("?" + PublicationService.Param.QUERY + "="), new int[]{200}, 5000, 3);
    if (!isAvailable) {
        out.println("<div class=\"error message message--error\">" + ERROR_MSG_NO_SERVICE + "</div>");
        try {
            SystemMessenger.sendStandardError(
                    SystemMessenger.DEFAULT_INTERVAL, 
                    "last_err_notification_publications", 
                    application, 
                    cms, 
                    "web@npolar.no", 
                    "no-reply@npolar.no", 
                    "Publications");
        } catch (Exception e) { 
            out.println("\n<!-- \nError sending email notification about problems with this page: " + e.getMessage() + " \n-->");
        }
        return;
    }
} catch (Exception e) {}


pubService.addDefaultParameter(
        // Don't include drafts
        PublicationService.modNot(Publication.Key.DRAFT),
        Publication.Val.DRAFT_TRUE
).addDefaultParameter(
        // Require state: published or accepted
        PublicationService.modFilter(Publication.Key.STATE), 
        PublicationService.combine(PublicationService.Delimiter.OR, Publication.Val.STATE_PUBLISHED, Publication.Val.STATE_ACCEPTED)
).addDefaultParameter(
        // Define which fields we want filters for
        PublicationService.Param.FACETS,
        PublicationService.Delimiter.AND,
        Publication.Key.TOPICS,
        Publication.Key.TYPE,
        Publication.Key.STATIONS,
        Publication.Key.PROGRAMMES
).addDefaultParameter(
        // Get all possible filters (not just "greatest hits")
        PublicationService.Param.FACETS_SIZE,
        "9999"
).addDefaultParameter(
        // Filter on "Yes, publication is affiliated to NPI"
        PublicationService.modFilter(Publication.Key.ORGS_ID),
        Publication.Val.ORG_NPI
); 
try {
    // Overrideable parameters
    Map<String, String[]> params = new HashMap<String, String[]>(request.getParameterMap());
    
    // Remove all parameters that we don't want to include on filter links
    try { params.remove("base"); } catch (Exception ee) {}
    try { params.remove("locale"); } catch (Exception ee) {}
    try { params.remove("expandedfilters"); } catch (Exception ee) {}
    
    String paramQuery = cms.getRequest().getParameter(PublicationService.Param.QUERY);
    
    if (paramQuery == null || paramQuery.isEmpty()) {
        // Set sort order to "newest first"
        pubService.addParameter(
                PublicationService.Param.SORT_BY, 
                PublicationService.modReverse(Publication.Key.PUB_TIME)
        );
    } else {
        // Use default sort order (typically "by relevancy")
    }
    
    if (ylow > -1 || yhigh > -1) {
        pubService.addParameter(
                PublicationService.modFilter(Publication.Key.PUB_TIME), 
                normalizeTimestampFilterValue(ylow, yhigh)
        );
    }
    
    // ToDo: Do we *really* need to encode here..? (specify why)
    Iterator<String> iParam = params.keySet().iterator();
    while (iParam.hasNext()) {
        String key = iParam.next();
        //*
        String[] val = params.get(key);
        // Encode is necessary to get predictable results, when query or filters
        // contain e.g. "æ", "ø" or "å"
        for (int iVal = 0; iVal < val.length; iVal++) {
            val[iVal] = URLEncoder.encode( URLDecoder.decode(val[iVal], "utf-8"), "utf-8");
        }
        params.put(key, val);
        out.println("<!-- params[" + key + "] = '" + val[0] + "' -->" );
        //out.println("<!-- params[" + key + "] = '" + URLDecoder.decode(val[0], "utf-8") + "' -->" );
        //*/
    }
    
    
    //pubService.addParameters(params);
    
    if (!params.containsKey(PublicationService.Param.QUERY)) {
        pubService.setFreetextQuery("");
    } //else {
        //pubService.setFreetextQuery(URLEncoder.encode(params.get("q")[0], "utf-8"));
    //}
    
    // Fetch the list, passing all dynamic parameters – including those from the request
    List<Publication> pubList = pubService.getPublicationList(params);
    //out.println("<h1>Matched " + pubService.getTotalResults() + " publications (" + pubList.size() + " per page), " 
    //        + (pubService.isUserFiltered() ? "" : " NOT") + " filtered by user.</h1>");
    
    String lastSearchPhrase = pubService.getLastSearchPhrase();
    int totalResults = pubService.getTotalResults();
    
    out.println("<!-- \nAPI URL: \n" + pubService.getLastServiceURL() + " \n-->");
    
    
    
    // Get 0-N sets of filters
    // One filter (pseudo): "TOPIC: climate | marine | ecology | biology | ..."
    SearchFilterSets filterSets = pubService.getFilterSets();
    
    // Handle special case: 
    // - active filters AND 
    // - zero results 
    //
    // It is "impossible" to trigger this case just by clicking on filter links, 
    // but easy if a year filter is applied on top of those filters.
    if (totalResults == 0 && filterSets.isEmpty()) {
        filterSets = getFiltersInParams(params, filterSets, locale, cms.getRequestContext().getUri());
    }
    
    /*SearchFilterSet yearsInResults = filterSets.getByName("year-published");
    yearRangeMin = Integer.valueOf(yearsInResults.get(0).getTerm());
    yearRangeMax = Integer.valueOf(yearsInResults.get(yearsInResults.size()-1).getTerm());
    disableYearRangeControls = (yearRangeMin == yearRangeMax);*/
    
    // Remove the "year-published" filter set (the API service will always 
    // return this filter set, but we don't want users to see it)
    filterSets.removeByName("year-published"); // ToDo: Use this to determine the min/max values in the publish year selector
    
    //filterSets.removeByName("category");
    
    // Adjust the order of the filter sets
    filterSets.order(
        Publication.Key.TOPICS
        ,Publication.Key.TYPE
        ,Publication.Key.STATIONS
        ,Publication.Key.PROGRAMMES
    );
    
    String disclaimer = loc.equalsIgnoreCase("no") ? 
                            "<strong>Finner du ikke publikasjonen? Da kan du prøve et " + "<a href=\"" + cms.link("/no/publikasjoner/brage.html") + "\">" + "søk i vårt publikasjonsarkiv «Brage»" + "</a>.</strong><br />(Vi jobber med å samle alle publikasjonene i ett arkiv.)"
                            :
                            "<strong>Can't find the publication? Try " + "<a href=\"" + cms.link("/en/publications/brage.html") + "\">" + "searching our publications&nbsp;archive" + " «Brage»</a>.</strong><br />(We're working on offering all publications in a single archive.)";

        %>
        <form class="search-panel" action="<%= cms.link(requestFileUri) %>" method="get" id="pub-search-form">
        
            <h2 class="search-panel__heading"><%= LABEL_SEARCHBOX_HEADING %></h2>
            <p class="smalltext"><%= disclaimer %></p>
            
                <div class="search-widget">
                    <div class="searchbox">
                        <input name="<%= APIService.Param.QUERY %>" type="search" value="<%= lastSearchPhrase == null ? "" : CmsStringUtil.escapeHtml(lastSearchPhrase) %>" />
                        <input class="search-button" type="submit" value="<%= LABEL_SEARCH %>" />
                    </div>
                </div>
                <input name="<%= APIService.Param.START_AT %>" type="hidden" value="0" />
                <%
                // If we don't want any existing "regular" filters to reset upon 
                // submitting the form (i.e. when selecting a year range), they 
                // must be added as hidden inputs
                Map<String, String[]> activeFilters = getFilterParams(params);
                if (!activeFilters.isEmpty()) {
                    for (String key : activeFilters.keySet()) {
                        if (key.equals(SearchFilter.PARAM_NAME_PREFIX+Publication.Key.PUB_TIME)) {
                            continue;
                        } 
                        
                        String[] val = activeFilters.get(key);
                        for (int iVal = 0; iVal < val.length; iVal++) {
                            %>
                            <input name="<%= key %>" type="hidden" value="<%= URLDecoder.decode(val[iVal], "utf-8") %>" />
                            <%
                        }
                    }
                } else {
                    %><!-- No regular filters active --><%
                }

                out.println(filterSets.getFiltersWrapperHtmlStart(LABEL_FILTERS));
                if (!activeFilters.isEmpty()) {
            %>
                <div class="layout-group single layout-group--single filter-widget" style="text-align:right;">
                    <a href="<%= cms.link(requestFileUri) %>" style="display:inline-block; width:auto;" class="cta cta--alt" id="filters-reset">
                        <em class="icon-cancel"></em><%= LABEL_RESET_FILTERS %>
                    </a>
                </div>
            <%
                }
            %>
                    
                    <div class="layout-group single layout-group--single filter-widget" style="text-align:center;">
                        <div class="layout-box">
                            <h3 class="filter-widget__heading"><%= LABEL_YEAR_SELECT %></h3>
                            <input type="number" <%= disableYearRangeControls ? " disabled" : "" %>
                                    class="input input--year" 
                                    value="<%= ylow > -1 ? ylow : "" %>" 
                                    name="<%= YLOW %>" 
                                    id="range-year-low" /> 
                            – 
                            <input type="number" <%= disableYearRangeControls ? " disabled" : "" %>
                                    class="input input--year" 
                                    value="<%= yhigh > -1 ? yhigh : "" %>" 
                                    name="<%= YHIGH %>" 
                                    id="range-year-high" />
                            
                            
                            <!--<input class="input input--year" type="number" value="<%= ylow > -1 ? ylow : "" %>" name="<%= YLOW %>" id="range-year-low" /> -->
                            <!--– <input class="input input--year" type="number" value="<%= yhigh > -1 ? yhigh : "" %>" name="<%= YHIGH %>" id="range-year-high" />-->
                            <div class="range-slider" id="range-slider" style="margin: 2em 40px 0;"></div>
                            <br />
                            <input type="button" id="submit-time-range" class="cta cta--button" value="<%= LABEL_YEAR_SUBMIT %>" style="margin-top:1em;" />
                        </div>
                    </div>
                    
                    <%
                    //
                    // Print all regular filters
                    //
                    if (!filterSets.isEmpty()) {
                        out.println(filterSets.toHtml(cms, labels));
                    }
                    
                    // If year filtering is active, we need to make sure it's picked up by the javascript
                    if (ylow > -1 || yhigh > -1) {
                        Map<String, String[]> paramsTemp = new HashMap<String, String[]>(params);
                        paramsTemp.remove(YLOW);
                        paramsTemp.remove(YHIGH);
                        paramsTemp.remove(PublicationService.modFilter(Publication.Key.PUB_TIME));
                        String yearRemoveLinkUrl = CmsRequestUtil.appendParameters(cms.link(requestFileUri), paramsTemp, false);
                        String yearRemoveLinkText = (ylow > -1 ? String.valueOf(ylow).concat("&ndash;").concat(yhigh > -1 ? "" : String.valueOf(ylow)) : "") 
                                                    + (yhigh > -1 ? String.valueOf(yhigh).concat( ylow > -1 ? "" : "&ndash".concat(String.valueOf(yhigh)) ) : "");
                        %>
                        <div class="layout-group quadruple layout-group--quadruple filter-widget">
                            <div class="layout-box filter-set" style="display:none;">
                                <h3 class="filters-heading filter-set__heading">
                                    <%= LABEL_YEAR_SELECT %>
                                </h3>
                                <ul class="filter-set__filters">
                                    <li><a class="filter filter--active" href="<%= yearRemoveLinkUrl %>" rel="nofollow"><%= yearRemoveLinkText %></a></li>
                                </ul>
                            </div>
                        </div>
                        <%
                    }

                    out.println(filterSets.getFiltersWrapperHtmlEnd());
                    %>
        </form><!-- .search-panel (former .search-widget--filterable) -->
        <div id="filters-details"></div>
        <div id="pub-serp">
    <%
    if (totalResults > 0) {
    %>
        <h2 class="num-results" style="color:#999; border-bottom:1px solid #eee;">
            <span id="totalResultsCount"><%= totalResults %></span> <%= LABEL_MATCHES.toLowerCase() %>
        </h2>

        <% if (!ONLINE) { %>
        <div id="admin-msg" style="margin:1em 0; background: #eee; color: #444; padding:1em; font-family: monospace; font-size:1.2em;"></div>
        <% } %>

        <ul class="list--serp">
        
            <%
            Iterator<Publication> iPubs = pubList.iterator();
            while (iPubs.hasNext()) {
                
                Publication pub = iPubs.next();
                List<PublicationContributor> auth = pub.getPeopleByRole(Publication.Val.ROLE_AUTHOR);
                
                String peopleStr = auth.isEmpty() ?
                        getContributorsShort(pub.getPeopleByRole(Publication.Val.ROLE_EDITOR), "(ed.)", "(eds.)") :
                        getContributorsShort(auth, null, null);
                
                String pubType = pub.getType().toString(); 
                try { 
                    pubType = labels.getString(Labels.PUB_TYPE_PREFIX_0.concat((pub.isPartContribution() && !pubType.startsWith("in-") ? "in-" : "").concat(pub.getType().toString())));
                } catch (Exception e) {
                    out.println("<!-- ERROR translating publication type '" + pubType + "': " + e.getMessage() + " -->");
                }
                
                String publishedIn = "";
                if (pub.hasParent() || !pub.getJournalName().isEmpty()) {
                    if (pub.hasParent()) {
                        publishedIn = pubService.get(pub.getParentId()).getTitle();
                    } else {
                        publishedIn = pub.getJournalName();
                    }
                }
                
                out.println("<li class=\"serp-item\">"
                                + "<a class=\"serp-item__title\" href=\"" 
                                    + pub.getURL(pubService).replace(
                                            PublicationService.SERVICE_DOMAIN_NAME, 
                                            PublicationService.SERVICE_DOMAIN_NAME_HUMAN
                                    ) 
                                + "\">"
                                    + "<h4>" + pub.getTitle() + "</h4>"
                                + "</a>"
                                + "<span class=\"serp-item__meta\">"
                                    + "<span class=\"tag\">" + pubType + "</span>" 
                                    + " " + peopleStr
                                    + " " + pub.getPubYear()
                                    + (publishedIn.isEmpty() ? "" : " &ndash; <em>".concat(publishedIn).concat("</em>"))
                                + "</span>"
                            + "</li>");
            }  
            %>
            
        </ul>

        <% 
        // Standard pagination
        SearchResultsPagination pagination = new SearchResultsPagination(pubService, requestFileUri);
        out.println(pagination.getPaginationHtml());
    }
    else {
        out.println("<h2 class=\"num-results\" style=\"color:#999;\">" + LABEL_NO_MATCHES + "</h2>");
    }
    %>
    </div><!-- #pub-serp -->
    <%
//*  
} catch (Exception e) {
    //out.println("<div class=\"paragraph\"><p>An error occured. Please try a different search or come back later.</p></div>");
    out.println("<div class=\"paragraph\"><p>");
    if (loc.equalsIgnoreCase("no")) {
        out.println("En feil oppsto ved uthenting av publikasjoner. Vennligst prøv å oppdater siden, prøv et annet søk, eller kom tilbake senere.</p><p>Skulle problemet vedvare, er det fint om du kan <a href=\"mailto:web@npolar.no\">gi oss beskjed</a>.");
    } else {
        out.println("An error occured while fetching the publications. Please try refreshing the page, try a different search, or come back later.</p><p>Should you continue to see this error message over time, we would very much appreciate <a href=\"mailto:web@npolar.no\">a notification from you</a>.");
    }
    out.println("</p></div>");

    if (!ONLINE) {
        out.println("Service URL was: <a href=\"" + pubService.getLastServiceURL() + "\">" + pubService.getLastServiceURL() + "</a>");
        e.printStackTrace(response.getWriter());
    }
}
%>
<script>
    $(function() {
        $('<span class="num-results">').prependTo( $('.search-panel__filters .filter-widget').first() ).html( $('#pub-serp .num-results').text() );
                
        $('#filters-reset').click(function() {
            $('body').append('<div class="overlay overlay--fullscreen overlay--loading" id="fullscreen-overlay"></div>');
        });
        if (emptyOrNonExistingElement('filters-details')) {
            createActiveFiltersPanel();
        }
        
        <% if (FILTERS_EXPANDED) { %>
        $('.search-panel__filters').addClass("expanded");
        <% } %>
            
        <%
        if (request.getParameter(APIService.Key.SEARCH_QUERY) != null) { %>
            initToggleablesInside( $('#pub-search') );
        <%
        }
        %>
        
        //console.log("ylow = <%= ylow %>, yhigh = <%= yhigh %>");
        var rangeSlider = document.getElementById("range-slider");
                
        if (typeof noUiSlider === 'undefined') {
            // load the slider script and css, then call setup
            $('head').append('<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/nouislider.css") %>" />');
            $.getScript('<%= cms.link("/system/modules/no.npolar.common.jquery/resources/nouislider.min.js") %>', function() {
               setupSlider(rangeSlider); 
            });
        } else {
            // slider script and css already loaded, just call setup
            setupSlider(rangeSlider);
        }
    
        /**
         * Sets up the year range slider.
         * 
         * @param {type} sliderElement  The element to create the slider on, typically an empty div.
         * @returns {undefined}  Nothing.
         */
        function setupSlider(sliderElement) {
            noUiSlider.create(sliderElement, {
                range: {
                    'min': 1970,//<%= yearRangeMin %>,
                    'max': <%= todayCal.get(Calendar.YEAR) %>//<%= yearRangeMax %>
                }
                ,start: [<%= ylow > -1 ? ylow : "1970" %>,<%= yhigh > -1 ? yhigh : todayCal.get(Calendar.YEAR) %>]
                //,start: [<%= ylow > -1 ? ylow : yearRangeMin %>,<%= yhigh > -1 ? yhigh : yearRangeMax %>]
                ,connect: true
                //,step: 1
                ,format: {
                    to: function ( value ) {
                        //console.log("to: " + value.toString());
                        return Math.floor( value );;
                    },
                    from: function ( value ) {
                        //console.log("from: " + value.toString());
                        return value.replace(',-', '');
                    }
                }
                /*,to: function ( value ) {
                          return value + ',-';
                    },
                    from: function ( value ) {
                          return value.replace(',-', '');
                    }
                  }serialization: {
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
                }*/
            });
            <% if (disableYearRangeControls) { %>
            //sliderElement.setAttribute('disabled', true);
            <% } %>
            sliderElement.noUiSlider.on('update', function (values, handle) {
            //rangeSlider.noUiSlider.on('update', function (values, handle) {
                if (handle === 1) {
                    document.getElementById("range-year-high").value = values[handle];
                } else {
                    document.getElementById("range-year-low").value = values[handle];
                }
            });
            /*sliderElement.noUiSlider.on('slide', function(values, handle) {
            //sliderElement.noUiSlider.on('slide change', function(values, handle) {
                if (handle === 1 && values[1] > <%= yearRangeMax %> ) { 
                    values[1] = <%= yearRangeMax %>;
                    document.getElementById("range-year-high").value = values[handle];
                    sliderElement.noUiSlider.set(values);
                    return false;
                } else if (values[0] < <%= yearRangeMin %> ) {
                    values[0] = <%= yearRangeMin %>;
                    document.getElementById("range-year-low").value = values[handle];
                    sliderElement.noUiSlider.set(values);
                    return false;
                }
            });*/
        }
    });
</script>