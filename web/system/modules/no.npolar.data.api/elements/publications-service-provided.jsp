<%-- 
    Document   : publications-service-provided
    Description: Lists publications using the data.npolar.no API.
    Created on : Nov 1, 2013, 1:11:42 PM
    Author     : flakstad
--%><%@page import="no.npolar.data.api.*,
            no.npolar.data.api.util.APIUtil,
            no.npolar.util.CmsAgent,
            org.apache.commons.httpclient.params.HttpParams,
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

/**
 * Default ("system") parameters: The end-user should never see these.
 */
public static Map<String, String> getDefaultParamMap() {
    if (dp.isEmpty()) {
        dp.put(PublicationService.Param.SORT_BY, PublicationService.modReverse(Publication.Key.PUB_TIME));
        //dp.put("sort", "-publication_year");
        dp.put(PublicationService.Param.FORMAT, APIService.ParamVal.FORMAT_JSON);
        dp.put(PublicationService.modFilter(Publication.Key.DRAFT), Publication.Val.DRAFT_FALSE);
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
            if (PublicationService.Param.START_AT.equals(pName) && !includeStart
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
            s += PublicationService.Param.QUERY + "=" + URLEncoder.encode(getParameter(cms, PublicationService.Param.QUERY), "utf-8");
        } catch (Exception e) {
            s += PublicationService.Param.QUERY + "=" + getParameter(cms, PublicationService.Param.QUERY);
        }

        // Items per page
        s += "&" + PublicationService.Param.RESULTS_LIMIT + "=" + getLimit(cms);

        // Start index
        if (includeStart && (start != null && !start.isEmpty()))
            s += "&" + PublicationService.Param.START_AT + "=" + start;
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
    return getParameter(cms, PublicationService.Param.RESULTS_LIMIT).isEmpty() ? "25" : getParameter(cms, PublicationService.Param.RESULTS_LIMIT);
}

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
final String LABEL_YEAR_SELECT_OPT_ALL = loc.equalsIgnoreCase("no") ? "Alle år" : "All years";

final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");

final boolean EDITABLE_TEMPLATE = false;


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

// 3 calendar instances: 
// - today
// - range start
// - range end
Calendar todayCal = new GregorianCalendar();
/*
Calendar ylowCal = new GregorianCalendar();
ylowCal.clear();
if (ylow > -1) {
    ylowCal.set(ylow, Calendar.JANUARY, 1, 0, 0, 0);
} else {
    ylowCal.set(1, Calendar.JANUARY, 1, 0, 0, 0);
}

Calendar yhighCal = new GregorianCalendar();
yhighCal.clear();
if (yhigh > -1) {
    yhighCal.set(yhigh, Calendar.DECEMBER, 31, 23, 59, 59);
} else {
    yhighCal.set(2999, Calendar.DECEMBER, 31, 23, 59, 59);
}*/
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
mappings.put("year-published_sort", LABEL_PUBYEAR);
mappings.put("topics", LABEL_TOPIC);

norm.put("publication_type", "publication.type");
norm.put("topics", "topic");
norm.put("research_stations", "research.station");

// HACKS!!! :-O
norm.put("programme", loc.equalsIgnoreCase("no") ? "Program" : "Programme");
norm.put("programme.Biodiversity", loc.equalsIgnoreCase("no") ? "Biodiversitet" : "Biodiversity");
norm.put("programme.Oceans and sea ice", loc.equalsIgnoreCase("no") ? "Hav og havis" : "Oceans and sea ice");
norm.put("programme.Geology and geophysics", loc.equalsIgnoreCase("no") ? "Geologi og geofysikk" : "Geology and geophysics");
norm.put("ICE Fluxes", loc.equalsIgnoreCase("no") ? "ICE-havis" : "ICE Fluxes");
norm.put("Environmental pollutants", loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Environmental pollutants");
norm.put("ICE Ecosystems", loc.equalsIgnoreCase("no") ? "ICE-økosystemer" : "ICE Ecosystems");
norm.put("ICE Antarctica", loc.equalsIgnoreCase("no") ? "ICE-Antarktis" : "ICE Antarctica");
norm.put("ICE", loc.equalsIgnoreCase("no") ? "ICE" : "ICE");
//*/




// Call master template (and output the opening part - hence the [0])
//cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE_TEMPLATE);

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
    URL url = new URL(pubService.getServiceBaseURL().concat("?" + PublicationService.Param.QUERY + "="));
    // set the connection timeout value to 30 seconds (30000 milliseconds)
    //final HttpParams httpParams = new BasicHttpParams();
    //HttpConnectionParams.setConnectionTimeout(httpParams, 30000);
    
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
            String lastErrorNotificationTimestampName = "last_err_notification_publications";
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

// Set new defaults (hidden / not overrideable parameters), overriding the standard defaults
Map<String, String[]> defaultParams = new HashMap<String, String[]>();

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
        "size-facet",// PublicationService.Param.FACETS_SIZE,
        "9999"
).addDefaultParameter(
        // Filter on "Yes, publication is affiliated to NPI"
        PublicationService.modFilter(Publication.Key.ORGS_ID),
        Publication.Val.ORG_NPI
); 
/*
//defaultParams.put("filter-state", new String[]{ "published" }); // Require state: published
//defaultParams.put("facets", new String[]{ "topics,category,publication_type,research_stations,locations" }); // This is why we're overriding the regular defaults; we want full filter control
//defaultParams.put("facets", new String[]{ "topics,category,publication_type,research_stations,area" });
defaultParams.put(APIService.Param.FACETS, 
        new String[]{ 
            Publication.Key.TOPICS // "topics"
            //+ ",category"
            + "," + Publication.Key.TYPE // "publication_type"
            + "," + Publication.Key.STATIONS // "research_stations"
            + "," + Publication.Key.PROGRAMMES // "programme"
        }
);
defaultParams.put("size-facet", new String[]{ "9999" }); // Get all possible filters
// Filter on "Yes, publication is affiliated to NPI activity" (require this box was checked)
defaultParams.put(
        PublicationService.Param.MOD_FILTER+Publication.Key.ORGS_ID,
        new String[] { Publication.Val.ORG_NPI }
); 
pubService.setDefaultParameters(defaultParams);
//*/
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
        /*params.put(
                PublicationService.Param.SORT_BY, 
                new String[]{ PublicationService.ParamVal.PREFIX_REVERSE+Publication.Key.PUB_TIME }
        );*/
    } else {
        // Use default sort order (typically "by relevancy")
    }
    
    if (ylow > -1 || yhigh > -1) {
        pubService.addParameter(
                PublicationService.modFilter(Publication.Key.PUB_TIME), 
                normalizeTimestampFilterValue(ylow, yhigh)
        );
        /*params.put(
                SearchFilter.PARAM_NAME_PREFIX+Publication.Key.PUB_TIME, 
                new String[] { normalizeTimestampFilterValue(ylow, yhigh) }
        );*/
    }
            
    //params.putAll(request.getParameterMap());
    
    // ToDo: Do we really need to encode here..?
    Iterator<String> iParam = params.keySet().iterator();
    while (iParam.hasNext()) {
        String key = iParam.next();
        //params.put(key, new String[] { URLEncoder.encode(params.get(key)[0], "utf-8") });
        //*
        String[] val = params.get(key);
        /*
        // Is it a filter?
        if (key.startsWith(PublicationService.Param.MOD_FILTER)) {
            try {} catch (Exception e) {}
        }
        */
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
        //params.put(PublicationService.Param.QUERY, new String[]{ "" });
    } //else {
        //params.put("q", new String[] { URLEncoder.encode(params.get("q")[0], "utf-8") });
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
    
    // Adjust the order of the  filter sets
    filterSets.order(new String[] { 
        Publication.Key.TOPICS // topics
        ,Publication.Key.TYPE //"publication_type"
        ,Publication.Key.STATIONS //"research_stations"
        ,Publication.Key.PROGRAMMES //"programme" 
    });
    
    String lastSearchPhrase = pubService.getLastSearchPhrase();
    int totalResults = pubService.getTotalResults();
    
    String disclaimer = loc.equalsIgnoreCase("no") ? 
                            "<strong>Finner du ikke publikasjonen? Da kan du prøve et " + "<a href=\"" + cms.link("/no/publikasjoner/brage.html") + "\">" + "søk i vårt publikasjonsarkiv «Brage»" + "</a>.</strong><br />(Vi jobber med å samle alle publikasjonene i ett arkiv.)"
                            :
                            "<strong>Can't find the publication? Try " + "<a href=\"" + cms.link("/en/publications/brage.html") + "\">" + "searching our publications&nbsp;archive" + " «Brage»</a>.</strong><br />(We're working on offering all publications in a single archive.)";

        // Query 
        %>
        <div class="searchbox-big search-widget search-widget--filterable">
            <h2><%= LABEL_SEARCHBOX_HEADING %></h2>
            <p class="smalltext"><%= disclaimer %></p>
            
            <form action="<%= cms.link(requestFileUri) %>" method="get">
                <input name="<%= APIService.Param.QUERY %>" type="search" value="<%= lastSearchPhrase == null ? "" : CmsStringUtil.escapeHtml(lastSearchPhrase) %>" />
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
                <input class="cta cta--search-submit" type="submit" value="<%= LABEL_SEARCH %>" />
            
            <!--<div id="filters-wrap">-->
            <div class="filters-wrapper">
                <a class="cta cta--filters-toggle" id="filters-toggler" onclick="$('#filters').slideToggle();" tabindex="0"><%= LABEL_FILTERS %></a>
                
                <div id="filters" class="filters-container">
                    
                    <div class="layout-row single clearfix" style="text-align:center;">
                        <div class="boxes">
                            <div class="span1">
                                <div class="filter-widget">
                                    <h3 class="filters-heading filter-widget-heading"><%= LABEL_YEAR_SELECT %></h3>
                                    <input type="number" value="<%= ylow > -1 ? ylow : "" %>" name="<%= YLOW %>" id="range-year-low" style="padding:0.5em; border:1px solid #ddd; width:4em; font-size:1.25em;" /> 
                                    – <input type="number" value="<%= yhigh > -1 ? yhigh : "" %>" name="<%= YHIGH %>" id="range-year-high" style="padding:0.5em; border:1px solid #ddd; width:4em; font-size:1.25em;" />
                                    <div id="range-slider" style="margin: 2em 40px 0;"></div> 
                                    <br />
                                    <input type="button" class="cta cta--filters-toggle" value="Oppdater årstall" style="margin-top:1em;" onclick="submit()" />
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
                                                out.println("<a" + (filter.isActive() ? (" class=\"filter--active\"") : "") 
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
                            Map<String, String[]> paramsTemp = new HashMap<String, String[]>(params);
                            paramsTemp.remove(YLOW);
                            paramsTemp.remove(YHIGH);
                            paramsTemp.remove(PublicationService.modFilter(Publication.Key.PUB_TIME));
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
        <%


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
                            <a href="<%= cms.link(requestFileUri + "?" + StringEscapeUtils.escapeHtml(getDynamicParams(cms, false) + "&" + APIService.Param.START_AT + "=" + ((pageCounter-1) * itemsPerPage))) %>"><%= pageCounter %></a>
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
                        <!--<a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(next)) %>">></a>-->
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
//*/

//String facetsJSReady = getFacets(cms, json.getJSONArray("facets")).replaceAll("\"", "\\\\\"");
//<script type="text/javascript">
//    $("#filters").html("%= facetsJSReady %");
//</script>
%>

<%
if (true) {//(!pubService.isUserFiltered()) {
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
<%
}

// Clear all static vars
dp.clear();
sw.clear();
//activeFacets.clear();
//mappings.clear();
//norm.clear();
%>
