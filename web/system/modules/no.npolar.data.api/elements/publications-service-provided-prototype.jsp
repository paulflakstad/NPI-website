<%-- 
    Document   : publications-service-provided
    Description: Lists publications using the data.npolar.no API.
    Created on : Nov 1, 2013, 1:11:42 PM
    Author     : flakstad
--%><%@page import="org.apache.commons.lang.StringUtils,
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
static List<String> sw = new ArrayList<String>();
/* Map storage for active facets (filters). */
static Map<String, String> activeFacets = new HashMap<String, String>();
/* Facet (filter) parameter name prefix. */
final static  String FACET_PREFIX = "filter-";
/* On-screen/service value mappings. */
public static Map<String, String> mappings = new HashMap<String, String>();

public String getFacets(CmsAgent cms, JSONArray facets) throws JSONException, java.io.IOException {
    String requestFileUri = cms.getRequestContext().getUri();
    //cms.getResponse().getWriter().print("<!-- uri = " + requestFileUri + "?" + cms.getRequest().getQueryString() + " -->");
    List<String> hiddenFacets = new ArrayList(
                                                Arrays.asList(
                                                    new String[] { 
                                                        "links.rel"
                                                        , "links.href"
                                                        , "organisation"
                                                        , "category"
                                                        , "draft"
                                                    }
                                                )
                                            );
    String s = "<section class=\"clearfix quadruple layout-row overlay-headings\">";
    s += "<div class=\"boxes\">";

    for (int i = 0; i < facets.length(); i++) {
        JSONObject facetSet = facets.getJSONObject(i);
        String facetSetName = facetSet.names().get(0).toString();
        if (!hiddenFacets.contains(facetSetName)) {
            JSONArray facetArray = facetSet.getJSONArray(facetSetName);
            if (facetArray.length() > 0) { 
                s += "<div class=\"span1 featured-box facets-set\">";
                s += "<h3>" + capitalize(getMapping(facetSetName)) + "</h3>";
                s += "<ul>";
                for (int j = 0; j < facetArray.length(); j++) {
                    JSONObject facet = facetArray.getJSONObject(j);
                    String facetLink = getFacetLink(cms, facetSetName, facet);
                    if (!getStopWords().contains(facet.get("term")))
                        s += "<li>" + facetLink + "</li>";
                }
                s += "</ul></div>";
            }
        }
    }
    s += "</div></section>";
    return s;
}
 
/**
 * Gets the link for a given facet/filter.
 */
public String getFacetLink(CmsAgent cms, String facetSetName, JSONObject facetDetails) throws JSONException, java.io.IOException {
    PrintWriter w = cms.getResponse().getWriter();
    String requestFileUri = cms.getRequestContext().getUri();
    
    String facetTerm = facetDetails.get("term").toString();
    String facetCount = facetDetails.get("count").toString();
    String facetUri = facetDetails.get("uri").toString();
    
    String facetText = getMapping(facetTerm);
    String facetToggleUri = requestFileUri.concat("?").concat(getFacetParameterString(facetUri));
    
    boolean active = false;
    
    // Get activated facets/filters
    Map<String, String> af = getActiveFacets(cms);
    // Check if there are active facet(s) for this facet set
    if (af.containsKey(FACET_PREFIX + facetSetName)) {
        // Get the 
        if (getFacetKeys(af.get(FACET_PREFIX + facetSetName)).contains(facetTerm)) {
            active = true;
            // Get the parameter string to use for deactivating this facet/filter
            String removeParams = getFacetDeactivateParameterString(facetTerm, facetDetails, facetSetName);
            facetToggleUri = requestFileUri.concat("?").concat(removeParams);
        } else {
            //w.println("<!-- Filter '" + FACET_PREFIX + facetSetName + "' was present, but was not a filter for '" + facetTerm + "' ('" + af.get(FACET_PREFIX + facetSetName) + "'). -->");
        }
    } else {
        //w.println("<!-- No '" + FACET_PREFIX + facetSetName + "' filters present. -->");
    }
    
    
    //String requestFullUri = requestFileUri + "?" + cms.getRequest().getQueryString().replaceAll("\\&", "&amp;");
    //boolean active = facetUri.equals(requestFullUri);
    
    //cms.getResponse().getWriter().println("<!-- comparing '" + facetUri + "' to '" + requestFullUri + "': active=" + active + " -->");
    
    facetToggleUri = facetToggleUri.replaceAll("\\&", "&amp;");
    
    return "<a href=\"" + cms.link(facetToggleUri) + "\"" + (active ? " style=\"font-weight:bold;\"" : "") + ">" 
                + (active ? "<span style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\" class=\"remove-filter\">X</span> " : "")
                + facetText 
            + "</a>"
            + "&nbsp;(" + facetCount + ")";
    /*
    String facetText = facetDetails.get("term").toString();
    String facetCount = facetDetails.get("count").toString();
    String facetUri = cms.getRequestContext().getUri().concat("?").concat(getParameterString(facetDetails.get("uri").toString()));
    return "<a href=\"" + cms.link(facetUri) + "\">" + facetText + " (" + facetCount + ")</a>";
    */
}

/**
 * Gets the complete parameter string to use for deactivating an active facet/filter.
 */
public String getFacetDeactivateParameterString(String facetTerm, JSONObject facetDetails, String facetSetName) throws JSONException {
    String s = "";
    
    // Get the parameter string from the facet's URI
    String fps = getFacetParameterString(facetDetails.get("uri").toString());
    // Split it up into parameters
    String[] fpsParts = fps.split("\\&");
    
    // Loop all parameters
    for (int i = 0; i < fpsParts.length;) {
        // Split the parameter name (key) and the value
        String[] keyVal = fpsParts[i].split("=");
        // Get the parameter name (key)
        String key = keyVal[0];
        String value = "";
        
        List<String> v = null;
        try {
            // Get the value(s)
            v = getFacetKeys(keyVal[1]);
            // Check if this is the parameter to modify
            if (FACET_PREFIX.concat(facetSetName).equals(key)) { // Match
                if (!v.remove(facetTerm)) // Remove the facet term from the list of values
                    throw new Exception("Unable to remove filter value '" + facetTerm + "'.");
            }
            value = listToCSVString(v);
            //s += listToCSVString(v);
        } catch (Exception e) {
            // Ignore:
            // Most likely due to empty value (index out of bounds on keyVal[1])
        }
        
        if (!value.isEmpty() || !key.startsWith(FACET_PREFIX))
            s += key + "=" + value; // Add parameter name
        
        if (++i < fpsParts.length)
            s += "&";
    }
    s = s.replaceAll("\\&\\&", "&"); // Remove redundant & chars
    if (s.endsWith("&"))
        s = s.substring(0, s.length() - "&".length()); // Remove trailing & chars
    return s;
}

/**
 * Constructs a list of keys based on the given keyString. The keyString may 
 * contain a single value or multiple (comma-separated) values.
 */
public List<String> getFacetKeys(String keyString) {
    // Create the list by splitting on commas.
    List<String> facetKeys = new ArrayList<String>(Arrays.asList(keyString.split(",")));
    
    return facetKeys;
}

/**
 * Constructs the parameter string to use when creating filter links.
 * This method will remove any default parameters (like "format=json") and 
 * escape ampersands so the parameter string is ready to use in a link.
 */
public String getFacetParameterString(String url) {
    String s = "";
    // The default parameters
    Map defaultParamMap = getDefaultParamMap();
    // The parameter string
    String parameterString = getParameterString(url);
    // The parameters
    String[] parameters = parameterString.split("\\&");
    
    // Check: Require parameters present
    if (defaultParamMap == null
            || defaultParamMap.isEmpty() 
            || parameters == null 
            || parameters.length == 0)
        return parameterString;
    
    int pCount = 0;
    for (int i = 0; i < parameters.length; i++) {
        String[] keyVal = parameters[i].split("=");
        String k = keyVal[0];
        if (!defaultParamMap.containsKey(k)) {
            s += (pCount++ > 0 ? "&" : "") + k + "=";
            try {
                s += keyVal[1];
            } catch (Exception e) {
                // Do nothing (there was no value)
            }
        }
    }
    return s;
}

/**
 * Gets all activated facets/filters.
 */
public Map<String, String> getActiveFacets(CmsJspActionElement cms) {
    // Fill the map only once
    if (activeFacets.isEmpty()) {
        // Empty map, get the request's parameter map
        Map<String, String[]> pm = cms.getRequest().getParameterMap();
        
        // No parameters present, nothing to do...
        if (pm == null || pm.isEmpty())
            return activeFacets;
        
        // Loop all request parameters
        Iterator<String> iKeys = pm.keySet().iterator();
        while (iKeys.hasNext()) {
            String k = iKeys.next();
            // Check parameter name, if it starts with the facet prefix, add the key/value pair to the active facets map
            if (k.startsWith(FACET_PREFIX))
                activeFacets.put(k, arrayToCSVString(pm.get(k)));
        }
    }
    // Return map
    return activeFacets;
    
}

/**
 * Converts the given JSON array to a list, either comma separated or HTML li elements.
 */
public String stringify(JSONArray a, boolean asListItems) {
    try {
        String s = "";
        for (int i = 0; i < a.length(); i++) {
            if (asListItems)
                s += "<li>" + a.getString(i) + "</li>";
            else {
                if (i > 0) 
                    s += ", ";
                s += a.getString(i);
            }
        }
        
        return s;
    } catch (Exception e) {
        return null;
    }
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
 * Requests the given URL and returns the response content payload as a string.
 */
public String getResponseContent(String requestURL) {
    try {
        URLConnection connection = new URL(requestURL).openConnection();
        StringBuffer buffer = new StringBuffer();
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String inputLine;
        while ((inputLine = reader.readLine()) != null) {
            buffer.append(inputLine);
        }
        reader.close();
        return buffer.toString();
    } catch (Exception e) {
        // Unable to contact or read the DB service
        return null;
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
 * Gets the default ("system") parameters as a string. 
 * The end-user should never see these parameters.
 */
public static String getDefaultParams() {
    String s = "";
    
    Map<String, String> defaultParamMap = getDefaultParamMap();
    Iterator<String> iParamName = defaultParamMap.keySet().iterator();
    while (iParamName.hasNext()) {
        String paramName = iParamName.next();
        String paramVal = defaultParamMap.get(paramName);
        s += paramName + "=" + paramVal + (iParamName.hasNext() ? "&" : "");
    }
    /*
    // Sorting 
    s += "&sort=last_name";

    // Format
    s += "&format=json";
    */
    return s;
}
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
 * Stop words.
 */
public static List<String> getStopWords() {
    if (sw.isEmpty()) {
        sw.add("og");
        sw.add("av");
    }
    return sw;
}

/**
 * Gets the default ("system") parameter names. 
 * Equivalent to getDefaultParamMap().keySet().
 */
public static List<String> getDefaultParamNames() {
    /*return new ArrayList(Arrays.asList(new String[] {"sort", "format"}));*/
    return Arrays.asList((String[])getDefaultParamMap().keySet().toArray());
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
 * Capitalizes the first letter in the given string.
 */
public static String capitalize(String s) {
    try {
        return s.replaceFirst(String.valueOf(s.charAt(0)), String.valueOf(s.charAt(0)).toUpperCase());
    } catch (Exception e) {
        return s;
    }
}

/**
 * Converts the given array of strings to a single comma separated string.
 */
public String arrayToCSVString(String[] arr) {
    return listToCSVString(Arrays.asList(arr));
}

/**
 * Converts the given list of strings to a single comma separated string.
 */
public String listToCSVString(List<String> list) {
    String s = "";
    Iterator<String> i = list.iterator();
    while (i.hasNext()) {
        s += i.next();
        if (i.hasNext())
            s += ",";
    }
    return s;
}

/** 
 * Swap the value retrieved from the service with the "nice" value.
 */
public String getMapping(String serviceValue) {
    String s = mappings.get(serviceValue);
    if (s != null && !s.isEmpty())
        return s;
    return serviceValue;
}

public String getAuthors(JSONObject o) throws JSONException {
    String authorStr = "";
    JSONArray persons = null;
    try {
        persons = o.getJSONArray("people");
    } catch (Exception e) {
        // No "people" array available, return empty string
        return authorStr;
    }
    
    for (int i = 0; i < persons.length(); i++) {
        try {
            JSONObject person = persons.getJSONObject(i);
            boolean isAuthor = false;
            boolean isNPIContributor = false;
            String email = null;
            String name = "";

            JSONArray roles = null;
            try {
                roles = person.getJSONArray("roles");
            } catch (Exception e) {
                // No role defined, assume role=author
                isAuthor = true;
            }
            if (roles != null) {
                for (int j = 0; j < roles.length(); j++) {
                    String role = roles.getString(j);
                    if (role.equalsIgnoreCase("author")) {
                        isAuthor = true;
                        break;
                    }
                }
            }
            
            try { if (person.getString("organisation").equalsIgnoreCase("npolar.no")) isNPIContributor = true; } catch (Exception e) {}

            if (isAuthor) {
                if (isNPIContributor)
                    authorStr += "<strong>";
                
                try { 
                    name += person.getString("first_name"); 
                } catch (Exception e) { 
                    name += "[unknown]"; 
                }
                name += " ";
                try { 
                    name += person.getString("last_name"); 
                } catch (Exception e) { 
                    name += "[unknown]"; 
                }
                
                authorStr += name;
                
                if (isNPIContributor)
                    authorStr += "</strong>";
                authorStr += ", ";
            }
            
            try {
                email = person.getString("email");
                mappings.put(email, name);
            } catch (Exception e) {
                
            }
        } catch (Exception e) {
            continue;
        }
    }
    
    if (authorStr.endsWith(", "))
        authorStr = authorStr.substring(0, authorStr.length() - 2);
    
    return authorStr;
}
%><%


CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();

final String LABEL_SEARCH_EMPLOYEES = loc.equalsIgnoreCase("no") ? "Søk i publikasjoner" : "Search publications";

final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
final String LABEL_SEARCH = cms.label("label.np.search");
final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
final String LABEL_MATCHES = cms.label("label.np.matches");
final String LABEL_FILTERS = cms.label("label.np.filters");

final boolean EDITABLE_TEMPLATE = false;

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




// Call master template (and output the opening part - hence the [0])
//cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE_TEMPLATE);

// Service details
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PORT = "80";
final String SERVICE_PATH = "/publication/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;

String dynamicParameters = getDynamicParams(cms, true);
String defaultParameters = getDefaultParams();
// Construct the URL to the service providing all neccessary data
String queryURL = SERVICE_BASE_URL + "?" + defaultParameters + (!dynamicParameters.isEmpty() ? "&".concat(dynamicParameters) : "");

out.println("<!-- using service URL " + queryURL + " -->");

%>
<!--<article class="main-content">-->
<%

JSONObject json = null;
try {
    // Read the JSON string
    String jsonStr = getResponseContent(queryURL);

    try {
        // Create the JSON object from the JSON string
        json = new JSONObject(jsonStr).getJSONObject("feed");
    } catch (Exception jsone) {
        %>
        <pre>
        <% jsone.printStackTrace(response.getWriter()); %>
        </pre>    
        <%
        return;
    }

    // Date formats
    SimpleDateFormat dfParse = new SimpleDateFormat("yyyy-dd-MM");
    SimpleDateFormat dfPrint = new SimpleDateFormat("d MMM yyyy");

    // Reference date
    Date now = new Date();





    // Project data variables
    String id = null;
    String title = null;
    String pubYear = null;
    String fName = null;
    String lName = null;
    String jobTitle = null;
    String personFolder = null;

    // Various JSON variables
    JSONObject openSearch = json.getJSONObject("opensearch");
    int totalResults = openSearch.getInt("totalResults");

    if (totalResults > 0) {

        // Query 
        %>
        <div class="searchbox-big">
            <h2><%= LABEL_SEARCH_EMPLOYEES %></h2>
            <form action="<%= cms.link(requestFileUri) %>" method="get">
                <input name="q" type="search" value="<%= CmsStringUtil.escapeHtml(getParameter(cms, "q")) %>" style="padding: 0.5em; font-size: larger;" />
                <!--<input name="limit" type="hidden" value="<%= getLimit(cms) %>" />-->
                <!--<input name="format" type="hidden" value="json" />-->
                <input name="start" type="hidden" value="0" />
                <input type="submit" value="<%= LABEL_SEARCH %>" />
            </form>
            <div id="filters-wrap"> 
                <a id="filters-toggler" onclick="$('#filters').slideToggle();"><%= LABEL_FILTERS %></a>
                <div id="filters">
                    <%
                    //out.println(getFacets(cms, json.getJSONArray("facets")));
                    %>
                </div>
            </div>
        </div>
        <%


        //
        // facets
        //


        int itemsPerPage = openSearch.getInt("itemsPerPage");
        int startIndex = openSearch.getInt("startIndex");
        int pageNumber = (startIndex + itemsPerPage) / itemsPerPage;
        int pagesTotal = (int)(Math.ceil((double)(totalResults + itemsPerPage) / itemsPerPage)) - 1;

        JSONObject list = json.getJSONObject("list");
        String next = null;
        try { next = list.getString("next"); } catch (Exception e) {  } ;
        String prev = list.getString("previous");
        //try { prev = list.getString("previous"); } catch (Exception e) {  } ;

        JSONObject search = json.getJSONObject("search");
        //JSONArray facets = json.getJSONArray("facets");





        JSONArray entries = json.getJSONArray("entries");
        out.println("<!-- entries.length() = " + entries.length() + " -->");

        %>
        <h2 style="color:#999; border-bottom:1px solid #eee;"><span id="totalResultsCount"><%= totalResults %></span> <%= LABEL_MATCHES.toLowerCase() %>
            <!--<em><%= CmsStringUtil.escapeHtml(getParameter(cms, "q")) %></em>-->
        </h2>

        <% if (!ONLINE) { %>
        <div id="admin-msg" style="margin:1em 0; background: #eee; color: #444; padding:1em; font-family: monospace; font-size:1.2em;"></div>
        <% } %>

        <ul class="pagelist" style="margin: 0; padding: 0; display: block;">
        
            <%
            for (int pCount = 0; pCount < entries.length(); pCount++) {
                JSONObject o = entries.getJSONObject(pCount);
                id = null;
                title = null;
                pubYear = null;
                // Mandatory fields
                try { 
                    id = o.getString("id");
                    title = o.getString("title");
                    try {
                        pubYear = String.valueOf(o.getInt("publication_year"));
                    } catch (Exception e) {
                        pubYear = String.valueOf(o.getInt("published-year"));
                    }
                    
                } catch (Exception e) { 
                    // Error on a mandatory field OR no corresponding folder => cannot output this
                    out.println("\n<!--\nSkipped publication [title=" + title + ", year=" + pubYear + ", id=" + id + "] (missing a mandatory field(s)), exception was\n" + e.getMessage() + "\n-->");
                    continue; 
                }
                // Optional fields
                //try { title = o.getString("title"); } catch (Exception e) {}
                //try { jobTitle = o.getJSONObject("jobtitle").getString(loc); } catch (Exception e) {}


                %>
                <li style="font-size:1em;">
                    <h3 style="margin:1em 0 0 0;"><a href="https://data.npolar.no/publication/<%= id %>"><%= title %></a></h3>
                    <span class="smalltext"><%= pubYear + " " + getAuthors(o) %></span>
                </li>
            <%      
            }  
            %>
        </ul>

        <% if (pagesTotal > 1) { %>
        <nav class="pagination clearfix">
            <div class="pagePrevWrap">
                <% 
                if (prev != null) {
                    if (pageNumber > 1) { // At least one previous page exists
                    %>
                        <!--<a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(prev)) %>"><</a>-->
                    <a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + getDynamicParams(cms, false) + "&amp;start=" + (startIndex-itemsPerPage)) %>"><</a>
                    <% 
                    }
                    else { // No previous page
                    %>
                        <a class="prev inactive"><</a>
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
                if (next != null) { 
                    if (pageNumber < pagesTotal) {
                        %>
                        <!--<a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(next)) %>">></a>-->
                        <a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + getDynamicParams(cms, false) + "&amp;start=" + (startIndex+itemsPerPage)) %>">></a>
                        <% 
                    }
                    else {
                        %>
                        <a class="next inactive">></a>
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
    out.println("<div class=\"paragraph\"><p>An error occured. Please try a different search or come back later.</p></div>");
    /*
    out.println("<pre>");
    e.printStackTrace(response.getWriter());
    out.println("</pre>");
    //*/ 
}
//*/
//String facetsJSReady = org.apache.commons.lang.StringEscapeUtils.escapeHtml(getFacets(cms, json.getJSONArray("facets")));
String facetsJSReady = getFacets(cms, json.getJSONArray("facets")).replaceAll("\"", "\\\\\"");
%>
<script type="text/javascript">
    $("#filters").html("<%= facetsJSReady %>");
</script>
<%
if (getActiveFacets(cms).isEmpty()) {
%>
<!-- Raw data at <a style="color: #bbb;" href="<%= queryURL %>"><%= queryURL %></a> -->
<script type="text/javascript">
    $("#filters").hide();
</script>
<!--</article>-->

<%
}

// Call master template (and output the closing part - hence the [1])
//cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], EDITABLE_TEMPLATE);

// Clear all static vars
dp.clear();
sw.clear();
activeFacets.clear();
mappings.clear();
%>
