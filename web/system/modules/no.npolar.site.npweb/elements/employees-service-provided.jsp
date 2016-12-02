<%-- 
    Document   : employees-service-provided a.k.a. employees-service-provided-sorted-clientside
    Description: Lists employees using the data.npolar.no API and cross-checking with OpenCms.
    Created on : Oct 11, 2013, 10:19:24 AM
    Author     : flakstad
--%>
<%@page import="no.npolar.data.api.util.APIUtil"%>
<%@page import="java.text.Collator,
            java.util.Collections,
            org.apache.commons.lang.StringUtils,
            java.util.Set,
            java.io.PrintWriter,
            org.opencms.jsp.CmsJspActionElement,
            java.io.IOException,
            java.util.Locale,
            java.util.Comparator,
            java.net.URLDecoder,
            java.net.URLEncoder,
            org.opencms.main.OpenCms,
            org.opencms.mail.CmsSimpleMail,
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
            no.npolar.data.api.SearchFilterSets,
            no.npolar.util.CmsAgent,
            org.opencms.json.JSONObject,
            org.opencms.json.JSONException,
            org.opencms.file.CmsObject,
            org.opencms.file.CmsResource"
            contentType="text/html; charset=UTF-8" 
            pageEncoding="UTF-8" 
            session="true" 
 %>
<%@page trimDirectiveWhitespaces="true" %>
<%!
/* Map storage for default parameters. */
static Map<String, String> dp = new HashMap<String, String>();
/* Stop words. */
static List<String> sw = new ArrayList<String>();
/* Map storage for active facets (filters). */
static Map<String, String> activeFacets = new HashMap<String, String>();
/* Facet (filter) parameter name prefix. */
final static  String FACET_PREFIX = "filter-";
/* The searchphrase parameter name, as used by the service. */
final static String PARAM_NAME_SEARCHPHRASE_SERVICE = "q";// "q-first_name,last_name";
/* The searchphrase parameter name, as used locally. */
final static String PARAM_NAME_SEARCHPHRASE_LOCAL = "q";
/* The facets parameter name, as used by the service. */
final static String PARAM_NAME_FACETS_SERVICE = "facets";
/* The start index parameter name, as used by the service. */
final static String PARAM_NAME_START_SERVICE = "start";
/* On-screen/service value mappings. */
public static Map<String, String> mappings = new HashMap<String, String>();

public String getFacets(CmsAgent cms, JSONArray facets) throws JSONException, java.io.IOException {
    String requestFileUri = cms.getRequestContext().getUri();
    cms.getResponse().getWriter().print("<!-- uri = " + requestFileUri + "?" + cms.getRequest().getQueryString() + " -->");
    // Define the facets we do not want to show as filters
    List<String> hiddenFacets = new ArrayList(
                                                Arrays.asList(
                                                    new String[] { 
                                                        "on_leave"
                                                        //, "jobtitle.".concat(cms.getRequestContext().getLocale().toString().equalsIgnoreCase("no") ? "en" : "no") 
                                                        , "jobtitle.no"
                                                        , "jobtitle.en"
                                                        , "currently_employed"
                                                        , "organisation"
                                                    }
                                                )
                                            );
    String s = "<div class=\"layout-group quadruple layout-group--quadruple filter-widget\">";
    //s += "<div class=\"boxes\">";

    for (int i = 0; i < facets.length(); i++) {
        JSONObject facetSet = facets.getJSONObject(i);
        String facetSetName = facetSet.names().get(0).toString();
        if (!hiddenFacets.contains(facetSetName)) {
            //s += "\n<!-- " + facetSetName + " was not hidden -->";
            JSONArray facetArray = facetSet.getJSONArray(facetSetName);
            if (facetArray.length() > 0) { 
                //s += "\n\n<div class=\"span1 facets-set\">";
                s += "\n\n<div class=\"layout-box filter-set\">";
                s += "\n<h3 class=\"filters-heading filter-set__heading\">" + capitalize(getMapping(facetSetName)) + "</h3>";
                s += "\n<ul class=\"filter-set__filters\">";
                for (int j = 0; j < facetArray.length(); j++) {
                    JSONObject facet = facetArray.getJSONObject(j);
                    String facetLink = getFacetLink(cms, facetSetName, facet);
                    if (!getStopWords().contains(facet.get("term")))
                        s += "\n\t<li>" + facetLink + "</li>";
                }
                s += "\n</ul>";
                s += "\n</div>";
            }
        }
    }
    s += "</div>";
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
    
    // Try to remove all pre-defined parameters from the filter URL
    //try { facetUri = normalizeFilterLink(facetUri); } catch (Exception e) { }
    
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
            if (!removeParams.isEmpty())
                facetToggleUri = requestFileUri.concat("?").concat(removeParams);
            else
                facetToggleUri = requestFileUri;
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

    return "<a href=\"" + cms.link(facetToggleUri) + "\" class=\"filter" + (active ? " filter--active" : "") + "\" rel=\"nofollow\">" 
                //+ (active ? "<span style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\" class=\"remove-filter\">X</span> " : "")
                + facetText 
            + "<span class=\"filter__num-matches\"> (" + facetCount + ")</span>"
            + "</a>"
            ;
    
    /*return "<a href=\"" + cms.link(facetToggleUri) + "\"" + (active ? " style=\"font-weight:bold;\"" : "") + ">" 
                + (active ? "<span style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\" class=\"remove-filter\">X</span> " : "")
                + facetText 
            + "&nbsp;(" + facetCount + ")"
            + "</a>"
            ;*/
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
    if (s.equals("=")) // Happens when the last filter is removed
        s = "";
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
    // The default parameters (these will not be exposed)
    Map defaultParamMap = new HashMap(getPreDefParamMap());
    // Other parameters we don't want to expose? (value is not important here, only the key)
    defaultParamMap.put(PARAM_NAME_FACETS_SERVICE, ""); // Don't want the "facets" parameter in filter URLs
    defaultParamMap.put(PARAM_NAME_START_SERVICE, ""); // Don't want the "start" parameter in filter URLs
    
    // The parameter string of the given url
    String parameterString = getParameterString(url);
    // Split out the parameters
    String[] parameters = parameterString.split("\\&");
    
    // Check: Require that there is an actual *need* to change the given url
    if (defaultParamMap == null // No parameters to hide
            || defaultParamMap.isEmpty() // No parameters to hide
            || parameters == null // No parameters at all
            || parameters.length == 0) // No parameters at all
        return parameterString; // Don't need to change anything - just use the paramter string as-is
    
    int parameterCounter = 0;
    for (int i = 0; i < parameters.length; i++) {
        String[] keyVal = parameters[i].split("=");
        String paramName = keyVal[0];
        if (!defaultParamMap.containsKey(paramName)) {
            if (PARAM_NAME_SEARCHPHRASE_SERVICE.equals(paramName)) {
                // Prevent adding empty search phrase parameter to the filter (it's not necessary)
                try { String v = keyVal[1]; } catch (IndexOutOfBoundsException ioobe) { continue; }
            }
                       
            s += (parameterCounter++ > 0 ? "&" : "") + paramName + "=";
            try {
                s += keyVal[1];
            } catch (Exception e) {
                // Do nothing (there was no value)
            }
        }
    }
    
    if (s.equals("=")) // Happens when the user removes all filters
        return "";
    
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
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
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
public static String getDynamicParams(CmsAgent cms, boolean includeStart, boolean wildcardSearch) {
    String s = "";
    int i = 0;
    Map<String, String[]> pm = cms.getRequest().getParameterMap();
    
    if (!pm.isEmpty()) {
        // Parameters found in request - handle them
        //List<String> preDefParamNames = getPreDefParamNames(); // Names of pre-defined parameters
        Map preDefParamMap = getPreDefParamMap(); // Pre-defined parameters
        Iterator<String> pNames = pm.keySet().iterator();
        while (pNames.hasNext()) {
            String pName = pNames.next();
            
            if ((PARAM_NAME_START_SERVICE.equals(pName) && !includeStart)
                    //|| preDefParamNames.contains(pName))
                    || preDefParamMap.containsKey(pName))
                continue; // Ignore this if this is the "start" parameter and we've decided not to include it, OR if this is a pre-defined parameter
            
            String pValue = "";
            try { pValue = URLEncoder.encode(pm.get(pName)[0], "utf-8"); } catch (Exception e) { pValue = ""; }
            
            // Set the parameter name and value - and apply wildcard(s) to the searchphrase if needed (the service automatically applies a trailing wildcard)
            s += (++i > 1 ? "&" : "") 
                    + (pName.equals(PARAM_NAME_SEARCHPHRASE_LOCAL) ? PARAM_NAME_SEARCHPHRASE_SERVICE : pName) 
                    + "=" + (pName.equals(PARAM_NAME_SEARCHPHRASE_LOCAL) && wildcardSearch ? ("*".concat(pValue)) : pValue);
        }
    }
    else {
        // No parameters found in request - set initial/default values
        //String start = cms.getRequest().getParameter("start"); // Not necessary - we already know it's not there

        // Query
        try {
            //s += "q=" + URLEncoder.encode(getParameter(cms, "q"), "utf-8");
            s += PARAM_NAME_SEARCHPHRASE_SERVICE + "=" + URLEncoder.encode(getParameter(cms, PARAM_NAME_SEARCHPHRASE_LOCAL), "utf-8");
        } catch (Exception e) {
            //s += "q=" + getParameter(cms, "q");
            s += PARAM_NAME_SEARCHPHRASE_SERVICE + "=" + getParameter(cms, PARAM_NAME_SEARCHPHRASE_LOCAL);
        }

        // Items per page
        //s += "&limit=" + getLimit(cms); // Commented out: Limit should be set as a pre-defined parameter

        // Start index
        s += "&" + PARAM_NAME_START_SERVICE + "=0"; // We already know "start" is not set, so set it to default
        //if (includeStart && (start != null && !start.isEmpty()))
        //    s += "&" + PARAM_NAME_START_SERVICE + "=" + start;
    }
    return s;
}
/**
 * Gets the default ("system") parameters as a string. 
 * The end-user should never see these parameters.
 */
public static String getDefaultParams() {
    String s = "";
    
    Map<String, String> defaultParamMap = getPreDefParamMap();
    Iterator<String> iParamName = defaultParamMap.keySet().iterator();
    while (iParamName.hasNext()) {
        String paramName = iParamName.next();
        String paramVal = defaultParamMap.get(paramName);
        s += paramName + "=" + paramVal + (iParamName.hasNext() ? "&" : "");
    }
    
    return s;
}
/**
 * Pre-defined ("system") parameters. The end-user should never see these.
 */
public static Map<String, String> getPreDefParamMap() {
    if (dp.isEmpty()) {
        dp.put("sort", "last_name");
        dp.put("format", "json");
        dp.put("filter-currently_employed", "true");
        //dp.put("filter-currently_employed", "T");
        dp.put("limit", "999");
        //dp.put("limit", "all");
        dp.put("size-facet", "999");
        dp.put("facets", "workplace,orgtree");
    }
    return dp;
}
/*
public static String normalizeFilterLink(String filterUri) {
    String filterBase = filterUri.split("?")[0];
    String filterParamString = filterUri.split("?")[1];
    // To begin with, we want to remove all pre-defined parameters
    Map<String, String> removeParams = getPreDefParamMap();
    // Also, we want to remove the "facets" parameter
    removeParams.put("facets", "");
        
    try {
        // Create a parameter map from the filter URI
        Map<String, String[]> filterParams = CmsRequestUtil.createParameterMap(filterParamString);
        Iterator<String> pNames = filterParams.keySet().iterator();
        while (pNames.hasNext()) {
            String pName = pNames.next();
            if (removeParams.containsKey(pName))
                filterParams.remove(pName);
        }
        if (filterParams.isEmpty())
            return filterBase;
        else
            return filterBase.concat("?").concat(CmsAgent.getParameterString(filterParams));
    } catch (Exception e) {
        return "NULL";
    }
}*/

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
public static List<String> getPreDefParamNames() {
    /*return new ArrayList(Arrays.asList(new String[] {"sort", "format"}));*/
    return Arrays.asList((String[])getPreDefParamMap().keySet().toArray());
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
    return getParameter(cms, "limit").isEmpty() ? "500" : getParameter(cms, "limit");
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

/**
 * Returns the sort character for a given name. For example, "von Quillfeldt"
 * will return "Q", "Nilsen" will return "N" and "Aars" will return "Å".
 */
public String getSortChar(String name) {
    if (name == null || CmsStringUtil.isEmptyOrWhitespaceOnly(name))
        return ""; // Nothing to work with ...
    
    int i = 0;
    while (true) {
        try {
            String letter = String.valueOf(name.charAt(i));
            if (i == 0 && letter.equalsIgnoreCase("A")) {
                try {
                    String secondLetter = String.valueOf(name.charAt(i+1));
                    if (secondLetter.equalsIgnoreCase("a")) // We have a case of "Aa" => return "Å"
                        return "Å";
                } catch (Exception e) {
                    // Well never mind that then
                }
            }
            if (StringUtils.isAllUpperCase(letter))
                return letter; // Uppercase letter - return it
        } catch (Exception e) {
            break; // Evaluated all letters - break the endless loop
        }
        i++; // "Continue to next letter"
    }
    try {
        return String.valueOf(name.charAt(0)).toUpperCase(); // Fallback to the first character
    } catch (Exception e) {
        return ""; // Last resort (should never happen really)
    }
}

public class Employee {
    private String id = null;
    private String lName = null;
    private String fName = null;
    private String jobTitle = null;
    private String title = null;
    private String sortChar = null;
    private List naturalOrder = Arrays.asList(new String[] { });
    
    public Employee(String id, String lastName, String firstName) {
        this.id = id;
        lName = lastName;
        fName = firstName;
        setSortChar();
    }
    public String getId() { return this.id; }
    public String getFirstName() { return this.fName; }
    public String getLastName() { return this.lName; }
    public String getJobTitle() { return this.jobTitle; }
    public String getTitle() { return this.title; }
    public String getSortChar() { return sortChar; }
    
    public Employee setJobTitle(String jobTitle) {
        this.jobTitle = jobTitle;
        return this;
    }
    public Employee setTitle(String title) {
        this.title = title;
        return this;
    }
    private void setSortChar() {
        if (lName == null || CmsStringUtil.isEmptyOrWhitespaceOnly(lName))
            sortChar = "";

        int i = 0;
        while (true) {
            try {
                String letter = String.valueOf(lName.charAt(i));
                if (i == 0) {
                    try {
                        String secondLetter = String.valueOf(lName.charAt(i+1));
                        if (letter.equalsIgnoreCase("a") && secondLetter.equalsIgnoreCase("a")) { // "Aa" = "Å"
                            sortChar = "Å";
                            break;
                        }
                    } catch (Exception e) {
                        // Never mind that then
                    }
                }
                if (StringUtils.isAllUpperCase(letter)) {
                    sortChar = letter;
                    break;
                }
            } catch (Exception e) {
                break;
            }
            i++;
        }
    }
    public String getCmsFolder(Locale locale) {
        String baseFolder = locale.toString().equalsIgnoreCase("no") ? "/no/ansatte/" : "/en/people/";
        return baseFolder + id + "/";
    }
    public boolean hasCmsFolder(CmsObject cmso) {
        return cmso.existsResource(this.getCmsFolder(cmso.getRequestContext().getLocale()));
    }
}

/*##############################################################################
################################################################################
##############################################################################*/
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();

// This parameter should normally be set only when the user selected using suggestions
String requestedEmployeeUri = request.getParameter("employeeuri");
if (requestedEmployeeUri != null && !requestedEmployeeUri.isEmpty() && cmso.existsResource(requestedEmployeeUri)) {
    //CmsRequestUtil.redirectPermanently(cms, requestedEmployeeUri); // Bad method, sends 302
    cms.sendRedirect(requestedEmployeeUri, HttpServletResponse.SC_MOVED_PERMANENTLY);
}

String requestFileUri = cms.getRequestContext().getUri();
final Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final Comparator<Employee> COMP_SORT_CHAR = 
        new Comparator<Employee>() {
            public int compare(Employee thisOne, Employee thatOne) {
                java.text.Collator c = Collator.getInstance(new Locale("no")); // Use Norwegian to force Æ Ø Å to appear at the end
                return c.compare(thisOne.getSortChar(), thatOne.getSortChar());
                //return thisOne.getSortChar().compareTo(thatOne.getSortChar());
            }
        };

final boolean WILDCARD_SEARCH = true;

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();
final String EMPLOYEES_FOLDER = loc.equalsIgnoreCase("no") ? "/no/ansatte/" : "/en/people/";

final String LABEL_SEARCH_EMPLOYEES = cms.label("label.np.searchemployee");
final String LABEL_SEARCH           = cms.label("label.np.search");
final String LABEL_SEARCH_PH        = loc.equalsIgnoreCase("no") ? "Søk på navn, stilling, fagfelt" : "Search by name, job title, specialization";//cms.label("label.np.search");
final String LABEL_FILTERS          = cms.label("label.np.filters");
final String LABEL_MATCHES          = cms.label("label.np.matches");
final String LABEL_MATCHES_FOR      = cms.label("label.np.matches.for");
final String LABEL_NO_MATCHES       = cms.label("label.np.matches.none");

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

final String LABEL_ERROR_HEAD           = loc.equalsIgnoreCase("no") ? "Noe gikk galt" : "Something went wrong";
final String LABEL_ERROR_MSG            = loc.equalsIgnoreCase("no") ? "En feil i vårt system lager trøbbel med ansattlista. Vennligst prøv igjen senere." 
                                                                        : 
                                                                        "An error in our system is causing trouble with listing employees. Please try again later.";

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




// Call master template (and output the opening part - hence the [0])
//cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE_TEMPLATE);

// Service details
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PORT = "80";
final String SERVICE_PATH = "/person/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;

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
    URL url = new URL(SERVICE_BASE_URL.concat("?q="));
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
            String lastErrorNotificationTimestampName = "last_err_notification_persons";
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


String dynamicParameters = getDynamicParams(cms, true, WILDCARD_SEARCH);
String defaultParameters = getDefaultParams();
// Construct the URL to the service providing all neccessary data
String queryURL = SERVICE_BASE_URL + "?" + defaultParameters + (!dynamicParameters.isEmpty() ? "&".concat(dynamicParameters) : "");

//out.println("<!-- using service URL " + queryURL + " -->");

String mismatches = "";

%>
<!--<article class="main-content">-->
<%

JSONObject json = null;
try {
    // Read the JSON string
    String jsonStr = APIUtil.httpResponseAsString(queryURL);//getResponseContent(queryURL);
    
    out.println("<!-- API URL: " + queryURL + " -->");

    try {
        // Create the JSON object from the JSON string
        json = new JSONObject(jsonStr).getJSONObject("feed");
    } catch (Exception jsone) {
        if (!ONLINE) {
            %>
            <pre>
            <% jsone.printStackTrace(response.getWriter()); %>
            </pre>    
            <%
        } else {
            %>
            <h2><%= LABEL_ERROR_HEAD %></h2>
            <p><%= LABEL_ERROR_MSG %></p>
            <%
        }
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
    String fName = null;
    String lName = null;
    String jobTitle = null;
    String personFolder = null;

    // Various JSON variables
    JSONObject openSearch = json.getJSONObject("opensearch");
    int totalResults = openSearch.getInt("totalResults");

    // For now, just a dummy collection
    SearchFilterSets filterSets = new SearchFilterSets();

        // Query 
        %>
        <form class="search-panel" action="<%= requestFileUri %>" method="get" id="employeelookup">
        <!--<div class="searchbox-big search-widget search-widget--filterable">-->
            <h2 class="search-panel__heading"><%= LABEL_SEARCH_EMPLOYEES %></h2>
            
            <div class="search-widget">
                <div class="searchbox">
                    <input name="<%= PARAM_NAME_SEARCHPHRASE_LOCAL %>" type="search" placeholder="<%= LABEL_SEARCH_PH %>" value="<%= CmsStringUtil.escapeHtml(getParameter(cms, PARAM_NAME_SEARCHPHRASE_LOCAL)) %>" id="q" />
                    <input class="search-button" type="submit" value="<%= LABEL_SEARCH %>" />
                </div>
            </div>
            
            <input name="start" type="hidden" value="0" />
            <input name="employeeuri" type="hidden" id="employeeuri" value="" />
            <%
                out.println(filterSets.getFiltersWrapperHtmlStart(LABEL_FILTERS));
                out.println(getFacets(cms, json.getJSONArray("facets")));
                out.println(filterSets.getFiltersWrapperHtmlEnd());
            %>
        </form>
        <%


    if (totalResults > 0) {
        
        List<Employee> emps = new ArrayList<Employee>();

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
        
        String indexLetter = "notaletter";

        %>
        <div id="filters-details"></div>
        <h2 class="info-secondary serp-heading" style="color:#999; border-bottom:1px solid #eee;"><span id="totalResultsCount"><%= totalResults %></span> <%= LABEL_MATCHES.toLowerCase() %>
            <!--<em><%= CmsStringUtil.escapeHtml(getParameter(cms, "q")) %></em>-->
        </h2>

        <% if (!ONLINE) { %>
        <div id="admin-msg" style="margin:1em 0; background: #eee; color: #444; padding:1em; font-family: monospace; font-size:1.2em;"></div>
        <% } %>

        <!--<ul class="pagelist" style="margin: 0; padding: 0; display: block;">-->
        <table class="odd-even-table">
            <tbody>
            <%
            int resultsPrinted = 0;
            for (int pCount = 0; pCount < entries.length(); pCount++) {
                JSONObject o = entries.getJSONObject(pCount);
                Employee emp = null;

                // Mandatory fields
                try {
                    id = o.getString("id");
                    fName = o.getString("first_name");
                    lName = o.getString("last_name"); 
                    emp = new Employee(id, lName, fName);
                    personFolder = EMPLOYEES_FOLDER + id + "/";
                    if (!emp.hasCmsFolder(cms.getCmsObject())) {
                        mismatches += "<li>" + fName + " " + lName + " [" + id + "]</li>";
                        throw new NullPointerException("No corresponding person found in the CMS.");
                    }
                    
                } catch (Exception e) { 
                    // Error on a mandatory field OR no corresponding folder => cannot output this
                    continue; 
                }
                // Optional fields
                try { title = o.getString("title"); emp.setTitle(title); } catch (Exception e) {}
                try { jobTitle = o.getJSONObject("jobtitle").getString(loc); emp.setJobTitle(jobTitle); } catch (Exception e) {}
                emps.add(emp);
            }
            
            if (!emps.isEmpty()) {
                Collections.sort(emps, COMP_SORT_CHAR);
                Iterator<Employee> iEmps = emps.iterator();
                while (iEmps.hasNext()) {
                    Employee emp = iEmps.next();
                    try {
                        String thisNameLetter = emp.getSortChar();
                        if (!thisNameLetter.isEmpty()) {
                            if (!thisNameLetter.equalsIgnoreCase(indexLetter)) {
                                indexLetter = thisNameLetter;
                                out.println("<tr class=\"index-letter\" style=\"font-size:1.2em; font-weight:bold;\"><td colspan=\"2\">" + indexLetter + "</td></tr>");
                            }
                        }
                    } catch (Exception e) {
                        out.println("<tr class=\"index-letter\" style=\"font-size:1.2em; font-weight:bold;\"><td colspan=\"2\">" + e.getMessage() + "</td></tr>");
                    }
                    %>
                    <tr>
                        <td style="width:50%;">
                            <a href="./<%= emp.getId() %>/">
                                <%= emp.getLastName() + ", " + emp.getFirstName() %>
                            </a>
                        </td>
                        <td>
                            <%= (emp.getJobTitle() != null ? emp.getJobTitle() : "") %>
                        </td>
                    </tr>
            <%      
                    resultsPrinted++;
                }
            }  
            %>
            <!--</ul>-->
            </tbody>
        </table>
        <script type="text/javascript">
            document.getElementById("totalResultsCount").innerHTML = "<%= resultsPrinted %>";
        </script>

        <% if (pagesTotal > 1) { %>
        <nav class="pagination clearfix">
            <div class="pagePrevWrap">
                <% 
                if (prev != null) {
                    if (pageNumber > 1) { // At least one previous page exists
                    %>
                        <!--<a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(prev)) %>"><</a>-->
                    <a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + getDynamicParams(cms, false, WILDCARD_SEARCH) + "&amp;start=" + (startIndex-itemsPerPage)) %>"><</a>
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
                            <a href="<%= cms.link(requestFileUri + "?" + getDynamicParams(cms, false, WILDCARD_SEARCH) + "&amp;start=" + ((pageCounter-1) * itemsPerPage)) %>"><%= pageCounter %></a>
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
                        <a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + getDynamicParams(cms, false, WILDCARD_SEARCH) + "&amp;start=" + (startIndex+itemsPerPage)) %>">></a>
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

%>
<!--<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jqueryui/1.9.1/jquery-ui.min.js"></script>-->
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/typeahead.min.js") %>"></script>-->
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/hogan.min.js") %>"></script>-->
<script type="text/javascript">
    
    
    $(function() {
        /*document.write('<div class="searchbox-big">');
        document.write('<h2>S&oslash;k p&aring; navn</h2>');
        document.write('<form id="employeelookup" method="post" action="/no/ansatte/index.html">');
        //document.write('S&oslash;k p&aring; navn: ');
        document.write('<input type="text" name="employeename" size="30" id="employeename" value="" /> ');
        document.write('<input type="hidden" name="employeeuri" id="employeeuri" value="" />');
        document.write('<input type="submit" value=" S&oslash;k " />');
        document.write('</form>');
        //document.write('<p></p>');
        document.write('</div>');*/
            
            
        // API-provided suggestions (AJAX)
        $("#q").autocomplete({
            minLength: 0
            //,source: employees
            , source: function(request, response) {
                $.ajax({
                    url: "http://www.npolar.no/ws-employees",
                    dataType: "jsonp",
                    data: {
                        q: request.term,
                        lang: '<%= loc %>'
                    },
                    success: function( data ) {
                        response( data );
                    }
                });
            }
            /* REMOVED
            ,source: function( request, response ) {
                var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" );
                response( $.grep( employees, function( value ) {
                    value = value.label || value.value || value.description || value;
                    return matcher.test(value) || matcher.test(normalize(value) );
                }) );
            }*/
            ,focus: function(event, ui) {
                //$("#q").val(ui.item.label);
                return false;
            }
            ,select: function(event, ui) {
                $("#q").val(ui.item.label);
                $("#employeeuri").val(ui.item.value);
                $("#employeelookup").submit();
                return false;
            }
        });/*.data("autocomplete")._renderItem = function( ul, item ) {
                return $( "<li></li>" )
                        .data( "item.autocomplete", item )
                        .append( "<a>" + item.label + "<br /><em>" + item.descr + "</em></a>" )
                        .appendTo( ul );
            };*/
        if ( $("#q").data() ) {
            var ac = $("#q").data('autocomplete');
            if (ac) {
               ac._renderItem = function(ul, item) {
                    return $( "<li></li>" )
                        .data( "item.autocomplete", item )
                        .append( "<a>" + item.label + "<br /><em>" + item.description + "</em></a>" )
                        .appendTo( ul );
                };
            }
        }
        
        
        
        
        
        
        
        
        
        
        
        
        // Client side suggestions
        /*
        var employees = <% cms.includeAny("/no/employees-ac.json"); %>;
        // Mappings for special characters
        var accentMap = {
                "á": "a",
                "â": "a",
                "å": "a",
                "ç": "c",
                "é": "e",
                "è": "e",
                "ö": "o",
                "ø": "o",
                "ü": "u",
                "æ": "a",
                "-": " "
        };
        // Used to find stuff using the mappings for special characters
        var normalize = function( term ) {
            var ret = "";
            for ( var i = 0; i < term.length; i++ ) {
                ret += accentMap[ term.charAt(i) ] || term.charAt(i);
            }
            return ret;
        };

        $("#q").autocomplete({
            minLength: 0
            ,source: function( request, response ) {
                var matcher = new RegExp( $.ui.autocomplete.escapeRegex( request.term ), "i" );
                response( $.grep( employees, function( value ) {
                    value = value.label || value.value || value.description || value;
                    return matcher.test( value ) || matcher.test( normalize( value ) );
                }) );
            }
            ,focus: function(event, ui) {
                $("#q").val(ui.item.label);
                return false;
            }
            ,select: function(event, ui) {
                $("#q").val(ui.item.label);
                $("#employeeuri").val(ui.item.value);
                $("#employeelookup").submit();
                return false;
            }
        });
        
        if ( $("#q").data() ) {
            var ac = $("#q").data('autocomplete');
            if ( ac ) {
               ac._renderItem = function(ul, item) {
                    return $( "<li></li>" )
                        .data( "item.autocomplete", item )
                        .append( "<a>" + item.label + "<br /><em>" + item.description + "</em></a>" )
                        .appendTo( ul );
                };
            }
        }
        
        //$("#q").focus();
        //*/
    });
                        
    //*/
    /*$( "#employee-query" ).autocomplete({
        source: "/no/employees.json",
        minLength: 2,
        select: function( event, ui ) {
            log( ui.item ?
                "Selected: " + ui.item.label + " aka " + ui.item.description :
                "Nothing selected, input was " + this.value );
        }
    });
    //*/
                        
    /*
    $('#employee-query').typeahead({
        name: 'lol',
        prefetch: '/no/employees.json',
        template: [
            '<p class="suggest-name">{{name}}</p>',
            '<p class="suggest-jobtitle">{{jobtitle}}</p>'
        ].join(''),
        engine: Hogan
    });
    //*/
</script>
<script type="text/javascript">
<%


if (getActiveFacets(cms).isEmpty()) {
%>
    $("#filters").hide();
<%
}
if (!ONLINE && !mismatches.isEmpty()) {
    %>
        document.getElementById("admin-msg").innerHTML = "<h3 style=\"color:red; border-bottom:1px solid red;\">WARNING: Service / CMS mismatch encountered</h3>" 
                                                            + "<p>At least 1 person exists only in the database, not in the CMS.</p>"
                                                            + "<p>Modify/delete these entries in the database or create corresponding folders/files in the CMS.</p>"
                                                            + "<ul><%= mismatches %></ul>";
    <%
}
%>
</script>
<%

// Call master template (and output the closing part - hence the [1])
//cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], EDITABLE_TEMPLATE);

// Clear all static vars
dp.clear();
sw.clear();
activeFacets.clear();
mappings.clear();
%>
