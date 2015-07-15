<%-- 
    Document   : projects-service-provided
    Description: Lists publications using the data.npolar.no API.
    Created on : Mar 12, 2013, 5:32:42 PM
    Author     : flakstad
--%><%@page import="org.opencms.file.CmsResource"%>
<%@page import="org.opencms.mail.CmsSimpleMail"%>
<%@page import="no.npolar.data.api.util.APIUtil,
                    java.util.ResourceBundle,
                    no.npolar.data.api.*,
                    org.apache.commons.lang.StringUtils,
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
                    org.opencms.json.JSONArray,
                    java.util.List,
                    java.util.Date,
                    java.util.Map,
                    java.util.HashMap,
                    java.util.Iterator,
                    java.text.SimpleDateFormat,
                    no.npolar.util.CmsAgent,
                    org.opencms.json.JSONObject,
                    org.opencms.json.JSONException,
                    org.opencms.file.CmsObject"
                contentType="text/html" 
                pageEncoding="UTF-8" 
                session="true"
 %><%!
/* Map storage for default parameters. */
static Map<String, String> dp = new HashMap<String, String>();
/* Stop words. */
//static List<String> sw = new ArrayList<String>();
/* Map storage for active facets (filters). */
//static Map<String, String> activeFacets = new HashMap<String, String>();
/* Facet (filter) parameter name prefix. */
//final static  String FACET_PREFIX = "filter-";
/* On-screen/service value mappings. */
//public static Map<String, String> mappings = new HashMap<String, String>();
/* On-screen/service value mappings. */
//public static Map<String, String> norm = new HashMap<String, String>();

/**
 * Default ("system") parameters: The end-user should never see these.
 */
public static Map<String, String> getDefaultParamMap() {
    if (dp.isEmpty()) {
        dp.put("sort", "-publication_year");
        dp.put("format", "json");
        dp.put("filter-draft", "no");
    }
    return dp;
}

/**
 * Gets the parameters part of the given URL string. 
 * (Equivalent to request.getQueryString().)
 */
public static String getParameterString(String theURL) {
    try {
        return theURL.split("\\?")[1];
    } catch (ArrayIndexOutOfBoundsException e) {
        return theURL;
    }  
}

/**
 * Gets the dynamic parameters from the request (typically the URL).
 * The end-user may see these parameters in the URL, and could potentially 
 * modify them there, in addition to indirectly modifying them using the 
 * end-user tools presented on-page. (Search form, pagination etc.)
 */
public static String getDynamicParams(CmsAgent cms, boolean includeStart) {
    String s = "";
    int i = 0;
    Map<String, String[]> pm = cms.getRequest().getParameterMap();
    
    if (!pm.isEmpty()) {
        Iterator<String> pNames = pm.keySet().iterator();
        while (pNames.hasNext()) {
            String pName = pNames.next();
            if ("start".equals(pName) && !includeStart
                    || getDefaultParamMap().containsKey(pName))
                continue;
            String pValue = "";
            try { pValue = URLEncoder.encode(pm.get(pName)[0], "utf-8"); } catch (Exception e) { pValue = ""; }
            s += (++i > 1 ? "&" : "") + pName + "=" + pValue;
        }
    }
    else {
        String start = cms.getRequest().getParameter("start");

        // Query
        try {
            s += "q=" + URLEncoder.encode(getParameter(cms, "q"), "utf-8");
        } catch (Exception e) {
            s += "q=" + getParameter(cms, "q");
        }

        // Items per page
        s += "&limit=" + getLimit(cms);

        // Start index
        if (includeStart && (start != null && !start.isEmpty()))
            s += "&start=" + start;
    }
    return s;
}

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
public static String getLimit(CmsAgent cms) {
    return getParameter(cms, "limit").isEmpty() ? "25" : getParameter(cms, "limit");
}

/** 
 * Swap the given value (retrieved from the service) with a "normalized" value.
 * NOTE: MOVED TO Labels.java
 */
/*public String normalize(String serviceValue) {
    String s = norm.get(serviceValue);
    if (s == null || s.isEmpty())
        return serviceValue.toLowerCase();
    return s;
}*/
%><%


CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final String DETAILS_URI = loc.equalsIgnoreCase("no") ? "detaljer" : "details";

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();

final String LABEL_SEARCHBOX_HEADING = loc.equalsIgnoreCase("no") ? "Søk i prosjekter" : "Search projects";

final String LABEL_YEAR_SELECT = loc.equalsIgnoreCase("no") ? "År" : "Year";
final String LABEL_YEAR_SELECT_OPT_ALL = loc.equalsIgnoreCase("no") ? "Alle år" : "All years";

final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");

final boolean EDITABLE_TEMPLATE = false;
/*
final String LABEL_ORG_COMM                 = loc.equalsIgnoreCase("no") ? "Kommunikasjon" : "Communications";
final String LABEL_ORG_COMM_INFO            = loc.equalsIgnoreCase("no") ? "Informasjon" : "Information";
final String LABEL_ORG_ADM                  = loc.equalsIgnoreCase("no") ? "Administrasjon" : "Administration";
final String LABEL_ORG_ADM_ECONOMICS        = loc.equalsIgnoreCase("no") ? "Økonomi" : "Economics";
final String LABEL_ORG_ADM_HR               = loc.equalsIgnoreCase("no") ? "Personal" : "Human resources";
final String LABEL_ORG_ADM_SENIOR           = loc.equalsIgnoreCase("no") ? "Seniorrådgivere" : "Senior advisers";
final String LABEL_ORG_ADM_ICT              = loc.equalsIgnoreCase("no") ? "IKT" : "ICT";
final String LABEL_ORG_LEADER               = loc.equalsIgnoreCase("no") ? "Ledergruppen" : "Leaders group";
final String LABEL_ORG_RESEARCH             = loc.equalsIgnoreCase("no") ? "Forskning" : "Scientific research";
final String LABEL_ORG_RESEARCH_BIODIV      = loc.equalsIgnoreCase("no") ? "Biodiversitet" : "Biodiversity";
final String LABEL_ORG_RESEARCH_GEO         = loc.equalsIgnoreCase("no") ? "Geologi og geofysikk" : "Geology and geophysics";
final String LABEL_ORG_RESEARCH_MARINE_CRYO = loc.equalsIgnoreCase("no") ? "Hav og havis" : "Oceans and sea ice";
final String LABEL_ORG_RESEARCH_ICE         = loc.equalsIgnoreCase("no") ? "Senter for is, klima og økosystemer (ICE)" : "Centre for Ice, Climate and Ecosystems (ICE)";
final String LABEL_ORG_RESEARCH_ICE_FIMBUL  = loc.equalsIgnoreCase("no") ? "ICE-Fimbulisen" : "ICE Fimbul Ice Shelf";
final String LABEL_ORG_RESEARCH_ICE_ECOSYSTEMS= loc.equalsIgnoreCase("no") ? "ICE-økosystemer" : "ICE Ecosystems";
final String LABEL_ORG_RESEARCH_ICE_SEA_ICE = loc.equalsIgnoreCase("no") ? "ICE-havis" : "ICE Fluxes";
final String LABEL_ORG_RESEARCH_ECOTOX      = loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Environmental pollutants";
final String LABEL_ORG_RESEARCH_SUPPORT     = loc.equalsIgnoreCase("no") ? "Støtte" : "Support";
final String LABEL_ORG_ENVMAP               = loc.equalsIgnoreCase("no") ? "Miljø- og kart" : "Environment and mapping";
final String LABEL_ORG_ENVMAP_DATA          = loc.equalsIgnoreCase("no") ? "Miljødata" : "Environmental data";
final String LABEL_ORG_ENVMAP_MANAGEMENT    = loc.equalsIgnoreCase("no") ? "Miljørådgivning" : "Environmental management";
final String LABEL_ORG_ENVMAP_MAP           = loc.equalsIgnoreCase("no") ? "Kart" : "Map";
final String LABEL_ORG_OL                   = loc.equalsIgnoreCase("no") ? "Operasjons- og logistikk" : "Operations and logistics";
final String LABEL_ORG_OL_ANTARCTIC         = loc.equalsIgnoreCase("no") ? "Antarktis" : "The Antarctic";
final String LABEL_ORG_OL_ARCTIC            = loc.equalsIgnoreCase("no") ? "Arktis" : "The Arctic";
final String LABEL_ORG_OL_LYR               = loc.equalsIgnoreCase("no") ? "Støtte" : "Support";
final String LABEL_ORG_OTHER                = loc.equalsIgnoreCase("no") ? "Sekretariater og organer" : "Secretariats and organizational bodies";
final String LABEL_ORG_OTHER_AC             = loc.equalsIgnoreCase("no") ? "Arktisk råd" : "Arctic Council";
final String LABEL_ORG_OTHER_CLIC           = loc.equalsIgnoreCase("no") ? "Climate and Cryosphere (CliC)" : "Climate and Cryosphere (CliC)";
final String LABEL_ORG_OTHER_NA2011         = loc.equalsIgnoreCase("no") ? "Nansen-Amundsenåret 2011" : "Nansen-Amundsen-year 2011";
final String LABEL_ORG_OTHER_NYSMAC         = loc.equalsIgnoreCase("no") ? "Ny-Ålesund Science Managers Committee (NySMAC)" : "Ny-Ålesund Science Managers Committee (NySMAC)";
final String LABEL_ORG_OTHER_SSF            = loc.equalsIgnoreCase("no") ? "Svalbard Science Forum" : "Svalbard Science Forum";

final String LABEL_JOB_TITLE            = loc.equalsIgnoreCase("no") ? "Ord i stillingstittel" : "Words in job title";
final String LABEL_ORG_AFFIL            = loc.equalsIgnoreCase("no") ? "Organisatorisk tilknytning" : "Org. affiliation";
final String LABEL_WORKPLACE            = loc.equalsIgnoreCase("no") ? "Arbeidssted" : "Work place";

final String LABEL_EMAIL                = loc.equalsIgnoreCase("no") ? "E-post" : "E-mail";
final String LABEL_PUBYEAR              = loc.equalsIgnoreCase("no") ? "Publikasjonsår" : "Published year";
final String LABEL_TOPIC                = loc.equalsIgnoreCase("no") ? "Tema" : "Topic";

final String LABEL_BIODIVERSITY = loc.equalsIgnoreCase("no") ? "Biologisk mangfold" : "Biodiversity";
final String LABEL_CLIMATE = loc.equalsIgnoreCase("no") ? "Klima" : "Climate";
final String LABEL_GEOLOGY = loc.equalsIgnoreCase("no") ? "Geologi" : "Geology";
final String LABEL_GLACIERS = loc.equalsIgnoreCase("no") ? "Isbreer" : "Glaciers";
final String LABEL_MARINE_ECOSYSTEMS = loc.equalsIgnoreCase("no") ? "Marine økosystemer" : "Marine ecosystems";
final String LABEL_ECOSYSTEMS = loc.equalsIgnoreCase("no") ? "Økosystemer" : "Ecosystems";
final String LABEL_MARINE = loc.equalsIgnoreCase("no") ? "Marint" : "Marine";
final String LABEL_OCEANOGRAPHY = loc.equalsIgnoreCase("no") ? "Oseanografi" : "Oceanography";
final String LABEL_ENVIRONMENTAL_POLLUTANTS = loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Envoronmental pollutants";
final String LABEL_ECOTOXICOLOGY = loc.equalsIgnoreCase("no") ? "Økotoksikologi" : "Ecotoxicology";
final String LABEL_BIOLOGY = loc.equalsIgnoreCase("no") ? "Biologi" : "Biology";
final String LABEL_ECOLOGY = loc.equalsIgnoreCase("no") ? "Økologi" : "Ecology";
final String LABEL_SEA_ICE = loc.equalsIgnoreCase("no") ? "Havis" : "Sea ice";
final String LABEL_GEOPHYSICS = loc.equalsIgnoreCase("no") ? "Geofysikk" : "Geofysikk";
final String LABEL_TOPOGRAPHY = loc.equalsIgnoreCase("no") ? "Topografi" : "Topography";

mappings.put("admin",       LABEL_ORG_ADM);
mappings.put("ikt",         LABEL_ORG_ADM_ICT);
mappings.put("okonomi",     LABEL_ORG_ADM_ECONOMICS);
mappings.put("personal",    LABEL_ORG_ADM_HR);
mappings.put("senior",      LABEL_ORG_ADM_SENIOR);
mappings.put("forskning",   LABEL_ORG_RESEARCH);
mappings.put("biodiv",      LABEL_ORG_RESEARCH_BIODIV);
mappings.put("geo",         LABEL_ORG_RESEARCH_GEO);
mappings.put("havkryo",     LABEL_ORG_RESEARCH_MARINE_CRYO);
mappings.put("ice",         LABEL_ORG_RESEARCH_ICE);
mappings.put("okosystemer", LABEL_ORG_RESEARCH_ICE_ECOSYSTEMS);
mappings.put("fimbul",      LABEL_ORG_RESEARCH_ICE_FIMBUL);
mappings.put("havis",       LABEL_ORG_RESEARCH_ICE_SEA_ICE);
mappings.put("miljogift",   LABEL_ORG_RESEARCH_ECOTOX);
mappings.put("support",     LABEL_ORG_RESEARCH_SUPPORT);
mappings.put("komm",        LABEL_ORG_COMM);
mappings.put("info",        LABEL_ORG_COMM_INFO);
mappings.put("leder",       LABEL_ORG_LEADER);
mappings.put("mika",        LABEL_ORG_ENVMAP);
mappings.put("data",        LABEL_ORG_ENVMAP_DATA);
mappings.put("forvaltning", LABEL_ORG_ENVMAP_MANAGEMENT);
mappings.put("kart",        LABEL_ORG_ENVMAP_MAP);
mappings.put("ola",         LABEL_ORG_OL);
mappings.put("antarktis",   LABEL_ORG_OL_ANTARCTIC);
mappings.put("arktis",      LABEL_ORG_OL_ARCTIC);
mappings.put("other",       LABEL_ORG_OTHER);
mappings.put("ac",          LABEL_ORG_OTHER_AC);
mappings.put("clic",        LABEL_ORG_OTHER_CLIC);
mappings.put("na2011",      LABEL_ORG_OTHER_NA2011);
mappings.put("nysmac",      LABEL_ORG_OTHER_NYSMAC);
mappings.put("ssf",         LABEL_ORG_OTHER_SSF);
mappings.put("jobtitle.no", LABEL_JOB_TITLE);
mappings.put("jobtitle.en", LABEL_JOB_TITLE);
mappings.put("orgtree",     LABEL_ORG_AFFIL);
mappings.put("workplace",   LABEL_WORKPLACE);


mappings.put("biodiversity", LABEL_BIODIVERSITY);
mappings.put("climate", LABEL_CLIMATE);
mappings.put("geology", LABEL_GEOLOGY);
mappings.put("geophysics", LABEL_GEOPHYSICS);
mappings.put("glaciers", LABEL_GLACIERS);
mappings.put("glaciology", LABEL_GLACIERS);
mappings.put("marine ecosystems", LABEL_MARINE_ECOSYSTEMS);
mappings.put("oceanography", LABEL_OCEANOGRAPHY);
mappings.put("environmental pollutants", LABEL_ENVIRONMENTAL_POLLUTANTS);
mappings.put("ecotoxicology", LABEL_ECOTOXICOLOGY);
mappings.put("seaice", LABEL_SEA_ICE);
mappings.put("biology", LABEL_BIOLOGY);
mappings.put("ecology", LABEL_ECOLOGY);
mappings.put("ecosystems", LABEL_ECOSYSTEMS);
mappings.put("marine", LABEL_MARINE);
mappings.put("topography", LABEL_TOPOGRAPHY);

mappings.put("people.email", LABEL_EMAIL);
mappings.put("publication_year", LABEL_PUBYEAR);
mappings.put("topics", LABEL_TOPIC);

norm.put("publication_type", "publication.type");
norm.put("topics", "topic");
norm.put("research_stations", "research.station");
norm.put("The Arctic", "arctic");
norm.put("Antarctic", "antarctic");
norm.put("Framstredet", "framstredet");
norm.put("The+Arctic", "arctic");
norm.put("The+Arctic", "arctic");
norm.put("The+Arctic", "arctic");
//*/



ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
ProjectService service = new ProjectService(locale);

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
    URL url = new URL(service.getServiceBaseURL().concat("?q="));    
    HttpURLConnection connection = (HttpURLConnection)url.openConnection();
    connection.setRequestMethod("GET");
    connection.setReadTimeout(7000);
    connection.connect();
    responseCode = connection.getResponseCode();
} catch (Exception e) {
} finally {
    if (responseCode != 200) {
        out.println("<div class=\"error\">" + ERROR_MSG_NO_SERVICE + "</div>");
        
        // Send error message
        try {
            String lastErrorNotificationTimestampName = "last_err_notification_projects";
            int errorNotificationTimeout = 1000*60*60*12; // 12 hours
            Date lastErrorNotificationTimestamp = (Date)application.getAttribute(lastErrorNotificationTimestampName);
            if (lastErrorNotificationTimestamp == null // No previous error
                    || (lastErrorNotificationTimestamp.getTime() + errorNotificationTimeout) < new Date().getTime()) { // Previous error sent, but timeout exceeded
                application.setAttribute(lastErrorNotificationTimestampName, new Date());
                CmsSimpleMail errorMail = new CmsSimpleMail();
                errorMail.addTo("web@npolar.no");
                errorMail.setFrom("no-reply@npolar.no");
                errorMail.setSubject("Error on NPI website / data centre");
                errorMail.setMsg("The page at " + OpenCms.getLinkManager().getOnlineLink(cmso, requestFileUri) + (request.getQueryString() != null ? "?".concat(request.getQueryString()) : "")
                        + " is having problems connecting to the data centre."
                        + "\n\nPlease look into this."
                        + "\n\nThis notification was generated because the data centre is down, frozen/hanging, or did not respond with the expected response code \"200 OK\"."
                        + "\n\nGenerated by OpenCms: " + cms.info("opencms.uri") + " - No further notifications will be sent for the next " + errorNotificationTimeout/(1000*60*60) + " hour(s).");
                errorMail.send();
            }
        } catch (Exception e) { 
            out.println("\n<!-- \nError sending error notification: " + e.getMessage() + " \n-->");
        }
        
        return;
    }
}

// Set defaults (override regular defaults)
Map<String, String[]> defaultParams = new HashMap<String, String[]>();
defaultParams.put("filter-draft", new String[]{ "no" });
//defaultParams.put("filter-state", new String[]{ "published" });
defaultParams.put("facets", new String[]{ "area,state,topics,type" });  // This is why we're overriding the regular defaults; we want full filter control
defaultParams.put("size-facet", new String[]{ "9999" }); // Get all possible filters
service.setDefaultParameters(defaultParams);

try {
    // START NEW
    Map<String, String[]> params = new HashMap<String, String[]>();
    //params.put("sort", new String[]{ "-published-year,-published-date" }); // By not having this in default parameters, we make it URL visible (and user overrideable)
            
    params.putAll(request.getParameterMap());
    
    Iterator<String> iParam = params.keySet().iterator();
    while (iParam.hasNext()) {
        String key = iParam.next();
        //params.put(key, new String[] { URLEncoder.encode(params.get(key)[0], "utf-8") });
        //*
        String[] val = params.get(key);
        for (int iVal = 0; iVal < val.length; iVal++) {
            val[iVal] = URLEncoder.encode(val[iVal], "utf-8");
        }
        params.put(key, val);
        //*/
    }       
    
    
    
    if (!params.containsKey("q"))
        params.put("q", new String[]{ "" });
    //else
    //    params.put("q", new String[] { URLEncoder.encode(params.get("q")[0], "utf-8") });
    
    List<Project> list = service.getProjectList(params);
    //out.println("<h1>Matched " + pubService.getTotalResults() + " publications (" + pubList.size() + " per page), " 
    //        + (pubService.isUserFiltered() ? "" : " NOT") + " filtered by user.</h1>");
    
    //out.println("<h4>" + pubService.getLastServiceURL() + "</h4>");
    
    SearchFilterSets filterSets = service.getFilterSets();
    String lastSearchPhrase = service.getLastSearchPhrase();
    int totalResults = service.getTotalResults();

        // Query 
        %>
        <div class="searchbox-big">
            <h2><%= LABEL_SEARCHBOX_HEADING %></h2>
            <form action="<%= cms.link(requestFileUri) %>" method="get">
                <input name="q" type="search" value="<%= lastSearchPhrase == null ? "" : CmsStringUtil.escapeHtml(lastSearchPhrase) %>" />
                <input name="start" type="hidden" value="0" />
                <input type="submit" value="<%= LABEL_SEARCH %>" />
            
            <div id="filters-wrap"> 
                <a id="filters-toggler" onclick="$('#filters').slideToggle();" href="javascript:void(0);"><%= LABEL_FILTERS %></a>
                <div id="filters">
                    <%
                    if (!filterSets.isEmpty()) {
                        Iterator<SearchFilterSet> iFilterSets = filterSets.iterator();
                        out.println("<section class=\"layout-row quadruple clearfix\">");
                        out.println("<div class=\"boxes\">");
                        while (iFilterSets.hasNext()) {
                            SearchFilterSet filterSet = iFilterSets.next();
                            //String filterSetName = filterSet.getName();
                            List<SearchFilter> filters = filterSet.getFilters();
                            
                            if (filters != null) {
                                out.println("<div class=\"span1\">");
                                out.print("<h3 class=\"filters-heading\" style=\"font-size:1.5em;\">");
                                out.print(filterSet.getTitle(locale));
                                /*try {
                                    out.print(labels.getString(normalize(filterSetName)));
                                } catch (Exception transE) {
                                    out.print(filterSetName);
                                }*/
                                out.print(" (" + filterSet.size() + ")");
                                out.println("</h3>");
                                out.println("<ul>");
                                try {
                                    // Iterate through the filters in this set
                                    Iterator<SearchFilter> iFilters = filters.iterator();
                                    while (iFilters.hasNext()) {
                                        SearchFilter filter = iFilters.next();
                                        // The visible filter text (initialize this as the term)
                                        String filterText = filter.getTerm();
                                        try {
                                            // Try to fetch a better (and localized) text for the filter
                                            filterText = labels.getString( filterSet.labelKeyFor(filter) );
                                        } catch (Exception skip) {}
                                        out.println("<li><a href=\"" + cms.link(requestFileUri + "?" + CmsStringUtil.escapeHtml(filter.getUrlPartParameters())) + "\">" 
                                                            + (filter.isActive() ? "<span style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\" class=\"remove-filter\">X</span> " : "")
                                                            + filterText
                                                            + " (" + filter.getCount() + ")"
                                                        + "</a></li>");
                                    }
                                } catch (Exception filterE) {
                                    out.println("<!-- " + filterE.getMessage() + " -->");
                                }
                                out.println("</ul>");
                                out.println("</div>");
                            }
                        }
                        out.println("<div class=\"span1\">");
                        %>
                        
                        <%
                        out.println("</div>");
                        out.println("</div>");
                        out.println("</section>");
                    }
                    //out.println(getFacets(cms, json.getJSONArray("facets")));
                    %>
                    
                </div>
            </div>
            </form>
        </div>
        <%


    if (totalResults > 0) {

        int itemsPerPage = service.getItemsPerPage();
        int startIndex = service.getStartIndex();
        int pageNumber = (startIndex + itemsPerPage) / itemsPerPage;
        int pagesTotal = (int)(Math.ceil((double)(totalResults + itemsPerPage) / itemsPerPage)) - 1;

        String next = service.getNextPageParameters();
        String prev = service.getPrevPageParameters();

        %>
        <h2 style="color:#999; border-bottom:1px solid #eee;">
            <span id="totalResultsCount"><%= totalResults %></span> <%= LABEL_MATCHES.toLowerCase() %>
        </h2>

        <% if (!ONLINE) { %>
        <div id="admin-msg" style="margin:1em 0; background: #eee; color: #444; padding:1em; font-family: monospace; font-size:1.2em;"></div>
        <% } %>

        <ul class="fullwidth line-items blocklist">
            <%
            //for (int pCount = 0; pCount < entries.length(); pCount++) {
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

        <% if (pagesTotal > 1) { %>
        <nav class="pagination clearfix">
            <div class="pagePrevWrap">
                <% 
                if (pagesTotal > 1) { // More than one page total
                    if (pageNumber > 1) { // At least one previous page exists
                    %>
                        <!--<a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + prev) %>"><</a>-->
                        <a class="prev" href="<%= cms.link(requestFileUri + "?" + prev) %>"></a>
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
                            <a href="<%= cms.link(requestFileUri + "?" + getDynamicParams(cms, false) + "&amp;start=" + ((pageCounter-1) * itemsPerPage)) %>"><%= pageCounter %></a>
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
                        out.println("<!-- page " + pageCounter + " dropped ... -->");
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
                        <!--<a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(next)) %>">></a>-->
                        <a class="next" href="<%= cms.link(requestFileUri + "?" + next) %>"></a>
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

//String facetsJSReady = getFacets(cms, json.getJSONArray("facets")).replaceAll("\"", "\\\\\"");
//<script type="text/javascript">
//    $("#filters").html("%= facetsJSReady %");
//</script>
%>

<%
if (!service.isUserFiltered()) {
%>
<script type="text/javascript">
    $("#filters").hide();
</script>

<%
}

// Clear all static vars
dp.clear();
//sw.clear();
//activeFacets.clear();
//mappings.clear();
//norm.clear();
%>
