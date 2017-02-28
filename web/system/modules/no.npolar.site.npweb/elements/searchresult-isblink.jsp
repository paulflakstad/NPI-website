<%-- 
    Document   : searchresult-isblink
    ToDo       : (This is an IDEA) Create a master SERP class holding "hit" 
                    objects (all hits, mixed from all sources), and arrange the 
                    hits (mixed) using their SCORE. This should be quite easy.
                    Also, one should offer the option to filter by source 
                    (Isblink, personalhåndbok, HMS-håndbok etc.)
    Created on : Sep 3, 2014, 5:21:04 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page import="java.io.*"%>
<%@page import="java.net.*"%>
<%@page import="java.util.*"%>
<%@page import="java.util.regex.Matcher"%>
<%@page import="java.util.regex.Pattern"%>
<%@page import="org.opencms.file.*"%>
<%@page import="org.opencms.json.*"%>
<%@page import="org.opencms.jsp.*"%>
<%@page import="org.opencms.main.*"%>
<%@page import="org.opencms.search.*"%>
<%@page import="org.opencms.search.fields.*"%>
<%@page import="org.opencms.security.CmsRoleManager"%>
<%@page import="org.opencms.security.CmsRole"%>
<%@page import="org.opencms.util.CmsStringUtil"%>
<%@page import="org.jsoup.Jsoup"%>
<%@page import="org.jsoup.nodes.Element"%>
<%@page import="org.jsoup.safety.Whitelist"%>
<%@page import="org.jsoup.select.Elements"%>
<%@page import="org.apache.commons.httpclient.*"%>
<%@page import="org.apache.commons.httpclient.cookie.CookiePolicy"%>
<%@page import="org.apache.commons.httpclient.cookie.CookieSpec"%>
<%@page import="org.apache.commons.httpclient.methods.*"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page buffer="none" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"%>
<%@include file="compendia-personal-credentials.jsp"%>
<%!
    
/**Used for notes to the end user; error messages, size trims, etc. */
public static String note = "";

/**
 * Represents a single hit in a SERP.
 */
public static class SearchResultHit implements Comparator<SearchResultHit> {
    private String title;
    private String snippet;
    private String category;
    private String uri;
    private String displayUri;
    private String source;
    private int score;
    
    public static final int TITLE = 0;
    public static final int SNIPPET = 1;
    public static final int CATEGORY = 2;
    public static final int URI = 3;
    public static final int DISPLAY_URI = 4;
    public static final int SOURCE = 5;
    public static final int SCORE = 6;
        
    /*public static final Comparator<SearchResultHit> SCORE_COMP = new Comparator<SearchResultHit>() {
        public int compare(SearchResultHit thisResult, SearchResultHit thatResult) {
            if (thisResult.getScore() < thatResult.getScore())
                return -1;
            else if (thisResult.getScore() > thatResult.getScore())
                return 1;
            return 0;
        }
    };*/
    
    /**
     * Creates a new hit.
     */
    public SearchResultHit(String title, 
                            String snippet,
                            String category,
                            String uri,
                            String displayUri,
                            String source,
                            int score) {
        this.title = title;
        this.snippet = snippet;
        this.category = category;
        this.uri = uri;
        this.displayUri = displayUri;
        this.source = source;
        this.score = score;
    }

    /**
     * Gets a detail from this hit - usage like Calendar#get(Calendar#DATE)
     */
    public String get(int type) {
        switch (type) {
            case TITLE:
                return this.title;
            case SNIPPET:
                return this.snippet;
            case CATEGORY:
                return this.category;
            case URI:
                return this.uri;
            case DISPLAY_URI:
                return this.displayUri;
            case SOURCE:
                return this.source;
            case SCORE:
                return String.valueOf(this.score);
            default:
                return null;
        }
    }
    /** Gets the title. */
    public String getTitle() { return title; }
    /** Gets the snippet. */
    public String getSnippet() { return snippet; }
    /** Gets the category (if any). */
    public String getCategory() { return category; }
    /** Gets the URI. */
    public String getUri() { return uri; }
    /** Gets the source. */
    public String getSource() { return source; }
    /** Gets the score. */
    public int getScore() { return score; }
    
    /** Compares by score. */
    public int compare(SearchResultHit thisResult, SearchResultHit thatResult) {
        if (thisResult.getScore() < thatResult.getScore())
            return -1;
        else if (thisResult.getScore() > thatResult.getScore())
            return 1;
        return 0;
    }
}
/**
 * Represents a searchable source, e.g. "Personalhåndboka" or "Isblink".
 */
public static class SearchSource implements Comparable {
    /** The name of the source. */
    private String name = null;
    /** The number of hits in this source. */
    private int numHits = -1;
    
    /** Creates a new source with the given name, and with zero hits. */
    public SearchSource(String name) {
        this.name = name;
        numHits = 0;
    }
    /** Gets the name of the source. */
    public String getName() {
        return name;
    }
    /** Increments the number of hits for this source by 1. */
    public int addOneHit() {
        return ++numHits;
    }
    /** Gets the number of hits for this source. */
    public int getNumHits() {
        return numHits;
    }
    /** Compares this source to the given one. */
    public int compareTo(Object that) {
        if (that instanceof SearchSource) {
            return this.name.compareTo(((SearchSource)that).name);
        }
        throw new IllegalArgumentException("Only other SearchSource instances can be compared to this SearchSource.");
    }
    /** Checks if this source is equal to the given one. */
    public boolean equals(Object that) {
        if (that == null || !(that instanceof SearchSource))
            return false;
        return this.name.equals(((SearchSource)that).name);
    }
}
/**
 * Represents a SERP; a collection of search hits that together form the 
 * complete search result.
 */
public static class SearchResults {
    /** Comparator that compares hits by their score. */
    public Comparator<SearchResultHit> SCORE_COMP = new Comparator<SearchResultHit>() {
        public int compare(SearchResultHit thisResult, SearchResultHit thatResult) {
            if (thisResult.getScore() < thatResult.getScore())
                return 1;
            else if (thisResult.getScore() > thatResult.getScore())
                return -1;
            return 0;
        }
    };
    /** The search hits in this SERP. */
    private List<SearchResultHit> hits = null;
    /** The sources represented in this SERP. */
    private List<SearchSource> sources = null;
    
    /** Creates a new, blank SERP. */
    public SearchResults() {
        hits = new ArrayList<SearchResultHit>();
        sources = new ArrayList<SearchSource>();
    }
    /** Gets all sources represented in this SERP. */
    public List<SearchSource> getSources() {
        return sources;
    }
    /** Adds a hit to this SERP. */
    public boolean add(SearchResultHit hit) {
        String hitSource = hit.getSource();
        if (hitSource != null) {
            hitSource = hitSource.trim();
            if (!hitSource.isEmpty()) { 
                SearchSource source = new SearchSource(hitSource);
                if (!sources.contains(source)) {
                    sources.add(source);
                }
                sources.get(sources.indexOf(source)).addOneHit();
            }
        }
        return hits.add(hit);
    }
    /** Gets the size of this SERP (the number of hits it contains). */
    public int size() {
        return hits.size();
    }
    /** Removes a hit from this SERP. */
    public boolean remove(SearchResultHit hit) {
        return hits.remove(hit);
    }
    /** Clears all hits, and their sources, from this SERP. */
    public void clear() {
        hits.clear();
        sources.clear();
    }
    /** Gets an iterator for the hits in this SERP. */
    public Iterator<SearchResultHit> iterator() {
        return hits.iterator();
    }
    /** Gets the hits in this SERP, unsorted. */
    public List<SearchResultHit> getHits() {
        return hits;
    }
    /** Gets the hits in this SERP, sorted. */
    public List<SearchResultHit> getResults() {
        Collections.sort(hits, SCORE_COMP);
        return hits;
    }
}
/**
 * Not done ... not even sure why this is here x)
 */
public class SearchResultsXml {
    String xmlSource = null;
    
    public SearchResultsXml(String xmlSource) {
        this.xmlSource = xmlSource;
    }
}

/**
 * Injects hits from Compendia Personal (CP) into the given SERP instance.
 * <p>
 * The CP search returns hits from all the different sources on that domain -
 * "HMS-håndbok", "Compendia Stat", and "Personalhåndbok"
 * <p>
 * This method tries to mimic a human user doing a search. It is also a hack; if 
 * CP at any point changes critical HTML or URIs, this method will break pending 
 * an update which reflects any such external changes.
 */
public static void injectCompendiaPersonalSerp(String usr, 
                                                String pwd,
                                                String key,
                                                String query,
                                                SearchResults serp,
                                                String sourceSelected,
                                                JspWriter out) throws Exception {
    //
    // See 
    // http://svn.apache.org/viewvc/httpcomponents/oac.hc3x/trunk/src/examples/FormLoginDemo.java?revision=604567&view=markup
    //

    // Churn out some extra comments along the way?
    final boolean DEBUG = false;

    // How to access Compendia Personal (CP)
    final String CP_PROTOCOL = "https";
    final String CP_DOMAIN = "cp.compendia.no";
    final int CP_PORT = 443;

    // Login-related URIs on CP
    final String CP_LOGIN_FORM_URI = "/login";
    final String CP_LOGIN_VALIDATION_URI = "/login_check";

    // Login details for CP. (These must reflect the form at CP_LOGIN_FORM_URI.)
    final String CP_LOGIN_FORM_USR = "_username";
    final String CP_LOGIN_FORM_PWD = "_password";
    final String CP_LOGIN_FORM_SUBMIT = "_submit";
    final String CP_LOGIN_FORM_SUBMIT_VAL = "Logg+inn";

    // The search results page URI on CP
    final String CP_SERP_URI_BASE = "/norsk-polarinstitutt/hms-handbok/search";
    final String CP_SERP_URI_QUERY = CP_SERP_URI_BASE + "?q=" + URLEncoder.encode(query, "utf-8");

    // Configure the client that we'll be using for all requests to CP
    HttpClient compendiaPersonalClient = new HttpClient();
    compendiaPersonalClient.getParams().setCookiePolicy(CookiePolicy.RFC_2109);
    compendiaPersonalClient.getHostConfiguration().setHost(CP_DOMAIN, CP_PORT, CP_PROTOCOL);

    // Start the interaction!

    // Begin with an attempt to get the SERP directly (without logging in).
    HttpMethod theRequest = new GetMethod(CP_SERP_URI_QUERY);
    theRequest.setFollowRedirects(true); // We'll get lots of redirects
    int responseStatusCode = compendiaPersonalClient.executeMethod(theRequest);

    if (DEBUG) { out.println("<p>Initial GET " + theRequest.getPath() + ": Response was '" + theRequest.getStatusLine().toString() + "'</p>"); }

    if (theRequest.getPath().equals(CP_LOGIN_FORM_URI)) {
        if (DEBUG) { out.println("<p>Posting login...</p>"); }
        // Our last GET was for the login page => Do the login
        theRequest.releaseConnection(); // Release first
        theRequest = new PostMethod(CP_LOGIN_VALIDATION_URI);
        // Set the login details (parameter names like in the form)
        NameValuePair[] loginParams = 
                new NameValuePair[] {
                    new NameValuePair(CP_LOGIN_FORM_USR, usr)
                    ,new NameValuePair(CP_LOGIN_FORM_PWD, pwd)
                    ,new NameValuePair(CP_LOGIN_FORM_SUBMIT, CP_LOGIN_FORM_SUBMIT_VAL)
                };
        // Cast as POST 
        ((PostMethod)theRequest).setRequestBody(loginParams);
        // POST the login details. The response should be a redirect.
        responseStatusCode = compendiaPersonalClient.executeMethod(theRequest);

        // HttpClient 3.x does not allow for follwing redirects when using POST
        // => Follow it manually
        if (responseStatusCode == HttpStatus.SC_MOVED_PERMANENTLY
                || responseStatusCode == HttpStatus.SC_MOVED_TEMPORARILY) {
            Header locationHeader = theRequest.getResponseHeader("Location");
            // Find out what to GET next, then get it (but release the current 
            // HttpMethod instance first)
            String redirectTarget = locationHeader.getValue();
            if (DEBUG) { out.println("<p>Login form validation responded with redirecting to " + redirectTarget + ". Getting it...</p>"); }
            theRequest.releaseConnection();
            theRequest = new GetMethod(redirectTarget);
            theRequest.setFollowRedirects(true);
            responseStatusCode = compendiaPersonalClient.executeMethod(theRequest);
        }
    }

    if (DEBUG) { out.println("<p>Past login step. Last requested path was " + theRequest.getPath() + "</p>"); }
    
    // This block enables revealing cookie values
    if (DEBUG) { 
        CookieSpec cookiespec = CookiePolicy.getDefaultSpec();
        org.apache.commons.httpclient.Cookie[] initcookies = cookiespec.match(
            CP_DOMAIN, CP_PORT, "/", false, compendiaPersonalClient.getState().getCookies()
        );
        out.println("<p>Cookies:</p>");    
        if (initcookies.length == 0) {
            out.println("<p><em>No cookies</em></p>");    
        } else {
            for (int i = 0; i < initcookies.length; i++) {
                out.println("- " + initcookies[i].toString() + "<br>");
            }
        }
    }

    // We should now be authenticated as the shared common user. Yay!

    // GET the SERP's HTML source
    // I.e. get("/norsk-polarinstitutt/hms-handbok/search?q=" + query)
    String serpSource = theRequest.getResponseBodyAsString();
    theRequest.releaseConnection();

    // Parse the HTML so we can cherrypick the interesting bits
    // (Note the jsoup dependency here)
    org.jsoup.nodes.Document serpDoc = Jsoup.parse(serpSource);

    // Pick the interesting bits from the response html
    Elements hitLinks =     serpDoc.select(".main-results-without-dn p");
    Elements hitBottom =    serpDoc.select(".main-results-without-dn p + table");

    // Whitelists to use in the cleaning up of our HTML extractions
    Whitelist whitelistLink = new Whitelist()
            .addTags(
                "a"
            ).addAttributes(
                "a", 
                "href"
    );
    Whitelist whitelistMeta = new Whitelist()
            .addTags(
                "a", 
                "span",
                "b",
                "strong"
            ).addAttributes(
                "a",
                "href"
    );

    if (DEBUG) { out.println("<p>hitLinks.size() is " + hitLinks.size() + ", hitBottom.size() is " + hitBottom.size() + "</p>"); }

    if (!hitLinks.isEmpty()) {
        for (int i = 0; i < hitLinks.size(); i++) {
            String linkTag = Jsoup.clean(hitLinks.get(i).html(), whitelistLink);
            String linkUri = Jsoup.parse(linkTag).select("a").first().attr("href");

            // The "key" parameter must be present in order for links to work
            linkUri = linkUri
                                //.replace("http://", "https://")
                                .concat(linkUri.contains("?") ? "&amp;" : "?").concat("key=" + key);
            String linkText = Jsoup.parse(linkTag).text();
            // Get the snippet/source(+category)
            String linkMeta = Jsoup.clean(hitBottom.get(i).html(), whitelistMeta);
            // First, we split this into [snippet] and [source(+category)]
            // Because we know it will have this structure: 
            //  <span>[snippet]</span>[source(+ category)]
            // we can just use basic string operations
            String linkSnippet = linkMeta.substring("<span>".length(), linkMeta.lastIndexOf("</span")); 
            String linkSourceAndCategory = linkMeta.substring(linkMeta.lastIndexOf("</span"));
            // Next, we need to split the source and catogory, in order to 
            // create a SearchResultHit instance for this hit.
            // Source and category separation is inconsistent, so fix that first:
            //  1.) Replace en dash with hyphen (to ensure consistent delimiter)
            linkSourceAndCategory = linkSourceAndCategory.replace(" -", " -");
            //  2.) Split on that hyphen (even no-category hits will have one)
            String linkSource = StringEscapeUtils.unescapeHtml(linkSourceAndCategory.split(" -")[0]);
            //  3.) Strip leading <span> from the link source
            linkSource = linkSource.substring(linkSource.indexOf(">") + 1);
            //  4.) See if a category was provided (it won't always be)
            String linkCategory = null;
            try { 
                linkCategory = linkSourceAndCategory.split(" -")[1].trim(); 
            } catch (ArrayIndexOutOfBoundsException e) {}
            
            // Finally, create the hit instance.
            // ...or don't (if a source filter was activated by the user and it 
            // doesn't match this hit's source)
            if (sourceSelected == null || sourceSelected.equals(linkSource)) {
                serp.add(new SearchResultHit(linkText, linkSnippet, linkCategory, linkUri, linkUri, linkSource, 98));
            }
        }

    } else {
        // Do nothing
    }
}

/**
 * Requests the given URL and returns the response content payload as a string.
 */
public static String getResponseContent(String requestUrl) {
    try {
        URLConnection connection = new URL(requestUrl).openConnection();
        StringBuffer buffer = new StringBuffer();
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String inputLine;
        while ((inputLine = reader.readLine()) != null) {
            buffer.append(inputLine);
        }
        reader.close();
        return buffer.toString();
    } catch (Exception e) {
        // Unable to contact or read the given URI
        return null;
    }
}

/**
 * Adds employee results to the given SERP.
 * <p>
 * ToDo: Use the standard no.npolar.data.api.PersonService instead.
 */
public static void addEmployeesSerp(String query, SearchResults serp) throws Exception {
    String queryUrl = "http://api.npolar.no:9000/person/?q=" + URLEncoder.encode(query, "utf-8") + "&format=json&facets=false&limit=all";
    JSONObject json = null;
    try {
        // Read the JSON string
        String jsonStr = getResponseContent(queryUrl);

        //out.println("<!-- API URL: " + queryUrl + " -->");

        try {
            // Create the JSON object from the JSON string
            json = new JSONObject(jsonStr).getJSONObject("feed");
        } catch (Exception jsone) {
            return;
        }

        // Project data variables
        String id = null;
        String title = null;
        String fName = null;
        String lName = null;
        String name = null;
        String jobTitle = null;
        //String personFolder = null;
        String personUrl = null;

        // Various JSON variables
        JSONObject openSearch = json.getJSONObject("opensearch");
        int totalResults = openSearch.getInt("totalResults");

        if (totalResults > 0) {

            JSONObject list = json.getJSONObject("list");
            JSONObject search = json.getJSONObject("search");
            JSONArray entries = json.getJSONArray("entries");

            for (int pCount = 0; pCount < entries.length(); pCount++) {
                JSONObject o = entries.getJSONObject(pCount);

                // Mandatory fields
                try {
                    id = o.getString("id");
                    fName = o.getString("first_name");
                    lName = o.getString("last_name");
                    //personFolder = EMPLOYEES_FOLDER + id + "/";
                    personUrl = "http://www.npolar.no/no/ansatte/"+id;
                    name = fName + " " + lName;
                } catch (Exception e) { 
                    // Error on a mandatory field OR no corresponding folder => cannot output this
                    continue; 
                }
                // Optional fields
                try { title = o.getString("title"); title.length(); } catch (Exception e) { title = ""; }
                try { jobTitle = o.getJSONObject("jobtitle").getString("no"); jobTitle.length(); } catch (Exception e) { jobTitle = ""; }
                
                
                int score = 99; // Default score (very high, but not max)
                //if (fName.toLowerCase().startsWith(query.toLowerCase()) || lName.toLowerCase().startsWith(query.toLowerCase()))
                if (name.toLowerCase().contains(query.toLowerCase()))
                    score = 100; // Max
                
                serp.add(new SearchResultHit(name, jobTitle, null, personUrl, personUrl, "Ansatte", score));
            }
        }
        else {
            // No matches
        }

    } catch (Exception e) {

    }
}
/**
 * Creates the HTML used for showing the end user a note/message.
 */
public String makeNote(String note) {
    String s = "<div class=\"msg-error\" style=\"border: 3px solid red; padding:1em 1em 0 1em; background:#fef1ed; color:#900; font-weight:bold; text-align:center;\">";
    //s += "<h2 style=\"border-bottom:1px solid red; color:#900\">Feilmelding</h2>";
    s += note;
    s += "</div>";
    return s;
}
/**
 * Gets the value of the parameter defined by the given name.
 * <p>
 * If no such parameter exists, an empty string is returned.
 */
public static String getParameter(CmsJspActionElement cms, String paramName) {
    String param = cms.getRequest().getParameter(paramName);
    return param != null ? param : "";
}
%>
<%  
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    
    // Get the search manager
    //CmsSearchManager searchManager = OpenCms.getSearchManager(); 
    String requestFileUri = cms.getRequestContext().getUri();
    //String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();

    final boolean ONLINE_PROJECT = cms.getRequestContext().currentProject().isOnlineProject(); //OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
    
    final String PARAM_NAME_SEARCHPHRASE_LOCAL = "query";
    final String LABEL_SEARCH = "Søk";
    final String LABEL_FILTERS = "Filtre";
    
    final Comparator<SearchSource> NUM_HITS_COMP = new Comparator<SearchSource>() {
        public int compare(SearchSource thisOne, SearchSource thatOne) {
            if (thisOne.getNumHits() < thatOne.getNumHits())
                return 1;
            else if (thisOne.getNumHits() > thatOne.getNumHits())
                return -1;
            return 0;
        }
    };
    
    //
    // Setup the OpenCms search
    //
    // Try to retrieve the index name via the assigned property
    String indexName = cms.property("search.index", "search");
    // If the index name was not set as a property, set default value
    if (indexName == null) {
        // Use default index name(s) - !!!the indices defined here may not exist!!!
        indexName = "isblink_no_online";
    } 
    // Use the offline search index when appropriate
    if (!ONLINE_PROJECT) {
        indexName = indexName.replace("_online", "_offline");
    }
    
    CmsSearch search = new CmsSearch();
    search.setMatchesPerPage(Integer.MAX_VALUE);
    search.setDisplayPages(Integer.MAX_VALUE);
    search.setQuery(request.getParameter("query"));
    search.setField(new String[] { "title", "content" });
    search.setIndex(indexName);
    search.init(cms.getCmsObject());
%>

<cms:include property="template" element="header" />

<div>
    <h1><cms:property name="Title" /> for <em><%= search.getQuery() %></em></h1>
<%
// Hold all hits to display
SearchResults serp = new SearchResults();
// The query string
String q = request.getParameter("query");
// The selected source (if any)
String sourceSelected = request.getParameter("source");


if (q != null && !q.isEmpty()) {
    //out.println(getCompendiaPersonalSerp(q, serp));
    try {
        if (sourceSelected == null || !(sourceSelected.equals("Ansatte") || sourceSelected.equals("Isblink"))) {
            // Username / passwords must be set as request attributes in the included file xxx-credentials.jsp
            String usr = (String)pageContext.getAttribute("cp_username");
            String pwd = (String)pageContext.getAttribute("cp_password");
            String key = (String)pageContext.getAttribute("cp_key");
            injectCompendiaPersonalSerp(usr, pwd, key, q, serp, sourceSelected, out);
        }
    } catch (Exception e) {
        note += "<p>En feil oppsto da vi så etter treff i Personal-/HMS-håndboka, Compendia personal og lover.<br />Vi kan derfor ikke vise deg treff fra disse.</p>";
        note += "<p>" + e.getMessage() + "</p>";
    }
    
    try {
        if (sourceSelected == null || sourceSelected.equals("Ansatte")) {
            addEmployeesSerp(q, serp);
        }
    } catch (Exception e) {
        note += "<p>En feil oppsto da vi så etter treff i lista over ansatte.<br />Vi kan derfor ikke vise deg treff fra denne.</p>";
    }
}
try {
    //*
    if (sourceSelected == null || sourceSelected.equals("Isblink")) {
        List<CmsSearchResult> ocmsResults = search.getSearchResult();
        Iterator<CmsSearchResult> iOcmsResults = ocmsResults.iterator();
        while (iOcmsResults.hasNext()) {
            CmsSearchResult ocmsResult = iOcmsResults.next();
            serp.add(new SearchResultHit(
                    ocmsResult.getField(CmsSearchField.FIELD_TITLE)
                    ,ocmsResult.getExcerpt()
                    ,null
                    ,cms.link(cms.getRequestContext().removeSiteRoot(ocmsResult.getPath()))
                    ,OpenCms.getLinkManager().getOnlineLink(cms.getCmsObject(), cms.getRequestContext().removeSiteRoot(ocmsResult.getPath()))
                    ,"Isblink"
                    ,ocmsResult.getScore())
            );

        }
    }
    //*/
} catch (Exception e) {
    out.println("<!-- exception when reading OpenCms search results: " + e.getMessage() + " -->");
    note += "<p>En feil oppsto da vi så etter treff i selve Isblink.<br />Vi kan derfor ikke vise deg treff derfra.</p>";
}

    int numHits = serp.size();

    // Note: getResults() will sort results by score before returning the list
    Iterator<SearchResultHit> iterator = serp.getResults().iterator();
    
    if (!note.isEmpty()) {
        out.println(makeNote(note));
    }
    
    // Construct the filter links / info
    String filters = "";
    if (sourceSelected != null) {
        // User has opted to display hits from specific source
        filters += "<li style=\"display:inline-block; margin:0;\">"
                    + "Viser nå kun treff i &laquo;" + sourceSelected + "&raquo;<br />"
                    + "<a class=\"button\" href=\"" + requestFileUri + "?" + PARAM_NAME_SEARCHPHRASE_LOCAL + "=" + q + "\">"
                        + "Vis treff i alle kilder"
                    + "</a></li>";
    } else {
        try {
            List<SearchSource> sources = serp.getSources();
            if (sources != null && !sources.isEmpty()) {
                Collections.sort(sources, NUM_HITS_COMP);
                Iterator<SearchSource> iSources = sources.iterator();
                while (iSources.hasNext()) {
                    SearchSource source = iSources.next();
                    filters += "<li style=\"display:inline-block; margin:0 1em 1em 0;\">"
                                + "<a class=\"button\" href=\"" + requestFileUri + "?" + PARAM_NAME_SEARCHPHRASE_LOCAL + "=" + q + "&amp;source=" + source.getName() + "\">" 
                                    + source.getName() + " (" + source.getNumHits() + ")" 
                                + "</a></li>";
                }
            }
        } catch (Exception e) {
            // WTF
        }
    }
    %>
    <div class="span1">
        <form class="search-panel" action="<%= requestFileUri %>" method="get">
            <h2 class="search-panel__heading"><%= LABEL_SEARCH %></h2>
            <p class="smalltext">
                Felles søk for <strong>ansatte</strong>, <strong>Isblink</strong>, 
                <strong>HMS- og personalhåndboka</strong>, og oppslagsverket 
                <strong>Compendia Stat</strong>.
            </p>
            <div class="search-widget">
                <div class="searchbox">
                    <input name="<%= PARAM_NAME_SEARCHPHRASE_LOCAL %>" 
                           type="search" 
                           value="<%= CmsStringUtil.escapeHtml(getParameter(cms, PARAM_NAME_SEARCHPHRASE_LOCAL)) %>" 
                           id="q" 
                    />
                    <input class="search-button" 
                           type="submit" 
                           value="<%= LABEL_SEARCH %>"
                    />
                </div>
            </div>
            
            <!--
            <div id="filters-wrap">
                <a id="filters-toggler" onclick="$('#filters').slideToggle();" href="javascript:void(0);"><%= LABEL_FILTERS %></a>
                <div id="filters">
                    <section class="layout-row quadruple clearfix">
                        <div class="boxes">
                            <div class="span1">
                                <ul>
                                    <%= filters %>
                                </ul>
                            </div>
                        </div>
                    </section>
                </div>
            </div>
            -->
        </form>
        
        <div id="filters" style="margin:0; padding:0; text-align:center;">
            <ul class="filters--simple" style="margin:0; padding:0; border:none; font-size:0.8em;">
                <%= filters %>
            </ul>
        </div>
        <h2><%= numHits %><%= (loc.equalsIgnoreCase("no") ? " treff" : (" hit" + (numHits > 1 ? "s" : "")) )%></h2>
        <%
        while (iterator.hasNext()) {
            SearchResultHit hit = iterator.next();
            String entryPath = hit.get(SearchResultHit.URI);

            String hitCat = hit.getCategory();
            if (hitCat == null || hitCat.equalsIgnoreCase("Uten navn"))
                hitCat = "";
            hitCat += (hitCat.isEmpty() ? "" : " &ndash; ") + hit.getSource();

            %>
            <div class="search-hit">
                <h3 class="search-hit__title">
                    <a href="<%= entryPath %>"><%= hit.getTitle() %></a>
                </h3>
                <div class="search-hit__meta smalltext">
                    <span class="search-hit__source tag"><%= hitCat %></span>
                    <%= hit.getSnippet() != null ? hit.getSnippet() : "" %>
                    <div class="search-hit__path" style="color:green;">
                        <%= hit.get(SearchResultHit.DISPLAY_URI) %>
                    </div>
                </div>
            </div>
            <%
        }
        %> 
        
    </div>
</div>
<%
// Reset the note
note = "";
%>
<cms:include property="template" element="footer" />