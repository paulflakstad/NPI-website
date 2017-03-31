<%-- 
    Document   : person-publications
    Description: Outputs a person's publications. 
                    NOT IN USE as of 2017-03-31.
    Created on : Oct 9, 2013, 5:11:32 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="java.util.SortedMap,
                 java.util.Arrays,
                 java.util.Collections,
                 java.util.SortedSet,
                 java.util.TreeSet,
                 no.npolar.util.CmsAgent,
                 no.npolar.util.CmsImageProcessor,
                 java.net.*,
                 java.nio.charset.Charset,
                 java.io.*,
                 java.util.Collections,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Date,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsFile,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.collectors.I_CmsResourceCollector,
                 org.opencms.file.types.CmsResourceTypeImage, 
                 org.opencms.file.CmsUser,
                 org.opencms.file.CmsProperty,
                 org.opencms.staticexport.CmsLinkManager,
                 org.opencms.json.*,
                 org.opencms.jsp.I_CmsXmlContentContainer, 
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.staticexport.CmsStaticExportManager,
                 org.opencms.security.CmsRole,
                 org.opencms.relations.CmsCategory,
                 org.opencms.util.CmsHtmlExtractor,
                 org.opencms.util.CmsRequestUtil,
                 org.opencms.util.CmsUriSplitter,
                 org.opencms.xml.content.CmsXmlContent,
                 org.opencms.xml.content.CmsXmlContentFactory,
                 org.opencms.xml.types.I_CmsXmlContentValue" session="true"
%><%!

/**
 * Requests the given URL and return the respose as a String.
 */
public String httpResponseAsString(String url) throws MalformedURLException, IOException {
    BufferedReader in = new BufferedReader(new InputStreamReader(new URL(url).openConnection().getInputStream()));
    StringBuffer contentBuffer = new StringBuffer();
    String inputLine;
    while ((inputLine = in.readLine()) != null) {
        contentBuffer.append(inputLine);
    }
    in.close();
    
    return contentBuffer.toString();
}

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

public String getParameterString(Map<String, String[]> params) throws java.io.UnsupportedEncodingException {
   if (params.isEmpty())
       return "";
   String s = "";
   Iterator<String> i = params.keySet().iterator();
   while (i.hasNext()) {
       String key = i.next();
       String[] values = params.get(key);
       for (int j = 0; j < values.length;) {
           s += key + "=" + values[j];
           if (++j == values.length)
               break;
           else
               s += "&";
       }
       if (i.hasNext())
           s += "&";
   }
   //return URLEncoder.encode(s, "utf-8");
   return s;
}

public class SimplePublication {
    private String title = "";
    private String year = "";
    private String doi = "";
    private String id = "";
    private String link = "";
    
    public SimplePublication(String title, String year, String doi, String id) {
        this.title = title;
        this.year = year;
        this.doi = doi;
        this.id = id;
    }
    
    public SimplePublication(String title, String year, String doi, String id, String link) {
        this.title = title;
        this.year = year;
        this.doi = doi;
        this.id = id;
        this.link = link;
    }
    
    public String getTitle() { return this.title; }
    public String getYear() { return this.year; }
    public String getDoi() { return this.doi; }
    public String getId() { return this.id; }
    public String getLink() { return this.link; }
    public String toString() {
        String s = this.title + (!this.year.isEmpty() ? " ("+this.year+")" : "");
        if (!this.link.isEmpty())
            s = "<a href=\"" + link + "\">" + s + "</a>";
        else if (!this.doi.isEmpty())
            s = "<a href=\"" + doi + "\">" + s + "</a>";
        return s;
    }
}
%><%
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();
if (request.getParameter("locale") != null) 
    loc = request.getParameter("locale");

if (cms.getRequest().getParameter("email") == null) {
    out.println("<!-- Nothing to work with here... -->");
    return;
}

final boolean EDITABLE = false;
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
final int LIMIT = 5;

/*
String pid = cms.getRequest().getParameter("pid");
if (pid == null || pid.isEmpty()) {
    // crash
    out.println(error("A project ID is required in order to view a project's details."));
    return; // IMPORTANT!
}
*/

// Dummy vars
//String fname = URLEncoder.encode("Kit M.", "utf-8");
//String lname = URLEncoder.encode("Kovacs", "utf-8");
// Real vars:
//String fname = URLEncoder.encode(request.getParameter("fname"), "utf-8");
//String lname = URLEncoder.encode(request.getParameter("lname"), "utf-8");
String email = URLEncoder.encode(request.getParameter("email"), "utf-8");
// These do not always work:
//String fname = URLDecoder.decode(request.getParameter("fname"), "utf-8");
//String lname = URLDecoder.decode(request.getParameter("lname"), "utf-8");
//String fname = request.getParameter("fname");
//String lname = request.getParameter("lname");

// Service details
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PORT = "80";
final String SERVICE_PATH = "/publication/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;
/*
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "apptest.data.npolar.no";
final String SERVICE_PORT = "9000";
final String SERVICE_PATH = "/publication/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;
*/

final String HUMAN_PROTOCOL = "https";
final String HUMAN_DOMAIN_NAME = "data.npolar.no";
final String HUMAN_PORT = "443";
final String HUMAN_PATH_LIST = "/publications/";
final String HUMAN_PATH_DETAIL = "/publication/";
final String HUMAN_BASE_URL_LIST = HUMAN_PROTOCOL + "://" + HUMAN_DOMAIN_NAME + ":" + HUMAN_PORT + HUMAN_PATH_LIST;
final String HUMAN_BASE_URL_DETAIL = HUMAN_PROTOCOL + "://" + HUMAN_DOMAIN_NAME + ":" + HUMAN_PORT + HUMAN_PATH_DETAIL;
/*
final String HUMAN_PROTOCOL = "http";
final String HUMAN_DOMAIN_NAME = "apptest.data.npolar.no";
final String HUMAN_PORT = "9666";
final String HUMAN_PATH_LIST = "/publications/";
final String HUMAN_PATH_DETAIL = "/publication/";
final String HUMAN_BASE_URL_LIST = HUMAN_PROTOCOL + "://" + HUMAN_DOMAIN_NAME + ":" + HUMAN_PORT + HUMAN_PATH_LIST;
final String HUMAN_BASE_URL_DETAIL = HUMAN_PROTOCOL + "://" + HUMAN_DOMAIN_NAME + ":" + HUMAN_PORT + HUMAN_PATH_DETAIL;
*/
// The parameters used to specify a particular results list
Map<String, String[]> params = new HashMap<String, String[]>();
params.put("q", new String[]{ "" });
//params.put("filter-people.first_name", new String[]{ fname });
//params.put("filter-people.last_name", new String[]{ lname });
params.put("filter-people.email", new String[] { email });
//params.put("sort", new String[]{ "-publication_year" });
params.put("sort", new String[]{ "-published-year" });

// Construct the "human" URL for looking up this particular entry set
String humanUrl = HUMAN_BASE_URL_LIST + "?" + getParameterString(params);

// Add more parameters, used only for machine-readable extraction
params.put("format", new String[]{ "json" });
params.put("limit", new String[]{ Integer.toString(LIMIT) });

// Construct the service URL for looking up this particular entry set
String serviceUrl = null;
try {
    serviceUrl = SERVICE_BASE_URL + "?" + getParameterString(params);
} catch (Exception e) {
    //out.println("Crash!");
    return;
}


//
// Access the service
//
String jsonFeed = null;
try {
    jsonFeed = httpResponseAsString(serviceUrl);
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

    
List<SimplePublication> publications = new ArrayList<SimplePublication>();
int totalResults = -1;

try {
    JSONObject json = new JSONObject(jsonFeed).getJSONObject("feed");
    
    // Stats
    try { totalResults = json.getJSONObject("opensearch").getInt("totalResults"); } catch (Exception e) { }
    
    
    JSONArray pubs = json.getJSONArray("entries");

    // JSON keys
    final String JSON_KEY_TITLE         = "title";
    final String JSON_KEY_LINKS         = "links";
    final String JSON_KEY_LINK_REL      = "rel";
    final String JSON_KEY_LINK_HREF     = "href";
    final String JSON_KEY_LINK_HREFLANG = "hreflang";
    final String JSON_KEY_LINK_TYPE     = "type";
    final String JSON_KEY_PUBYEAR       = "publication_year";
    final String JSON_KEY_ID            = "id";
    final String JSON_KEY_COMMENT       = "comment";

    final String JSON_VAL_LINK_RELATED  = "related";
    final String JSON_VAL_LINK_DOI      = "doi";
    
    for (int pubCount = 0; pubCount < pubs.length(); pubCount++) {
        JSONObject pub = pubs.getJSONObject(pubCount);
        
        String title = "";
        String doi = "";
        String pubyear = "";
        String id = "";
        String pubLink = "";
        JSONArray links = null;
        
        try { title = pub.getString(JSON_KEY_TITLE); } catch (Exception e) { title = "Unknown title"; }
        try { links = pub.getJSONArray(JSON_KEY_LINKS); } catch (Exception e) { }
        try { pubyear = pub.getString(JSON_KEY_PUBYEAR); } catch (Exception e) { }
        try { id = pub.getString(JSON_KEY_ID); pubLink = HUMAN_BASE_URL_DETAIL + id; } catch (Exception e) { }
        try {
            links = pub.getJSONArray(JSON_KEY_LINKS);
            for (int i = 0; i < links.length(); i++) {
                JSONObject link = links.getJSONObject(i);
                try {
                    if (link.getString(JSON_KEY_LINK_REL).equals(JSON_VAL_LINK_DOI)) {
                        doi = link.getString(JSON_KEY_LINK_HREF);
                        break;
                    }
                } catch (Exception doie) {}
            }
        } catch (Exception e) {}
        
        publications.add(new SimplePublication(title, pubyear, doi, id, pubLink));
    }
} catch (Exception e) {
    out.println("An unexpected error occured while constructing the publication details.");
    out.println("<br />Service URL: <a href=\"" + serviceUrl + "\">" + serviceUrl + "</a>");
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
}
    





// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------
if (!publications.isEmpty()) {
    out.println("<h4>" + (loc.equalsIgnoreCase("no") ? "Publikasjoner" : "Publications") + "</h4>");
    out.println("<ul class=\"person-publications\">");
    Iterator<SimplePublication> iPub = publications.iterator();
    while (iPub.hasNext()) {
        out.println("<li>" + iPub.next().toString() + "</li>");
    }
    out.println("</ul>");
    if (totalResults > LIMIT) {
        int more = totalResults - LIMIT;
        String moreLinkText = "&hellip; " + (loc.equalsIgnoreCase("no") ? "og " + more + " til" : "and " + more + " more");
        out.println("<a class=\"cta-more\" href=\"" + humanUrl + "\">" + moreLinkText + "</a>");
    }
}
else {
    out.println("<!-- No publications found on " + serviceUrl + " -->");
}
//*/
%>