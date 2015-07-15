<%-- 
    Document   : publications-ice, based on publications-annual-report
    Created on : Jan 15, 2014, 9:51:15 AM
    Author     : flakstad
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
                 java.util.LinkedHashMap,
                 java.util.Set,
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

public static Map<String, String> translations = new HashMap<String, String>();

/**
 * Requests the given URL and return the respose as a String.
 */
public String httpResponseAsString(String url) throws MalformedURLException, IOException, JspException {
    HttpURLConnection conn = (HttpURLConnection)new URL(url).openConnection();
    conn.connect();
    int responseCode = conn.getResponseCode();
    if (responseCode != HttpURLConnection.HTTP_OK) {
        throw new JspException("The service at " + url + " responded with status code " + responseCode + ". Unable to continue.");
    }
    
    // Response code was 200 OK
    InputStream inStream = conn.getInputStream();
    BufferedReader reader = new BufferedReader(new InputStreamReader(inStream));
    StringBuffer contentBuffer = new StringBuffer();
    String inputLine;
    while ((inputLine = reader.readLine()) != null) {
        contentBuffer.append(inputLine);
    }
    reader.close();

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
    private String authors = "";
    private String year = "";
    private String journal = "";
    private String volume = "";
    private String pages = "";
    private String doi = "";
    private String id = "";
    private String link = "";
    private String type = "";
    private List<String> programmes = null;
    private List<String> conferences = null;
    
    public SimplePublication(String title, String year, String doi, String id, String type) {
        this.title = title;
        this.year = year;
        this.doi = doi;
        this.id = id;
        this.type = type;
        this.programmes = new ArrayList<String>();
        this.conferences = new ArrayList<String>();
    }
    
    public SimplePublication(
            String title
            , String authors
            , String year
            , String journal
            , String volume
            , String pages
            , String doi
            , String id
            , String type
            , String link
            , List<String> programmes
            , List<String> conferences
            ) {
        this.title = title.trim();
        this.authors = authors.trim();
        this.year = year.trim();
        this.journal = journal.trim();
        this.volume = volume.trim();
        this.pages = pages.trim();
        this.doi = doi.trim();
        this.id = id.trim();
        this.type = type.trim();
        this.link = link.trim();
        if (programmes != null && !programmes.isEmpty()) {
            this.programmes = new ArrayList<String>();
            this.programmes.addAll(programmes);
        }
        if (conferences != null && !conferences.isEmpty()) {
            this.conferences = new ArrayList<String>();
            this.conferences.addAll(conferences);
        }
    }
    
    public String getTitle() { return this.title; }
    public String getAuthors() { return this.authors; }
    public String getYear() { return this.year; }
    public String getJournal() { return this.journal; }
    public String getVolume() { return this.volume; }
    public String getPages() { return this.pages; }
    public String getDoi() { return this.doi; }
    public String getId() { return this.id; }
    public String getType() { return this.type; }
    public String getLink() { return this.link; }
    public String toString() {
        String s = (authors.isEmpty() ? "" : authors + ". ");
        s += (year.isEmpty() ? "" : " " + year + ". ");
        s += "<a href=\"http://data.npolar.no/publication/" + id + "\"><em>" + title + "</em></a>. ";
        s += (journal.isEmpty() ? "" : journal + (volume.isEmpty() ? ". " : "") + "&nbsp;");
        s += (volume.isEmpty() ? "" : "" + volume + "" + (pages.isEmpty() ? "." : ""));
        if (!volume.isEmpty())
            s += (pages.isEmpty() ? "" : ":&nbsp;" + pages + ".");
        else
            s += (pages.isEmpty() ? "" : "p.p.&nbsp;" + pages + ".");
        s += (doi.isEmpty() ? "" : "<br />DOI:<a href=\"http://dx.doi.org/" + doi + "\">" + doi + "</a>");
        return s;
    }
    public boolean isAffiliatedToProgramme(String programmeIdentifier) {
        if (this.programmes == null || this.programmes.isEmpty())
            return false;
        return this.programmes.contains(programmeIdentifier);
    }
    public boolean isAffiliatedToConference(String conferenceIdentifier) {
        if (this.conferences == null || this.conferences.isEmpty())
            return false;
        return this.conferences.contains(conferenceIdentifier);
    }
}

public class PublicationCollection {
    private LinkedHashMap<String, ArrayList<SimplePublication>> pubs = null;
    public static final String PEER_REVIEWED = "peer-reviewed";
    public static final String EDITORIAL = "editorial";
    public static final String REVIEW = "review";
    public static final String CORRECTION = "correction";
    public static final String BOOK = "book";
    public static final String POSTER = "poster";
    public static final String REPORT = "report";
    public static final String ABSTRACT = "abstract";
    public static final String PHD = "phd";
    public static final String MASTER = "master";
    public static final String PROCEEDINGS = "proceedings";
    public static final String POPULAR = "popular";
    public static final String OTHER = "other";
    
    String[] order = { 
        PEER_REVIEWED, 
        BOOK, 
        EDITORIAL, 
        REPORT, 
        REVIEW,
        PROCEEDINGS,
        ABSTRACT,
        CORRECTION,
        PHD,
        MASTER,
        POSTER,
        POPULAR,
        OTHER 
    };
    
    public PublicationCollection() {
        pubs = new LinkedHashMap<String, ArrayList<SimplePublication>>();
        for (int i = 0; i < order.length; i++) {
            pubs.put(order[i], new ArrayList<SimplePublication>());
        }
    }
    
    public ArrayList<SimplePublication> getListByType(String pubType) {
        return this.pubs.get(pubType);
    }
    
    public void add(SimplePublication sp) {
        if (pubs.get(sp.getType()) == null) // Should never happen, but anyway ...
            pubs.put(sp.getType(), new ArrayList<SimplePublication>());
        
        pubs.get(sp.getType()).add(sp);
    }
    
    public boolean isEmpty() {
        return this.size() <= 0;
    }
    
    public int size() {
        if (pubs == null)
            return 0;
        
        int size = 0;
        Iterator iKeys = pubs.keySet().iterator();
        while (iKeys.hasNext()) {
            size += pubs.get(iKeys.next()).size();
        }
        return size;
    }
    
    public Set<String> getTypesContained() {
        return pubs.keySet();
    }
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
        } catch (Exception e) {
            continue;
        }
    }
    
    if (authorStr.endsWith(", "))
        authorStr = authorStr.substring(0, authorStr.length() - 2);
    
    return authorStr;
}

public String getJournal(JSONObject o) throws JSONException {
    String s = "";
    JSONObject journal = null;
    try {
        s = o.getJSONObject("journal").getString("name");
        return s;
    } catch (Exception e) {
        // No "journal" available, return empty string
        return s;
    }
}


public String getVolume(JSONObject o) throws JSONException {
    String s = "";
    try {
        s = o.getString("volume");
        return s;
    } catch (Exception e) {
        // No "journal" available, return empty string
        return s;
    }
}


public String getPages(JSONObject o) throws JSONException {
    String s = "";
    JSONArray pages = null;
    try {
        pages = o.getJSONArray("pages");
        if (pages.length() == 2) 
            s += pages.getString(0) + "&ndash;" + pages.getString(1);
        return s;
    } catch (Exception e) {
        // No "journal" available, return empty string
        return s;
    }
}

public String translate(String s) {
    String translation = translations.get(s);
    return translation != null ? translation : s;
}
%><%
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();

final boolean COMMENTS  = true;

translations.put("N-ICE", "N-ICE");
translations.put("ICE Fluxes", loc.equalsIgnoreCase("no") ? "ICE-havis" : "ICE Fluxes");
translations.put("ICE Antarctica", loc.equalsIgnoreCase("no") ? "ICE-Antarktis" : "ICE Antarctica");
translations.put("ICE Ecosystems", loc.equalsIgnoreCase("no") ? "ICE-økosystemer" : "ICE Ecosystems");
//translations.put("", loc.equalsIgnoreCase("no") ? "" : "");


if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    try { cms.getRequestContext().setLocale(new Locale(loc)); } catch (Exception e) {}
}


String year = cms.getRequest().getParameter("year");
if (year == null) {
    //year = "2014";
    //out.println("<!-- Nothing to work with here... -->");
    //return;
}

final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
final int LIMIT = 9999;

/*
String pid = cms.getRequest().getParameter("pid");
if (pid == null || pid.isEmpty()) {
    // crash
    out.println(error("A project ID is required in order to view a project's details."));
    return; // IMPORTANT!
}
*/

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


String[] iceProgs = new String[] { 
                                        "N-ICE"
                                        , "ICE Antarctica"
                                        , "ICE Fluxes"
                                        , "ICE Ecosystems" 
                                    };
for (int j = 0; j < iceProgs.length; j++) {
    // The parameters used to specify a particular results list
    Map<String, String[]> params = new HashMap<String, String[]>();
    params.put("q", new String[]{ "" });
    //params.put("filter-people.first_name", new String[]{ fname });
    //params.put("filter-people.last_name", new String[]{ lname });
    if (year != null)
        params.put("filter-published-year", new String[] { year });
    //params.put("sort", new String[]{ "-publication_year" });
    params.put("sort", new String[]{ "-published-year" });
    // Add parameter for the current ICE programme
    params.put("filter-programme", new String[] { URLEncoder.encode(iceProgs[j], "utf-8") });

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
        if (COMMENTS) out.println("\n\n<!-- Service @ " + serviceUrl + " -->");
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


    //List<SimplePublication> publications = new ArrayList<SimplePublication>();

    PublicationCollection publications = new PublicationCollection();
    int totalResults = -1;

    try {
        JSONObject json = new JSONObject(jsonFeed).getJSONObject("feed");

        // Stats
        try { totalResults = json.getJSONObject("opensearch").getInt("totalResults"); } catch (Exception e) { }
        
        if (COMMENTS) out.println("<!-- " + totalResults + " publication(s) in service response -->");


        JSONArray pubs = json.getJSONArray("entries");

        // JSON keys
        final String JSON_KEY_TITLE         = "title";
        final String JSON_KEY_LINKS         = "links";
        final String JSON_KEY_LINK_REL      = "rel";
        final String JSON_KEY_LINK_HREF     = "href";
        final String JSON_KEY_LINK_HREFLANG = "hreflang";
        final String JSON_KEY_LINK_TYPE     = "type";
        final String JSON_KEY_PUBYEAR       = "published-year";
        final String JSON_KEY_ID            = "id";
        final String JSON_KEY_TYPE          = "publication_type";
        final String JSON_KEY_COMMENT       = "comment";

        final String JSON_VAL_LINK_RELATED  = "related";
        final String JSON_VAL_LINK_DOI      = "doi";

        for (int pubCount = 0; pubCount < pubs.length(); pubCount++) {
            JSONObject pub = pubs.getJSONObject(pubCount);

            String title = "";
            String doi = "";
            String pubyear = "";
            String id = "";
            String type = "";
            String pubLink = "";
            String authors = getAuthors(pub);
            String journal = getJournal(pub);
            String volume = getVolume(pub);
            String pages = getPages(pub);
            JSONArray links = null;

            try { title = pub.getString(JSON_KEY_TITLE); } catch (Exception e) { title = "Unknown title"; }
            try { links = pub.getJSONArray(JSON_KEY_LINKS); } catch (Exception e) { }
            try { pubyear = pub.getString(JSON_KEY_PUBYEAR); } catch (Exception e) { }
            try { id = pub.getString(JSON_KEY_ID); pubLink = HUMAN_BASE_URL_DETAIL + id; } catch (Exception e) { }
            try { type = pub.getString(JSON_KEY_TYPE); } catch (Exception e) { }
            try {
                links = pub.getJSONArray(JSON_KEY_LINKS);
                for (int i = 0; i < links.length(); i++) {
                    JSONObject link = links.getJSONObject(i);
                    try {
                        if (link.getString(JSON_KEY_LINK_REL).equalsIgnoreCase(JSON_VAL_LINK_DOI)) {
                            doi = link.getString(JSON_KEY_LINK_HREF).replace("http://dx.doi.org/", "");
                            break;
                        }
                    } catch (Exception doie) {}
                }
            } catch (Exception e) {}

            publications.add(new SimplePublication(title, authors, pubyear, journal, volume, pages, doi, id, type, pubLink, null, null));
            if (COMMENTS) out.println("<!-- Added publication: " + title + " -->");
            //out.println("<!-- publications.size() = " + publications.size() + " -->");
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
    if (COMMENTS) out.println("<!-- Ready to output HTML, " + publications.size() + " publication(s) in this set. -->");
    if (!publications.isEmpty()) {
        out.println("<h2>" + cms.labelUnicode("label.np.publist.heading") + " for " + translate(iceProgs[j]) + "</h2>");

        // Get types of publications
        Iterator<String> iTypes = publications.getTypesContained().iterator();
        while (iTypes.hasNext()) {
            String listType = iTypes.next();
            Iterator<SimplePublication> iPubs = publications.getListByType(listType).iterator();
            if (iPubs.hasNext()) {
                out.println("<h3>" + cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListByType(listType).size() + ")</h3>");
                out.println("<ul class=\"fullwidth line-items\">");
                while (iPubs.hasNext()) {
                    out.println("<li>" + iPubs.next().toString() + "</li>");
                }
                out.println("</ul>");
            }
            /*if (totalResults > LIMIT) {
                int more = totalResults - LIMIT;
                String moreLinkText = "&hellip; " + (loc.equalsIgnoreCase("no") ? "og " + more + " til" : "and " + more + " more");
                out.println("<a class=\"cta-more\" href=\"" + humanUrl + "\">" + moreLinkText + "</a>");
            }*/
        }
    }
    else {
        out.println("<!-- No publications to output. -->");
    }
}
//*/
%>