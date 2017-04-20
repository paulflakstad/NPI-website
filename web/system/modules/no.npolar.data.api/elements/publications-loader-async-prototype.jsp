<%-- 
    Document   : publications-loader
    Created on : Apr 27, 2016, 11:29:47 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="no.npolar.data.api.*,
            no.npolar.data.api.util.APIUtil,
            no.npolar.util.CmsAgent,
            org.apache.commons.lang.StringUtils,
            org.apache.commons.lang.StringEscapeUtils,
            org.markdown4j.Markdown4jProcessor,
            java.util.Set,
            java.io.PrintWriter,
            org.opencms.jsp.CmsJspActionElement,
            java.io.IOException,
            java.util.Locale,
            java.net.URLDecoder,
            java.net.URLEncoder,
            org.opencms.main.OpenCms,
            org.opencms.util.CmsStringUtil,
            org.opencms.util.CmsRequestUtil,
            java.io.InputStreamReader,
            java.io.BufferedReader,
            java.net.URLConnection,
            java.net.URL,
            java.net.HttpURLConnection,
            java.util.ArrayList,
            java.util.Arrays,
            java.util.GregorianCalendar,
            java.util.Calendar,
            java.util.List,
            java.util.Date,
            java.util.Map,
            java.util.HashMap,
            java.util.Iterator,
            java.util.ResourceBundle,
            java.text.SimpleDateFormat,
            org.opencms.file.CmsObject,
            org.opencms.file.CmsProject,
            org.opencms.file.CmsResource,
            org.opencms.json.JSONArray,
            org.opencms.json.JSONObject,
            org.opencms.json.JSONException,
            org.opencms.mail.CmsSimpleMail"
            contentType="text/html" 
            pageEncoding="UTF-8" 
            session="true" 
 %><%!
/* Map storage for default parameters. */
static Map<String, String> dp = new HashMap<String, String>();
/* Stop words. */
static List<String> sw = new ArrayList<String>();
/* Map storage for active facets (filters). */
//static Map<String, String> activeFacets = new HashMap<String, String>();
/* Facet (filter) parameter name prefix. */
//final static  String FACET_PREFIX = "filter-";
/* On-screen/service value mappings. */
//public static Map<String, String> mappings = new HashMap<String, String>();
/* On-screen/service value mappings. */
//public static Map<String, String> norm = new HashMap<String, String>();

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

/**
 * Default ("system") parameters: The end-user should never see these.
 */
/*public static Map<String, String> getDefaultParamMap() {
    if (dp.isEmpty()) {
        dp.put(APIService.Param.SORT_BY, APIService.ParamVal.PREFIX_REVERSE+Publication.Key.PUB_TIME);
        //dp.put("sort", "-publication_year");
        dp.put(APIService.Param.FORMAT, APIService.ParamVal.FORMAT_JSON);
        dp.put(SearchFilter.PARAM_NAME_PREFIX+Publication.Key.DRAFT, Publication.Val.DRAFT_FALSE);
    }
    return dp;
}*/

/**
 * Gets the parameters part of the given URL string. 
 * (Equivalent to request.getQueryString().)
 */
/*public static String getParameterString(String theURL) {
    try {
        return theURL.split("\\?")[1];
    } catch (ArrayIndexOutOfBoundsException e) {
        return theURL;
    }  
}*/

/**
 * Gets the dynamic parameters from the request (typically the URL).
 * The end-user may see these parameters in the URL, and could potentially 
 * modify them there, in addition to indirectly modifying them using the 
 * end-user tools presented on-page. (Search form, pagination etc.)
 */
/*public static String getDynamicParams(CmsAgent cms, boolean includeStart) {
    String s = "";
    int i = 0;
    Map<String, String[]> pm = cms.getRequest().getParameterMap();
    
    if (!pm.isEmpty()) {
        Iterator<String> pNames = pm.keySet().iterator();
        while (pNames.hasNext()) {
            String pName = pNames.next();
            if (APIService.Param.START_AT.equals(pName) && !includeStart
                    || getDefaultParamMap().containsKey(pName))
                continue;
            String pValue = "";
            try { pValue = URLEncoder.encode(pm.get(pName)[0], "utf-8"); } catch (Exception e) { pValue = ""; }
            s += (++i > 1 ? "&" : "") + pName + "=" + pValue;
        }
    }
    else {
        String start = cms.getRequest().getParameter(APIService.Param.START_AT);

        // Query
        try {
            s += APIService.Param.QUERY + "=" + URLEncoder.encode(getParameter(cms, APIService.Param.QUERY), "utf-8");
        } catch (Exception e) {
            s += APIService.Param.QUERY + "=" + getParameter(cms, APIService.Param.QUERY);
        }

        // Items per page
        s += "&" + APIService.Param.RESULTS_LIMIT + "=" + getLimit(cms);

        // Start index
        if (includeStart && (start != null && !start.isEmpty()))
            s += "&" + APIService.Param.START_AT + "=" + start;
    }
    return s;
}*/

/**
 * Gets a particular parameter value. If no such parameter exists, an empty 
 * string is returned.
 */
public static String getParameter(CmsAgent cms, String paramName) {
    String param = cms.getRequest().getParameter(paramName);
    return param != null ? param : "";
}

/**
 * Gets the current limit value, with fallback to default value.
 */
/*public static String getLimit(CmsAgent cms) {
    return getParameter(cms, APIService.Param.RESULTS_LIMIT).isEmpty() ? "25" : getParameter(cms, APIService.Param.RESULTS_LIMIT);
}*/

/** 
 * Swap the given value (retrieved from the service) with a "normalized" value.
 * NOTE: MOVED TO Labels.java
 */
/*public String normalize(String serviceValue) {
    String s = norm.get(serviceValue);
    if (s == null || s.isEmpty())
        return serviceValue;
    return s;
}*/

public static String markdownToHtml(String s) {
    try { return new Markdown4jProcessor().process(s); } catch (Exception e) { return s + "\n<!-- Could not process this as markdown -->"; }
}

public static boolean isInteger(String s) {
    if (s == null || s.isEmpty())
        return false;
    try { Integer.parseInt(s); } catch(NumberFormatException e) { return false; }
    return true;
}

public static String normalizeTimestampFilterValue(int yearLo, int yearHi) {
    String yearRangeFilterVal = "";
    try {
        if (yearLo > -1) {
            yearRangeFilterVal += yearLo + "-01-01T00:00:00Z" + (yearHi > -1 ? ".." : ""); 
        }
        if (yearHi > -1) {
            yearRangeFilterVal += (yearLo < 0 ? yearHi + "-01-01T00:00:00Z.." : "") + yearHi + "-12-31T23:59:59Z";
        }
    } catch (Exception e) {}
    return yearRangeFilterVal;
}

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
 * @param parameters Request parameters
 */
/*public static List<String> getFilterRemovers(Map<String, String[]> parameters, String baseUri) {
    Map<String, String[]> filterParams = getFilterParams(parameters);
    List<String> removers = new ArrayList<String>(filterParams.size());
    
    for (String filterName : filterParams.keySet()) {
        // = filterParams.get(filterName)[0];
        String[] filterValues = filterParams.get(filterName)[0].filterValue.split(",");
        for (String filterValue : filterValues) {
            removers.add(baseUri.concat(toParameterString(parameters, key)).concat("&"+filterName));
        }
    }
    return removers;
}*/
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = request.getParameter("base");
if (requestFileUri == null || requestFileUri.isEmpty()) {
    requestFileUri = cms.getRequestContext().getUri();
}
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();

final String LABEL_SEARCHBOX_HEADING = loc.equalsIgnoreCase("no") ? "Søk i publikasjoner" : "Search publications";

final String LABEL_YEAR_SELECT = loc.equalsIgnoreCase("no") ? "År" : "Year";
final String LABEL_YEAR_SELECT_OPT_ALL = loc.equalsIgnoreCase("no") ? "Alle år" : "All years";

final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");
final String LABEL_FILTERS_RESET = loc.equalsIgnoreCase("no") ? "Nullstill alt" : "Reset all";
/*
final boolean EDITABLE_TEMPLATE = false;
*/
//*
final String YLOW = "ylow";
final String YHIGH = "yhigh";

// Year parameters 
int ylow = -1;
int yhigh = -2;
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
//*/

// Call master template (and output the opening part - hence the [0])
//cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE_TEMPLATE);

ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
PublicationService pubService = new PublicationService(locale);

// ------------
// Test service 
// ------------

// Define default settings (hidden / not overrideable parameters)
pubService.addDefaultParameter(
        // Don't include drafts
        PublicationService.modNot(Publication.Key.DRAFT), 
        Publication.Val.DRAFT_TRUE
).addDefaultParameter(
        // Require that publications have state=[published OR accepted] 
        PublicationService.modFilter(Publication.Key.STATE), 
        PublicationService.Delimiter.OR,
        Publication.Val.STATE_PUBLISHED,
        Publication.Val.STATE_ACCEPTED
).addDefaultParameter(
        // Require publications affiliated to NPI activity
        PublicationService.modFilter(Publication.Key.ORGS_ID),
        Publication.Val.ORG_NPI
).addDefaultParameter(
        // Define what facets (filtering options) we want
        PublicationService.Param.FACETS, 
        PublicationService.Delimiter.AND,
        Publication.Key.TOPICS,
        Publication.Key.TYPE,
        Publication.Key.STATIONS,
        Publication.Key.PROGRAMMES
).addDefaultParameter(
        // Get all possible filters
        "size-facet", //PublicationService.Param.FACETS_SIZE, 
        "9999"
);

//pubService.addParameters(request.getParameterMap());
try {
    
    
    // Adjust sort mode depending on whether or not a query string was used
    String paramQuery = cms.getRequest().getParameter(PublicationService.Param.QUERY);
    
    if (paramQuery == null || paramQuery.isEmpty()) {
        // No query string: Sort by "newest first"
        pubService.addParameter(
                PublicationService.Param.SORT_BY, 
                PublicationService.modReverse(Publication.Key.PUB_TIME)
        );
    } else {
        // Query string: Use default sorting
    }
    
    if (ylow > -1 || yhigh > -1) {
        pubService.addFilter(
                Publication.Key.PUB_TIME, 
                normalizeTimestampFilterValue(ylow, yhigh)
        );
    }
          
    
    // URL-encode any request parameters (necessary to get predictable results)
    Map<String, String[]> requestParams = new HashMap<String, String[]>(request.getParameterMap());
    Iterator<String> iParam = requestParams.keySet().iterator();
    while (iParam.hasNext()) {
        String key = iParam.next();
        if (key.equals("base")) {
            continue;
        }
        String[] val = requestParams.get(key);
        
        for (int iVal = 0; iVal < val.length; iVal++) {
            val[iVal] = URLEncoder.encode(val[iVal], "utf-8");
        }
        
        requestParams.put(key, val);
    }
    // Add ALL request parameters (will not override defaults, so should be safe)
    pubService.addParameters(requestParams);
    
    // A query string is needed - set it to empty string if there was no such parameter
    if (!pubService.getParameters().containsKey(PublicationService.Param.QUERY)) { // ToDo: Add hasParameter(String) or getParameter(String) method to service class
        pubService.setFreetextQuery(""); // ToDo: Change name to setSearchPhrase for consistence - that's what's used elsewhere (i.e. getLastSearchPhrase())
    }
    
    
    
    
    
    
    
    
    List<Publication> pubList = pubService.getPublicationList();

    out.println("<!-- \nAPI URL: \n" + pubService.getLastServiceURL() + " \n-->");
    
    
    
    
    
    
    
    
    
    
    
    // Get the collection of filter sets
    SearchFilterSets filterSets = pubService.getFilterSets();
    
    SearchFilterSet yearsInResults = filterSets.getByName("year-published");
    yearRangeMin = Integer.valueOf(yearsInResults.get(0).getTerm());
    yearRangeMax = Integer.valueOf(yearsInResults.get(yearsInResults.size()-1).getTerm());
    
    disableYearRangeControls = (yearRangeMin == yearRangeMax);
    String removeYearRangeFilter = null;
    if (ylow == yhigh) {
        // In that case, the year range input fields are disabled
        removeYearRangeFilter = cms.link(requestFileUri) //yearsInResults.get(0).getUrlPartBase() 
                + "?" + toParameterString(new HashMap<String, String[]>(requestParams), YLOW, YHIGH);
    }
    
    // Remove the "year-published" filter set (the API service will always 
    // return this filter set, but we don't want users to see it)
    filterSets.removeByName("year-published"); // ToDo: Use this to determine the min/max values in the publish year selector
    
    // Adjust the order of the  filter sets
    filterSets.order(new String[] { // ToDo: Make twin method that accepts 1-N Strings, instead of String[]
        Publication.Key.TOPICS
        ,Publication.Key.TYPE
        ,Publication.Key.STATIONS
        ,Publication.Key.PROGRAMMES
    });
    
    String lastSearchPhrase = pubService.getLastSearchPhrase();
    int totalResults = pubService.getTotalResults();
    // Define any filters that should not have hidden fields added in the form. 
    // (Typically anyhing that has a dedicated input field, like e.g. a year range selector.)
    List<String> noHidden = Arrays.asList(new String[] { 
        APIService.modFilter(Publication.Key.PUB_TIME) 
    });
    
    String disclaimer = loc.equalsIgnoreCase("no") ? 
                            "<strong>Finner du ikke publikasjonen? Da kan du prøve et " + "<a href=\"" + cms.link("/no/publikasjoner/brage.html") + "\">" + "søk i vårt publikasjonsarkiv «Brage»" + "</a>.</strong><br />(Vi jobber med å samle alle publikasjonene i ett arkiv.)"
                            :
                            "<strong>Can't find the publication? Try " + "<a href=\"" + cms.link("/en/publications/brage.html") + "\">" + "searching our publications&nbsp;archive" + " «Brage»</a>.</strong><br />(We're working on offering all publications in a single archive.)";
    
        // Query 
        
        %>
        <div class="searchbox-big search-widget search-widget--filterable">
            <h2><%= LABEL_SEARCHBOX_HEADING %></h2>
            <p class="smalltext"><%= disclaimer %></p>
            
            <form action="<%= cms.link(requestFileUri) %>" method="get" id="pub-search-form">
                <input name="<%= APIService.Param.QUERY %>" type="search" value="<%= lastSearchPhrase == null ? "" : CmsStringUtil.escapeHtml(lastSearchPhrase) %>" />
                <input name="<%= APIService.Param.START_AT %>" type="hidden" value="0" />
                <%
                // If we don't want any existing "regular" filters to reset upon 
                // submitting the form (i.e. when selecting a year range), they 
                // must be added as hidden inputs
                Map<String, String[]> activeFilters = getFilterParams(requestParams);
                if (!activeFilters.isEmpty()) {
                    for (String key : activeFilters.keySet()) {
                        if (noHidden.contains(key)) {
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
                %>
                <input class="cta cta--search-submit" type="submit" value="<%= LABEL_SEARCH %>" />
            
            <!--<div id="filters-wrap">-->
            <div class="filters-wrapper">
                <a class="cta cta--filters-toggle" id="filters-toggler" onclick="$('#filters').slideToggle();" tabindex="0"><%= LABEL_FILTERS %></a>
                
                <div id="filters" class="filters-container">
                    <div class="layout-row single clearfix" style="text-align:center;">
                        <a href="<%= cms.link(requestFileUri) %>" class="cta cta--filters-toggle filter--async"><%= LABEL_FILTERS_RESET %></a>
                    </div>
                    <div class="layout-row single clearfix" style="text-align:center;">
                        <div class="boxes">
                            <div class="span1">
                                <div class="filter-widget">
                                    <h3 class="filters-heading filter-widget-heading"><%= LABEL_YEAR_SELECT %></h3>
                                    <input type="number" <%= disableYearRangeControls ? " disabled" : "" %>
                                           value="<%= ylow > -1 ? ylow : "" %>" 
                                           name="<%= YLOW %>" id="range-year-low" 
                                           style="padding:0.5em; border:1px solid #ddd; width:4em; font-size:1.25em;" /> 
                                    – <input type="number" <%= disableYearRangeControls ? " disabled" : "" %>
                                             value="<%= yhigh > -1 ? yhigh : "" %>" 
                                             name="<%= YHIGH %>" 
                                             id="range-year-high" 
                                             style="padding:0.5em; border:1px solid #ddd; width:4em; font-size:1.25em;" />
                                    <div id="range-slider" style="margin: 2em 40px 0; min-height:18px;"></div> 
                                    <br />
                                    <% if (removeYearRangeFilter  == null) { %>
                                    <input id="submit-time-range" <%= disableYearRangeControls ? " disabled" : "" %>
                                           type="button" 
                                           class="cta cta--filters-toggle" 
                                           value="Oppdater år" 
                                           style="margin-top:1em;<%= disableYearRangeControls ? " background-color:#ccc;" : ""%>" 
                                           onclick="submit()" />
                                    <% } else { %>
                                    <a class="cta cta--filters-toggle filter--async" href="<%= removeYearRangeFilter %>">Vis alle år</a>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <%
                    if (!filterSets.isEmpty()) {
                        Iterator<SearchFilterSet> iFilterSets = filterSets.iterator();
                        %>
                        <section class="layout-row quadruple clearfix">
                        <div class="boxes">
                        <%
                        while (iFilterSets.hasNext()) {
                            // Get the filter set ...
                            SearchFilterSet filterSet = iFilterSets.next();
                            // ... and the filters in that set
                            List<SearchFilter> filters = filterSet.getFilters();
                            
                            if (filters != null) {
                                // Filter set has filters
                                %>
                                <div class="span1">
                                    <h3 class="filters-heading">
                                        <%= filterSet.getTitle(locale) %>
                                        <span class="filter__num-matches"> (<%= filterSet.size() %>)</span>
                                    </h3>
                                    <ul>
                                        <%
                                        /*try {
                                            out.print(labels.getString(normalize(filterSet.getName())));
                                        } catch (Exception transE) {
                                            out.print(normalize(filterSet.getName()));
                                        }*/
                                        //out.print(" R=" + filterSet.getRelevancy());
                                        //out.print(" N=" + filterSet.getName());
                                        try {
                                            Iterator<SearchFilter> iFilters = filters.iterator();
                                            while (iFilters.hasNext()) {
                                                SearchFilter filter = iFilters.next();
                                                String filterText = filter.getTerm();
                                                try {
                                                    filterText = labels.getString(filterSet.labelKeyFor(filter)); //labels.getString(normalize(filterSet.getName()) + "." + filter.getTerm());
                                                } catch (Exception skip) {
                                                    //normalize(filterSet.getName() + "." + filter.getTerm()); // HACK :-O
                                                }
                                                %>
                                                <li>
                                                <%
                                                filter.removeParam("base");
                                                out.println("<a class=\"filter--async" + (filter.isActive() ? (" filter--active") : "") + "\""
                                                                + " href=\"" + cms.link(requestFileUri + "?" + CmsStringUtil.escapeHtml(filter.getUrlPartParameters())) + "\">" 
                                                                    + (filter.isActive() ? "<span style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\" class=\"remove-filter\">X</span> " : "")
                                                                    + filterText
                                                                    + "<span class=\"filter__num-matches\"> (" + filter.getCount() + ")</span>"
                                                                + "</a>");
                                                %>
                                                </li>
                                                <%
                                            }
                                        } catch (Exception filterE) {
                                            out.println("<!-- " + filterE.getMessage() + " -->");
                                        }
                                        %>
                                    </ul>
                                </div>
                                <%
                            }
                        }
                        // If year filtering is active, we need to make sure it's picked up by the javascript
                        if (ylow > -1 || yhigh > -1) {
                            Map<String, String[]> paramsTemp = new HashMap<String, String[]>(requestParams);
                            paramsTemp.remove(YLOW);
                            paramsTemp.remove(YHIGH);
                            paramsTemp.remove(SearchFilter.PARAM_NAME_PREFIX+Publication.Key.PUB_TIME);
                            String yearRemoveLinkUrl = CmsRequestUtil.appendParameters(cms.link(requestFileUri), paramsTemp, false);
                            String yearRemoveLinkText = (ylow > -1 ? String.valueOf(ylow).concat("&ndash;").concat(yhigh > -1 ? "" : String.valueOf(ylow)) : "") 
                                                        + (yhigh > -1 ? String.valueOf(yhigh).concat( ylow > -1 ? "" : "&ndash".concat(String.valueOf(yhigh)) ) : "");
                            %>
                            <div class="span1" style="display:none;">
                                <h3 class="filters-heading">
                                    <%= LABEL_YEAR_SELECT %>
                                </h3>
                                <ul>
                                    <li><a class="filter--active" href="<%= yearRemoveLinkUrl %>"><%= yearRemoveLinkText %></a></li>
                                </ul>
                            </div>
                            <%
                        }
                        %>
                        </div>
                        </section>
                        <%
                    }
                    //out.println(getFacets(cms, json.getJSONArray("facets")));
                    %>
                    
                </div>
            </div>
            </form>
        </div>
    
        <div id="pub-serp">
    <%
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //String lastSearchPhrase = pubService.getLastSearchPhrase();
    //int totalResults = pubService.getTotalResults();
    Map<String, String[]> serviceParamsFree = pubService.getParameters();
    Map<String, String[]> serviceParamsLocked = pubService.getPresetParameters();
    if (totalResults > 0) {

        int itemsPerPage = pubService.getItemsPerPage();
        int startIndex = pubService.getStartIndex();
        int pageNumber = (startIndex + itemsPerPage) / itemsPerPage;
        int pagesTotal = (int)(Math.ceil((double)(totalResults + itemsPerPage) / itemsPerPage)) - 1;

        String next = pubService.getNextPageParameters();
        String prev = pubService.getPrevPageParameters();

        %>
        <h2 style="color:#999; border-bottom:1px solid #eee;">
            <span id="totalResultsCount"><%= totalResults %></span> <%= LABEL_MATCHES.toLowerCase() %>
        </h2>
        <div id="filters-details"></div>

        <% if (!ONLINE) { %>
        <div id="admin-msg" style="margin:1em 0; background: #eee; color: #444; padding:1em; font-family: monospace; font-size:1.2em;"></div>
        <% } %>

        <ul class="fullwidth line-items blocklist">
        
            <%
            //for (int pCount = 0; pCount < entries.length(); pCount++) {
            Iterator<Publication> iPubs = pubList.iterator();
            while (iPubs.hasNext()) {
                Publication pub = iPubs.next();
                out.println("<li>"
                                + "<span class=\"tag\">" + pub.getType() + "</span> " 
                                + pub.toString()
                            + "</li>");
            }  
            %>
        </ul>

        <% if (pagesTotal > 1) { %>
        <nav class="pagination clearfix">
            <div class="pagePrevWrap">
                <% 
                if (pagesTotal > 1) { // More than one page total
                    if (pageNumber > 1) { // At least one previous page exists
                    %>
                        <!--<a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + prev) %>"><</a>-->
                    <a class="prev" href="<%= cms.link(requestFileUri + "?" + StringEscapeUtils.escapeHtml(prev)) %>"></a>
                    <% 
                    }
                    else { // No previous page
                    %>
                        <a class="prev inactive"></a>
                    <%
                    }
                }
                %>
            </div>
            <div class="pageNumWrap">
                <%
                for (int pageCounter = 1; pageCounter <= pagesTotal; pageCounter++) {
                    boolean splitNav = pagesTotal >= 8;
                    // if (first page OR last page OR (pages total > 10 AND (this page number > (current page number - 4) AND this page number < (current page number + 4)))
                    // Pseudo: if this is the first page, the last page, or a page close to the current page (± 4)
                    if (!splitNav
                                || (splitNav && (pageCounter == 1 || pageCounter == pagesTotal))
                                //|| (pagesTotal > 10 && (pageCounter > (pageNumber-4) && pageCounter < (pageNumber+4)))) {
                                || (splitNav && (pageCounter > (pageNumber-3) && pageCounter < (pageNumber+3)))) {
                        if (pageCounter != pageNumber) { // Not the current page: print a link
                        %>
                            <a href="<%= cms.link(requestFileUri 
                                    + "?" 
                                    + StringEscapeUtils.escapeHtml(toParameterString(serviceParamsFree, APIService.Param.START_AT) 
                                    + "&" + APIService.Param.START_AT + "=" + ((pageCounter-1) * itemsPerPage))) %>">
                                <%= pageCounter %>
                            </a>
                        <% 
                        }
                        else { // The current page: no link
                        %>
                            <span class="currentpage"><%= pageCounter %></span>
                        <%
                        }
                    }
                    // Pseudo: 
                    else if (splitNav && (pageCounter == 2 || pageCounter+1 == pagesTotal)) { 
                    %>
                        <span> &hellip; </span>
                    <%
                    } else {
                        //out.println("<!-- page " + pageCounter + " dropped ... -->");
                    }
                } 
                %>
            </div>
            <div class="pageNextWrap">
                <!--<span>Page <%= pageNumber %> of <%= pagesTotal %></span>-->


                <% 
                if (pagesTotal > 1) { // More than one page total
                    if (pageNumber < pagesTotal) { // At least one more page exists
                        %>
                        <!--<a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + APIUtil.getQueryString(next)) %>">></a>-->
                        <a class="next" href="<%= cms.link(requestFileUri + "?" + StringEscapeUtils.escapeHtml(next)) %>"></a>
                        <% 
                    }
                    else {
                        %>
                        <a class="next inactive"></a>
                        <%
                    }
                }
                %>
            </div>
        </nav>
        <%
        }
    }
    else {
        out.println("<h2 style=\"color:#999;\">" + LABEL_NO_MATCHES + "</h2>");
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
<script type="text/javascript">
    /*$('.filter--async').click(function(event) {
        event.preventDefault();
        var filterTarget = $(this).attr('href');
        var queryString = filterTarget.substring(filterTarget.indexOf("?")+1);
        var pubListUri = '<%= cms.link(cms.getRequestContext().getUri()) %>?'+queryString+'&base=<%= requestFileUri %>';
        $(this).toggleClass('filter--active');
        console.log('Loading "' + pubListUri + '" ...');
        
        window.history.pushState(document.getElementById('pub-search').innerHTML, "", filterTarget);
        updateAsync.call(undefined, filterTarget);*/
        /*
        $('body').append('<div class="overlay--loading" id="pub-search-overlay" style="position:fixed; top:0; bottom:0; left:0; right:0; background-color:rgba(0,0,0,0.5);"></div>');
        $('#pub-search').load(pubListUri, function(responseText, textStatus, jqXHR) {
            $('#pub-search-overlay').remove();
            window.history.pushState(document.getElementById('pub-search').innerHTML, "", filterTarget);
        });
        //*/
    /*});
    var updateAsync = function(uri) {
        $('body').append('<div class="overlay--loading" id="pub-search-overlay" style="position:fixed; top:0; bottom:0; left:0; right:0; background-color:rgba(0,0,0,0.5);"></div>');
        $('#pub-search').load(uri, function(responseText, textStatus, jqXHR) {
            $('#pub-search-overlay').remove();
        });
    };
    window.onpopstate = function(e) {
        updateAsync.call(undefined, document.location.href);
    };*/
    var provider = '<%= cms.link(cms.getRequestContext().getUri()) %>';
    $('.filter--async').click(function(event) {
        event.preventDefault();
        var filterTarget = $(this).attr('href');
        var queryString = filterTarget.substring(filterTarget.indexOf("?")+1);
        queryString += '&base=<%= requestFileUri %>';
        //var pubListUri = '/no/publikasjoner/publications-loader.jsp?'+queryString+'&base=<%= requestFileUri %>';
        $(this).toggleClass('filter--active');
        //console.log('Loading "' + pubListUri + '" ...');
        
        window.history.pushState(document.getElementById('pub-search').innerHTML, "", filterTarget);
        updateAsync.call(undefined, provider, queryString);
        /*
        $('body').append('<div class="overlay--loading" id="pub-search-overlay" style="position:fixed; top:0; bottom:0; left:0; right:0; background-color:rgba(0,0,0,0.5);"></div>');
        $('#pub-search').load(pubListUri, function(responseText, textStatus, jqXHR) {
            $('#pub-search-overlay').remove();
            window.history.pushState(document.getElementById('pub-search').innerHTML, "", filterTarget);
        });
        //*/
    });
    
    $('#submit-time-range').attr('onclick', 'submitAsync("pub-search-form")');
    $('#pub-search-form').submit( function(event) {
        event.preventDefault();
        submitAsync('pub-search-form');
        //var queryString = $(this).serialize();
        //updateAsyncFromUrl(queryString);
        return false;
    });
    
    function submitAsync(id) {
        var queryString = $('#'+id).serialize();
        window.history.pushState(queryString, "", getPath(document.location.href)+"?"+queryString);
        updateAsyncFromUrl(queryString);
    }
    
    var updateAsync = function(provider, queryString) {
        console.log("Loading: " + provider + "?" + queryString);
        $('body').append('<div class="overlay--loading" id="pub-search-overlay" style="position:fixed; top:0; bottom:0; left:0; right:0; background-color:rgba(0,0,0,0.5);"></div>');
        $('#pub-search').load(provider+'?'+queryString, function(/*String*/responseText, /*String*/textStatus, /*jqXHR*/jqXHR) {
            $('#pub-search-overlay').remove();
        });
    };
    
    function updateAsyncFromUrl(url) {
        if (url === 'undefined' || url === null) {
            url = document.location.href;
        }
        var queryString = getQueryString(url);
        queryString += (queryString.length > 0 ? "&" : "?") + "base=<%= requestFileUri %>"; // Re-add the "base" parameter, avoids filters targeting THIS file after a popstate event
        updateAsync.call(undefined, provider, queryString);
    }
    window.onpopstate = function(e) {
        updateAsyncFromUrl(null);
    };
    function getPath(url) {
        if (url.indexOf("?") < 0) {
            return url;
        }
        else {
            return url.substring(0, url.indexOf("?"));
        }
    }
    function getQueryString(url) {
        var queryString = "";
        // Case: only query string
        if (url.indexOf("?") <= 0 && url.indexOf("=") > 0) {
            return url;
        }
        // Case: query string present, but MAY be empty (hence the try/catch)
        try {
            queryString = url.substring(url.indexOf("?")+1);
        } catch (ignore) { }
        
        return queryString;
    }
    
    //$("#filters").hide();
    $('input[type=number].input-year').attr({ max:'<%= yearRangeMax %>', min:'<%= yearRangeMin %>'});
    if ($('#range-slider').length > 0) {
        var rangeSlider = document.getElementById("range-slider");
        $('head').append('<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/nouislider.css") %>" />');
        $.getScript('<%= cms.link("/system/modules/no.npolar.common.jquery/resources/nouislider.min.js") %>', function() {
            noUiSlider.create(rangeSlider, {
                range: {
                    'min': 1970,//<%= yearRangeMin %>,
                    'max': <%= todayCal.get(Calendar.YEAR) %>//<%= yearRangeMax %>
                }
                ,start: [<%= ylow > -1 ? ylow : yearRangeMin %>,<%= yhigh > -1 ? yhigh : yearRangeMax %>]
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
            rangeSlider.setAttribute('disabled', true);
            <% }%>
            rangeSlider.noUiSlider.on('update', function (values, handle) {
            //rangeSlider.noUiSlider.on('update', function (values, handle) {
                if (handle === 1) {
                    document.getElementById("range-year-high").value = values[handle];
                } else {
                    document.getElementById("range-year-low").value = values[handle];
                }
            });
            rangeSlider.noUiSlider.on('slide', function(values, handle) {
            //rangeSlider.noUiSlider.on('slide change', function(values, handle) {
                if (handle === 1 && values[1] > <%= yearRangeMax %> ) { 
                    values[1] = <%= yearRangeMax %>;
                    document.getElementById("range-year-high").value = values[handle];
                    rangeSlider.noUiSlider.set(values);
                    return false;
                } else if (values[0] < <%= yearRangeMin %> ) {
                    values[0] = <%= yearRangeMin %>;
                    document.getElementById("range-year-low").value = values[handle];
                    rangeSlider.noUiSlider.set(values);
                    return false;
                }
            });
        });
    }
</script>