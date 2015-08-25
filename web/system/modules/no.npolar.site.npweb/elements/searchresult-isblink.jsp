<%-- 
    Document   : searchresult-isblink
    ToDo       : (This is an IDEA) Create a master SERP class holding "hit" 
                    objects (all hits, mixed from all sources), and arrange the 
                    hits (mixed) using their SCORE. This should be quite easy.
                    Also, one should offer the option to filter by source 
                    (Isblink, personalh�ndbok, HMS-h�ndbok etc.)
    Created on : Sep 3, 2014, 5:21:04 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.dom4j.Element"%>
<%@page import="java.util.regex.Matcher"%>
<%@page import="java.util.regex.Pattern"%>
<%@page import="org.opencms.main.*, 
            org.opencms.security.CmsRoleManager,
            org.opencms.security.CmsRole,
            org.opencms.search.*, 
            org.opencms.search.fields.*, 
            org.opencms.file.*, 
            org.opencms.json.*,
            org.opencms.jsp.*, 
            org.opencms.util.CmsStringUtil,
            org.dom4j.Document,
            org.dom4j.Node,
            org.dom4j.io.SAXReader,
            java.util.*,
            java.io.*,
            java.net.*,
            org.apache.commons.httpclient.*,
            org.apache.commons.httpclient.cookie.CookiePolicy,
            org.apache.commons.httpclient.cookie.CookieSpec,
            org.apache.commons.httpclient.methods.*" buffer="none"
%><%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%@include file="compendia-personal-credentials.jsp" 
%><%!
public static String note = "";

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
    
    public SearchResultHit(String title, String snippet, String category, String uri, String displayUri, String source, int score) {
        this.title = title;
        this.snippet = snippet;
        this.category = category;
        this.uri = uri;
        this.displayUri = displayUri;
        this.source = source;
        this.score = score;
    }
    
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
    public String getTitle() { return title; }
    public String getSnippet() { return snippet; }
    public String getCategory() { return category; }
    public String getUri() { return uri; }
    public String getSource() { return source; }
    public int getScore() { return score; }
    
    public int compare(SearchResultHit thisResult, SearchResultHit thatResult) {
        if (thisResult.getScore() < thatResult.getScore())
            return -1;
        else if (thisResult.getScore() > thatResult.getScore())
            return 1;
        return 0;
    }
}

public static class SearchSource implements Comparable {
    private String name = null;
    private int numHits = -1;
    
    
    public SearchSource(String name) {
        this.name = name;
        numHits = 0;
    }
    public String getName() {
        return name;
    }
    public int addOneHit() {
        return ++numHits;
    }
    public int getNumHits() {
        return numHits;
    }
    public int compareTo(Object that) {
        if (that instanceof SearchSource) {
            return this.name.compareTo(((SearchSource)that).name);
        }
        throw new IllegalArgumentException("Only other SearchSource instances can be compared to this SearchSource.");
    }
    public boolean equals(Object that) {
        if (that == null || !(that instanceof SearchSource))
            return false;
        return this.name.equals(((SearchSource)that).name);
    }
}

public static class SearchResults {
    public Comparator<SearchResultHit> SCORE_COMP = new Comparator<SearchResultHit>() {
        public int compare(SearchResultHit thisResult, SearchResultHit thatResult) {
            if (thisResult.getScore() < thatResult.getScore())
                return 1;
            else if (thisResult.getScore() > thatResult.getScore())
                return -1;
            return 0;
        }
    };
    private List<SearchResultHit> hits = null;
    private List<SearchSource> sources = null;
    
    public SearchResults() {
        hits = new ArrayList<SearchResultHit>();
        sources = new ArrayList<SearchSource>();
    }
    
    public List<SearchSource> getSources() {
        return sources;
    }
    
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
    
    public int size() {
        return hits.size();
    }
    
    public boolean remove(SearchResultHit hit) {
        return hits.remove(hit);
    }
    
    public void clear() {
        hits.clear();
    }
    
    public Iterator<SearchResultHit> iterator() {
        return hits.iterator();
    }
    
    public List<SearchResultHit> getHits() {
        return hits;
    }
    public List<SearchResultHit> getResults() {
        Collections.sort(hits, SCORE_COMP);
        return hits;
    }
}
/**
 * Not done ...
 */
public class SearchResultsXml {
    String xmlSource = null;
    
    public SearchResultsXml(String xmlSource) {
        this.xmlSource = xmlSource;
    }
}

public static String getCompendiaPersonalSerp(String usr, String pwd, String query, SearchResults serp, String sourceSelected) throws Exception {
    //
    // See http://svn.apache.org/viewvc/httpcomponents/oac.hc3x/trunk/src/examples/FormLoginDemo.java?revision=604567&view=markup
    //
    
    String xmlStr = null; 
    String s = "";
    
    int port = 80;
    String protocol = "http";
    String domain = "www.compendiapersonal.no";
    String pathSerp = "/kunder/npolar/sokemoto.nsf/sokemotorxml?OpenAgent&search=" + URLEncoder.encode(query, "utf-8");
    
    String pathLoginProxy = "/names.nsf?login&amp;username=" + usr + "&amp;password=" + pwd + "&amp;redirectto=";
    String pathSerpHuman = pathLoginProxy + URLEncoder.encode("/kunder/npolar/ph.nsf/search?readform&q=" + query, "utf-8");
    
    String hms = "kunder/npolar/hms.nsf";
    String ph = "kunder/npolar/ph.nsf";
    String compPers = "kilder/compendia_personal.nsf";
    String laws = "kilder/lover_og_forskrifter.nsf";
    
    String noCategory = "Uten navn";
    
    String attribNameTitle = "title";
    String attribNameHits = "hits";
    String attribNamePath = "path";
    
    final int MAX_DB_HITS = 100;
    
    HttpClient httpclient = new HttpClient();
    httpclient.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY);
    httpclient.getHostConfiguration().setHost(domain, port, protocol);
    
    //
    // GET the login page
    //
    GetMethod authget = new GetMethod("/names.nsf");
    httpclient.executeMethod(authget);
    authget.releaseConnection();
    
    
    // See if we got any cookies
    CookieSpec cookiespec = CookiePolicy.getDefaultSpec();
    org.apache.commons.httpclient.Cookie[] initcookies = cookiespec.match(
        domain, port, "/", false, httpclient.getState().getCookies());
    
    //
    // POST login details
    //
    PostMethod authpost = new PostMethod("/names.nsf?Login");
    // Prepare login parameters
    NameValuePair[] loginParams = 
            new NameValuePair[] {
                new NameValuePair("%%ModDate", "0000000000000000"),
                new NameValuePair("Username", usr),
                new NameValuePair("Password", pwd),
                new NameValuePair("RedirectTo", pathSerp),
                new NameValuePair("reason_type", "0")
            };
    authpost.setRequestBody(loginParams);
    httpclient.executeMethod(authpost);
    authpost.releaseConnection();
    
    //
    // GET the serp as xml
    //
    GetMethod xmlGet = new GetMethod(pathSerp);
    httpclient.executeMethod(xmlGet);
    xmlStr = xmlGet.getResponseBodyAsString();
    //s += "<!--\nXML response:\n" + xmlStr + "\n-->";
    xmlGet.releaseConnection();
    
    
    //
    // Parse the xml
    //
    //try {
        
        SAXReader reader = new SAXReader();
        StringReader sr = new StringReader(xmlStr);
        Document doc = reader.read(sr);
        
        List databases = doc.selectNodes("//compendiasok/database");
        if (!databases.isEmpty()) {
            Iterator iDatabases = databases.iterator();
            while (iDatabases.hasNext()) {

                Node databaseNode = (Node)iDatabases.next();
                String databaseName = databaseNode.valueOf("@"+attribNameTitle);
                if (sourceSelected == null || sourceSelected.equals(databaseName)) {
                    int databaseHits = Integer.valueOf(databaseNode.valueOf("@"+attribNameHits));
                    if (databaseHits > MAX_DB_HITS) {
                        note += "<p>" + databaseHits + " treff i &laquo;" + databaseName + "&raquo; er kortet ned til de " + MAX_DB_HITS + " beste.</p>";
                        //continue;
                    }
                    if (databaseHits > 0) {
                        String databasePath = databaseNode.valueOf("@"+attribNamePath);

                        // Get the number of items
                        // This method should work, but experienced hits="1" error
                        //String numHits = doc.selectSingleNode("//compendiasok/database").valueOf("@hits");

                        //List items = doc.selectNodes("//compendiasok/database/document");///title");
                        List items = databaseNode.selectNodes("document");///title");
                        int numHits = items.size();

                        if (numHits > 0) {
                            s += "<div class=\"toggleable collapsed\">";
                            //int topHitsLimit = 10;

                            /*if (!items.isEmpty())
                                s += "<a href=\"" + protocol + "://" + domain + pathSerpHuman + "\">";*/
                            //s += "<h2>Personalh�ndboka: " + numHits + " treff</h2>";
                            s += "<a class=\"toggletrigger\" href=\"javascript:void(0);\">" + numHits + " treff i " + databaseName + "</a>";
                            /*if (!items.isEmpty())
                                s += "</a>";*/

                            s += "<div class=\"toggletarget\">";

                            s += "<ul id=\"comp-pers-serp\" style=\"list-style:none; padding-left:0;\">";
                            Iterator i = items.iterator();
                            int itemsVisited = 0;
                            while (i.hasNext() && itemsVisited++ < MAX_DB_HITS) {
                                Node itemNode   = (Node)i.next();

                                Node idNode    = null;
                                Node titleNode  = null;
                                Node categoryNode  = null;
                                Node scoreNode = null;

                                try { idNode    = itemNode.selectSingleNode("unid"); } catch (Exception e) {}
                                try { titleNode  = itemNode.selectSingleNode("name"); } catch (Exception e) {}
                                try { categoryNode  = itemNode.selectSingleNode("category"); } catch (Exception e) {}
                                try { scoreNode = itemNode.selectSingleNode("score"); } catch (Exception e) {}

                                //String url = protocol + "://" + domain + pathLoginProxy + "/kunder/npolar/ph.nsf/unique/" + idNode.getText();
                                String url = protocol + "://" + domain + pathLoginProxy + "/" + databasePath + "/unique/" + idNode.getText();

                                s += "<li>";
                                s += "<h3 class=\"searchHitTitle\" style=\"padding:1em 0 0.2em 0; margin:0;\"><a href=\"" + url + "\">" + titleNode.getText() + "</a></h3>";
                                if (!categoryNode.getText().equalsIgnoreCase(noCategory))
                                    s += "<div class=\"text\" style=\"font-size:small;\"><i class=\"icon-tag\"></i>&nbsp;" + categoryNode.getText() + "</div>";
                                s += "<div class=\"search-hit-path\" style=\"font-size:0.75em; color:green;\">" + url + "</div>";
                                s += "</li>";

                                serp.add(new SearchResultHit(
                                        titleNode.getText()
                                        , ""
                                        , categoryNode.getText().equalsIgnoreCase(noCategory) ? "" : categoryNode.getText()
                                        , url
                                        , url.replace(pathLoginProxy, "")
                                        , databaseName
                                        , Integer.valueOf(scoreNode.getText()))
                                        );
                            }
                            s += "</ul>";
                            /*
                            if (topHitsLimit < numHits) {
                                int diff = numHits - topHitsLimit;
                                s += "<a href=\"" + protocol + "://" + domain + pathSerpHuman + "\">&hellip;&nbsp;og " + diff + (diff > 1 ? " flere treff" : " treff til") + "</a>";
                            }
                            */
                            s += "</div>";
                            s += "</div>";
                        }
                    }
                }
            }
            //s += "<a href=\"" + protocol + "://" + domain + pathSerpHuman + "\">G� til dette s�ket</a>";
        }
    /*} catch (Exception e) {
        return e.getMessage();
    }*/

    //
    // Return a ready-to-use serp section
    //
    return s;
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
        // Unable to contact or read the DB service
        return null;
    }
}

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

public String makeNote(String note) {
    String s = "<div class=\"msg-error\" style=\"border: 3px solid red; padding:1em 1em 0 1em; background:#fef1ed; color:#900; font-weight:bold; text-align:center;\">";
    //s += "<h2 style=\"border-bottom:1px solid red; color:#900\">Feilmelding</h2>";
    s += note;
    s += "</div>";
    return s;
}
/**
 * Gets a particular parameter value. If no such parameter exists, an empty 
 * string is returned.
 */
public static String getParameter(CmsJspActionElement cms, String paramName) {
    String param = cms.getRequest().getParameter(paramName);
    return param != null ? param : "";
}
%><%  
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    
    // Get the search manager
    CmsSearchManager searchManager = OpenCms.getSearchManager(); 
    String requestFileUri = cms.getRequestContext().getUri();
    String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();

    boolean onlineProject = cms.getRequestContext().currentProject().isOnlineProject(); //OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
    
    final String PARAM_NAME_SEARCHPHRASE_LOCAL = "query";
    final String LABEL_SEARCH = "S�k";
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
    if (!onlineProject) {
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
SearchResults serp = new SearchResults();
// Hits elsewhere
String q = request.getParameter("query");
//
String sourceSelected = request.getParameter("source");


if (q != null && !q.isEmpty()) {
    //out.println(getCompendiaPersonalSerp(q, serp));
    try {
        if (sourceSelected == null || !(sourceSelected.equals("Ansatte") || sourceSelected.equals("Isblink"))) {
            // Username / passwords must be set as request attributes in the included file xxx-credentials.jsp
            String usr = (String)pageContext.getAttribute("cp_username");
            String pwd = (String)pageContext.getAttribute("cp_password");
            getCompendiaPersonalSerp(usr, pwd, q, serp, sourceSelected);
        }
    } catch (Exception e) {
        note += "<p>En feil oppsto da vi s� etter treff i Personal-/HMS-h�ndboka, Compendia personal og lover.<br />Vi kan derfor ikke vise deg treff fra disse.</p>";
    }
    
    try {
        if (sourceSelected == null || sourceSelected.equals("Ansatte"))
            addEmployeesSerp(q, serp);
    } catch (Exception e) {
        note += "<p>En feil oppsto da vi s� etter treff i lista over ansatte.<br />Vi kan derfor ikke vise deg treff fra denne.</p>";
    }
}
try {
    //*
    if (sourceSelected == null || sourceSelected.equals("Isblink")) {
        List<CmsSearchResult> ocmsResults = search.getSearchResult();
        Iterator<CmsSearchResult> iOcmsResults = ocmsResults.iterator();
        while (iOcmsResults.hasNext()) {
            CmsSearchResult ocmsResult = iOcmsResults.next();
            serp.add(
                        new SearchResultHit(
                                            ocmsResult.getField(CmsSearchField.FIELD_TITLE)
                                            , ocmsResult.getExcerpt()
                                            , null
                                            , cms.link(cms.getRequestContext().removeSiteRoot(ocmsResult.getPath()))
                                            , OpenCms.getLinkManager().getOnlineLink(cms.getCmsObject(), cms.getRequestContext().removeSiteRoot(ocmsResult.getPath()))
                                            , "Isblink"
                                            , ocmsResult.getScore())
                    );

        }
    }
    //*/
} catch (Exception e) {
    out.println("<!-- exception when reading OpenCms search results: " + e.getMessage() + " -->");
    note += "<p>En feil oppsto da vi s� etter treff i selve Isblink.<br />Vi kan derfor ikke vise deg treff derfra.</p>";
}

    int numHits = serp.size();

    // Note that getResults() will SORT the list BY SCORE before returning it
    Iterator<SearchResultHit> iterator = serp.getResults().iterator();
    
    if (!note.isEmpty()) {
        out.println(makeNote(note));
    }
    
    String filters = "";
    if (sourceSelected != null) {
        filters += "<li style=\"display:inline-block; margin:0;\">"
                    + "Viser n� kun treff i &laquo;" + sourceSelected + "&raquo;<br />"
                    + "<a href=\"" + requestFileUri + "?" + PARAM_NAME_SEARCHPHRASE_LOCAL + "=" + q + "\">"
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
                                + "<a href=\"" + requestFileUri + "?" + PARAM_NAME_SEARCHPHRASE_LOCAL + "=" + q + "&amp;source=" + source.getName() + "\">" 
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
        <div class="searchbox-big">
            <h2><%= LABEL_SEARCH %></h2>
            <form action="<%= requestFileUri %>" method="get">
                <input name="<%= PARAM_NAME_SEARCHPHRASE_LOCAL %>" type="search" value="<%= CmsStringUtil.escapeHtml(getParameter(cms, PARAM_NAME_SEARCHPHRASE_LOCAL)) %>" style="padding: 0.5em; font-size: larger;" id="q" />
                <input type="submit" value="<%= LABEL_SEARCH %>" />
            </form>
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
        </div>
        
        <div id="filters" style="margin:0; padding:0; text-align:center;">
            <ul style="margin:0; padding:0; border:none; font-size:0.8em;">
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
                <h3 class="searchHitTitle" style="margin-bottom:0;">
                    <a href="<%= entryPath %>"><%= hit.getTitle() %></a>
                </h3>
                <div class="text" style="font-size:small;"><span class="tag"><%= hitCat %></span></div>
                <div class="text">
                    <%= hit.getSnippet() != null ? hit.getSnippet() : "" %>
                </div>
                <div class="search-hit-path" style="font-size:0.75em; color:green;">
                    <%= hit.get(SearchResultHit.DISPLAY_URI) %>
                </div>

            <%
        }
// Reset the note
note = "";
        %> 
        
    </div>
</div>
<cms:include property="template" element="footer" />