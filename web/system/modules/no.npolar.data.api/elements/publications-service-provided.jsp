<%-- 
    Document   : publications-service-provided
    Description: Lists publications using the data.npolar.no API.
    Created on : Nov 1, 2013, 1:11:42 PM
    Author     : flakstad
--%><%@page import="no.npolar.data.api.*,
            no.npolar.data.api.util.APIUtil,
            no.npolar.util.CmsAgent,
            no.npolar.util.SystemMessenger,
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
        if (!key.startsWith(PublicationService.Param.MOD_FILTER)) {
            keysToRemove.add(key);
        }
    }
    for (String key : keysToRemove) {
        params.remove(key);
    }
    return params;
}
%><%


CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();

final String LABEL_SEARCHBOX_HEADING = loc.equalsIgnoreCase("no") ? "Søk i publikasjoner" : "Search publications";

final String LABEL_YEAR_SELECT = loc.equalsIgnoreCase("no") ? "År" : "Year";
final String LABEL_YEAR_SUBMIT = loc.equalsIgnoreCase("no") ? "Aktiver årstallsfilter" : "Activate year filter";

//final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");


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

Calendar todayCal = new GregorianCalendar();

ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
PublicationService pubService = new PublicationService(locale);

// Test service 
// ToDo: Use a servlet context variable instead of a helper file in the e-mail routine.
//       Also, the error message should be moved to workplace.properies or something
//       The whole "test the API availability" procedure should also be moved to a central location.
int responseCode = 0;
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
    
    // ToDo: Do we really need to encode here..?
    Iterator<String> iParam = params.keySet().iterator();
    while (iParam.hasNext()) {
        String key = iParam.next();
        //*
        String[] val = params.get(key);
        // Encode is necessary to get predictable results
        for (int iVal = 0; iVal < val.length; iVal++) {
            val[iVal] = URLEncoder.encode(val[iVal], "utf-8");
        }
        params.put(key, val);
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
    
    out.println("<!-- \nAPI URL: \n" + pubService.getLastServiceURL() + " \n-->");
    
    
    
    // Get the collection of filter sets
    SearchFilterSets filterSets = pubService.getFilterSets();
    
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
    
    String lastSearchPhrase = pubService.getLastSearchPhrase();
    int totalResults = pubService.getTotalResults();
    
    String disclaimer = loc.equalsIgnoreCase("no") ? 
                            "<strong>Finner du ikke publikasjonen? Da kan du prøve et " + "<a href=\"" + cms.link("/no/publikasjoner/brage.html") + "\">" + "søk i vårt publikasjonsarkiv «Brage»" + "</a>.</strong><br />(Vi jobber med å samle alle publikasjonene i ett arkiv.)"
                            :
                            "<strong>Can't find the publication? Try " + "<a href=\"" + cms.link("/en/publications/brage.html") + "\">" + "searching our publications&nbsp;archive" + " «Brage»</a>.</strong><br />(We're working on offering all publications in a single archive.)";

        // Query 
        // ToDo: rename "searchbox-big" / "search-widget" => "search-panel" (?)
        //       - "search-widget" suggests a single tool or group of related 
        //         tools (like filter sets)
        %>
        <form class="search-panel" action="<%= cms.link(requestFileUri) %>" method="get">
        <!--<div class="search-panel">-->
            <h2 class="search-panel__heading"><%= LABEL_SEARCHBOX_HEADING %></h2>
            <p class="smalltext"><%= disclaimer %></p>
            
            <!--<form action="<%= cms.link(requestFileUri) %>" method="get">-->
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
                %>
                <!--<div class="search-panel__filters">-->
                    <!--<a class="toggler toggler--filters-toggle" tabindex="0"><%= LABEL_FILTERS %></a>-->
                    <!--<div class="toggleable toggleable--filters">-->
            <%
                out.println(filterSets.getFiltersWrapperHtmlStart(LABEL_FILTERS));
            %>
                    
                    <div class="layout-group single layout-group--single filter-widget" style="text-align:center;">
                        <div class="layout-box">
                            <h3 class="filter-widget__heading"><%= LABEL_YEAR_SELECT %></h3>
                            <input class="input input--year" type="number" value="<%= ylow > -1 ? ylow : "" %>" name="<%= YLOW %>" id="range-year-low" /> 
                            – <input class="input input--year" type="number" value="<%= yhigh > -1 ? yhigh : "" %>" name="<%= YHIGH %>" id="range-year-high" />
                            <div class="range-slider" id="range-slider" style="margin: 2em 40px 0;"></div>
                            <br />
                            <input type="button" class="cta cta--button" value="<%= LABEL_YEAR_SUBMIT %>" style="margin-top:1em;" onclick="submit()" />
                        </div>
                    </div>
                    
                    <%
                        
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

                    //out.println(getFacets(cms, json.getJSONArray("facets")));

                    out.println(filterSets.getFiltersWrapperHtmlEnd());
                    %>
                    <!--</div>--><!-- .toggleable -->
                <!--</div>--><!-- .search-panel__filters -->
            <!--</form>-->
        </form><!-- .search-panel (former .search-widget--filterable) -->
        <div id="filters-details"></div>
        <!--
        <div class="something">
            <a class="toggler" href="#"><span class="toggler__text">Toggle!</span></a>
            <div class="toggleable">this is toggleable</div>
            <a class="toggler" href="#"><span class="toggler__text">Toggle!</span></a>
            <div class="toggleable">this is toggleable</div>
            <a class="toggler" href="#"><span class="toggler__text">Toggle!</span></a>
            <div class="toggleable">this is toggleable</div>
            <a class="toggler" href="#"><span class="toggler__text">Toggle!</span></a>
            <div class="toggleable">this is toggleable</div>
            <a class="toggler" href="#"><span class="toggler__text">Toggle!</span></a>
            <div class="toggleable">this is toggleable</div>
        </div>
        -->
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

        <% 
        // Standard pagination
        SearchResultsPagination pagination = new SearchResultsPagination(pubService, requestFileUri);
        out.println(pagination.getPaginationHtml());
    }
    else {
        out.println("<h2 style=\"color:#999;\">" + LABEL_NO_MATCHES + "</h2>");
    }
//*  
} catch (Exception e) {
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
//*/
%>

<script type="text/javascript">
    //$("#filters").hide();
    $('input[type=number].input-year').attr({ max:'<%= todayCal.get(Calendar.YEAR) %>', min:'1970'});
    if ($('#range-slider').length > 0) {
        var rangeSlider = document.getElementById("range-slider");
        $('head').append('<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/nouislider.css") %>" />');
        $.getScript('<%= cms.link("/system/modules/no.npolar.common.jquery/resources/nouislider.min.js") %>', function() {
            noUiSlider.create(rangeSlider, {
                range: {
                    'min': 1970,
                    'max': <%= todayCal.get(Calendar.YEAR) %>
                }
                ,start: [<%= ylow > -1 ? ylow : "1970" %>,<%= yhigh > -1 ? yhigh : todayCal.get(Calendar.YEAR) %>]
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
            rangeSlider.noUiSlider.on('update', function (values, handle) {
                if (handle === 1) {
                    document.getElementById("range-year-high").value = values[handle];
                } else {
                    document.getElementById("range-year-low").value = values[handle];
                }
            });
        });
    }
</script>