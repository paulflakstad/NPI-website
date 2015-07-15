<%-- 
    Document   : ws-employees (loosely based on employees-json)
    Descr      : A web service to serve employee details as json objects, 
                    designed to work with the jquery.jqueryui.autocomplete widget.
                    Employee details are fetched using an existing API.
    Created on : Sep 3, 2014, 11:26:52 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="java.util.Set,
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
            org.opencms.flex.CmsFlexController,
            org.opencms.file.CmsObject"
            contentType="text/html" 
            pageEncoding="UTF-8" 
            session="true" 
 %><%!
/** Map storage for default parameters. */
static Map<String, String> dp = new HashMap<String, String>();

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
 * Gets the default API parameters as a string. 
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

public static String getParams(String query) {
    String s = "q=";
    
    if (query != null && !query.isEmpty()) {
        if (!query.startsWith("*"))
            query = "*" + query;
        try { s += URLEncoder.encode(query, "utf-8"); } catch (Exception e) {}
    }
    
    String defaultParams = getDefaultParams();
    if (!defaultParams.isEmpty())
        s += "&" + defaultParams;
    
    return s;
}
/**
 * Pre-defined API parameters. 
 * The end-user should never see these.
 */
public static Map<String, String> getPreDefParamMap() {
    if (dp.isEmpty()) {
        dp.put("sort", "last_name");
        dp.put("format", "json");
        dp.put("filter-currently_employed", "T");
        dp.put("limit", "999");
    }
    return dp;
}

/*##############################################################################
################################################################################
##############################################################################*/
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();

// The allowed languages
List<String> allowedLang = Arrays.asList(new String[] { "no", "en" });
// The default language
Locale locale = new Locale("no");

// Determine the desired language (fallback to default if that fails)
String language = request.getParameter("lang");
if (language != null && allowedLang.contains(language)) {
    try { locale = new Locale(language); } catch (Exception e) {}
}
String loc = locale.toString();

// Determine the MIME sub-type by checking if a "callback" parameter exists
String mimeSubType = "json";
String callback = request.getParameter("callback");
if (callback != null && !callback.isEmpty()) {
    mimeSubType = "javascript";
}

// Determine the query
String query = request.getParameter("q");


// Muy importante!!! (One of "application/json" OR "application/javascript")
CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/" + mimeSubType + "; charset=utf-8");



final String EMPLOYEES_FOLDER = loc.equalsIgnoreCase("no") ? "/no/ansatte/" : "/en/people/";

// Service details
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PORT = "80";
final String SERVICE_PATH = "/person/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;

// Construct the URL to the service providing all neccessary data
String queryURL = SERVICE_BASE_URL + "?" + getParams(query);

//out.println("API URL <a href=\"" + queryURL + "\">" + queryURL + "</a>");

if (callback != null && !callback.isEmpty()) {
    out.print(callback + "(");
}
out.print("[");
if (query != null && !query.isEmpty()) {

    JSONObject json = null;
    try {
        // Read the JSON string
        String jsonStr = getResponseContent(queryURL);

        try {
            // Create the JSON object from the JSON string
            json = new JSONObject(jsonStr).getJSONObject("feed");
        } catch (Exception jsone) {
            out.println(queryURL);
            %>
            <pre>
            <% jsone.printStackTrace(response.getWriter()); %>
            </pre>    
            <%
            return;
        }

        // Project data variables
        String id = null;
        String title = null;
        String fName = null;
        String lName = null;
        String jobTitle = null;
        String personFolder = null;
        int totalResults = json.getJSONObject("opensearch").getInt("totalResults");

        if (totalResults > 0) {
            //out.print("{");
            //out.print("\"totalResults\":" + totalResults + ",");
            //out.print("\"employees\":[");
            String entries = "";
            JSONArray entriesArr = json.getJSONArray("entries");
            int resultsPrinted = 0;
            for (int pCount = 0; pCount < entriesArr.length(); pCount++) {
                JSONObject o = entriesArr.getJSONObject(pCount);

                // Mandatory fields
                try { 
                    id = o.getString("id");
                    fName = o.getString("first_name");
                    lName = o.getString("last_name"); 
                    personFolder = EMPLOYEES_FOLDER + id + "/";
                    if (!cms.getCmsObject().existsResource(personFolder)) {
                        throw new NullPointerException("No corresponding person found in the CMS.");
                    }
                } catch (Exception e) { 
                    // Error on a mandatory field OR no corresponding folder => cannot output this
                    continue; 
                }
                // Optional fields
                try { title = o.getString("title"); } catch (Exception e) {}
                try { jobTitle = o.getJSONObject("jobtitle").getString(loc); } catch (Exception e) {}


                entries += "{";
                entries += "\"value\": \"" +  personFolder + "\",";
                entries += "\"label\": \"" + fName + " " + lName + "\",";
                entries += "\"description\": \"" + (jobTitle != null ? jobTitle : "") + "\"";
                entries += "},";

                resultsPrinted++;
            }
            entries = entries.substring(0, entries.length()-1);
            out.print(entries);        
        }
        
    } catch (Exception e) {
        out.println(queryURL);
        e.printStackTrace(response.getWriter());
    }
}
out.print("]");
if (callback != null && !callback.isEmpty()) {
    out.print(")");
}
// Clear all static vars
dp.clear();
%>
