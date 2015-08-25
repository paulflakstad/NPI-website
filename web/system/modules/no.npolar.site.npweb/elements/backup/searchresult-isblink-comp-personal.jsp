<%-- 
    Document   : searchresult-isblink
    ToDo       : (This is an IDEA) Create a master SERP class holding "hit" 
                    objects (all hits, mixed from all sources), and arrange the 
                    hits (mixed) using their SCORE. This should be quite easy.
                    Also, one should offer the option to filter by source 
                    (Isblink, personalhåndbok, HMS-håndbok etc.)
    Created on : Sep 3, 2014, 5:21:04 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.dom4j.Element"%>
<%@page import="java.util.regex.Matcher"%>
<%@page import="java.util.regex.Pattern"%>
<%@ page import="org.opencms.main.*, 
            org.opencms.security.CmsRoleManager,
            org.opencms.security.CmsRole,
            org.opencms.search.*, 
            org.opencms.search.fields.*, 
            org.opencms.file.*, 
            org.opencms.jsp.*, 
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
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%@include file="compendia-personal-credentials.jsp" 
%><%!
public static String getCompendiaPersonalSerp(String usr, String pwd, String query) throws Exception {
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
    try {
        
        SAXReader reader = new SAXReader();
        StringReader sr = new StringReader(xmlStr);
        Document doc = reader.read(sr);
        
        List databases = doc.selectNodes("//compendiasok/database");
        if (!databases.isEmpty()) {
            Iterator iDatabases = databases.iterator();
            while (iDatabases.hasNext()) {

                Node databaseNode = (Node)iDatabases.next();
                int databaseHits = Integer.valueOf(databaseNode.valueOf("@"+attribNameHits));
                if (databaseHits > 0) {
                    String databaseName = databaseNode.valueOf("@"+attribNameTitle);
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
                        //s += "<h2>Personalhåndboka: " + numHits + " treff</h2>";
                        s += "<a class=\"toggletrigger\" href=\"javascript:void(0);\">" + numHits + " treff i " + databaseName + "</a>";
                        /*if (!items.isEmpty())
                            s += "</a>";*/

                        s += "<div class=\"toggletarget\">";
                        
                        s += "<ul id=\"comp-pers-serp\" style=\"list-style:none; padding-left:0;\">";
                        Iterator i = items.iterator();
                        //int itemsVisited = 0;
                        while (i.hasNext()) {
                            Node itemNode   = (Node)i.next();

                            Node idNode    = null;
                            Node titleNode  = null;
                            Node categoryNode  = null;

                            try { idNode    = itemNode.selectSingleNode("unid"); } catch (Exception e) {}
                            try { titleNode  = itemNode.selectSingleNode("name"); } catch (Exception e) {}
                            try { categoryNode  = itemNode.selectSingleNode("category"); } catch (Exception e) {}

                            //String url = protocol + "://" + domain + pathLoginProxy + "/kunder/npolar/ph.nsf/unique/" + idNode.getText();
                            String url = protocol + "://" + domain + pathLoginProxy + "/" + databasePath + "/unique/" + idNode.getText();

                            s += "<li>";
                            s += "<h3 class=\"searchHitTitle\" style=\"padding:1em 0 0.2em 0; margin:0;\"><a href=\"" + url + "\">" + titleNode.getText() + "</a></h3>";
                            if (!categoryNode.getText().equalsIgnoreCase(noCategory))
                                s += "<div class=\"text\" style=\"font-size:small;\"><i class=\"icon-tag\"></i>&nbsp;" + categoryNode.getText() + "</div>";
                            s += "<div class=\"search-hit-path\" style=\"font-size:0.75em; color:green;\">" + url + "</div>";
                            s += "</li>";
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
            //s += "<a href=\"" + protocol + "://" + domain + pathSerpHuman + "\">Gå til dette søket</a>";
        }
    } catch (Exception e) {
        return e.getMessage();
    }

    //
    // Return a ready-to-use serp section
    //
    return s;
}

public static List<String> cookieList = new ArrayList<String>();

public String getCompendiaId(String loginForm) throws MalformedURLException, IOException {
    URL url = new URL(loginForm);
    URLConnection conn = url.openConnection();
    
    String jSessionId = null;
    
    if (true)
        return conn.getHeaderFields().get("Set-Cookie").get(0);

    String cookieHeader = conn.getHeaderFields().get("Set-Cookie").get(0);
    Pattern p = Pattern.compile("[0-9]{10}\\.[0-9]{5}\\.[0-9]{4}"); // Name of the session
    Matcher m = p.matcher(cookieHeader);
    if (m.find()) {
        jSessionId = cookieHeader.substring(m.start(), m.end());
    }
    //return cookieHeader + " - [" + jSessionId + "]";
	return jSessionId;
}

public List<String> getCookieIds(String loginForm) throws MalformedURLException, IOException {
    URL url = new URL(loginForm);
    URLConnection conn = url.openConnection();    
    
    List<String> cookieIds = new ArrayList<String>();
    
    List<String> cookieValues = conn.getHeaderFields().get("Set-Cookie");
    
    if (!cookieValues.isEmpty()) {
        Iterator<String> i = cookieValues.iterator();

        while (i.hasNext()) {
            String cookieValue = i.next();
            if (cookieValue.contains(";")) 
                cookieValue = cookieValue.substring(0, cookieValue.indexOf(";"));
            cookieIds.add(cookieValue);
        }
    }
    return cookieIds;
}

public void setCookies(URLConnection conn) {
    List<String> cookieValues = conn.getHeaderFields().get("Set-Cookie");
    if (!cookieValues.isEmpty()) {
        Iterator<String> i = cookieValues.iterator();

        while (i.hasNext()) {
            String cookieValue = i.next();
            if (cookieValue.contains(";")) 
                cookieValue = cookieValue.substring(0, cookieValue.indexOf(";"));
            cookieList.add(cookieValue);
        }
    }
}

public void login(String usr, String pwd, JspWriter out) throws MalformedURLException, IOException {
    
    String url = "http://www.compendiapersonal.no/names.nsf?Login";
    
    HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
    
    //String postPayload = "%25%25ModDate=77BE2E5C00000000&Username=" + usr + "&Password=" + pwd + "&RedirectTo=%2F&reason_type=0";
    String postPayload = "%25%25ModDate=77BE2E5C00000000&Username=" + usr + "&Password=" + pwd + "&RedirectTo=%2Fkunder%2Fnpolar%2Fph.nsf";
    //String postPayload = "%25%25ModDate=77BE2E5C00000000&Username=" + usr + "&Password=" + pwd;

    // Act like a browser
    conn.setUseCaches(false);
    conn.setRequestMethod("POST");
    conn.setRequestProperty("Host", "www.compendiapersonal.no");
    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.143 Safari/537.36");
    conn.setRequestProperty("Accept",
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
    conn.setRequestProperty("Accept-Language", "no,en-US,en;q=0.5");
    conn.setRequestProperty("Connection", "keep-alive");
    conn.setRequestProperty("Referer", "http://www.compendiapersonal.no/names.nsf?login");
    conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
    conn.setRequestProperty("Content-Length", Integer.toString(postPayload.length()));

    conn.setDoOutput(true);
    conn.setDoInput(true);

    // Do the POST
    DataOutputStream output = new DataOutputStream(conn.getOutputStream());
    output.writeBytes(postPayload);
    output.flush();
    output.close();

    int responseCode = conn.getResponseCode();
    List<String> cookieValues = conn.getHeaderFields().get("Set-Cookie");
    
    setCookies(conn);
    
    //*
    out.println("<p>Sending 'POST' request to URL : " + url);
    out.println("<br />Post parameters : " + postPayload);
    out.println("<br />Response Code : " + responseCode);
    out.println("</p>");
    //*/

    BufferedReader in = 
         new BufferedReader(new InputStreamReader(conn.getInputStream()));
    String inputLine;
    StringBuffer response = new StringBuffer();

    while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
    }
    in.close();
    
    //out.println("<p>Response:</p>" + response.toString());
    
    /*
    List<String> cookieIds = new ArrayList<String>();
    if (!cookieValues.isEmpty()) {
        Iterator<String> i = cookieValues.iterator();

        while (i.hasNext()) {
            String cookieValue = i.next();
            if (cookieValue.contains(";")) 
                cookieValue = cookieValue.substring(0, cookieValue.indexOf(";"));
            cookieIds.add(cookieValue);
        }
    }
    return cookieIds;
    //*/
    // System.out.println(response.toString());
}

/**
 * Requests the given URL and returns the response content payload as a string.
 */
public String getResponseContent(String requestURL, String compendiaId) {
    try {
        URL url = new URL(requestURL);
        URLConnection conn = url.openConnection();
        
        conn.setRequestProperty("Cookie", "compendia=" + compendiaId);
        StringBuffer buffer = new StringBuffer();
        BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
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
 * Requests the given URL and returns the response content payload as a string.
 */
public String getResponseContent(String requestURL) {
    try {
        URLConnection connection = new URL(requestURL).openConnection();
        
        setCookies(connection);
        
        if (cookieList != null && !cookieList.isEmpty()) {
            String cookieString = "";
            Iterator<String> i = cookieList.iterator();
            while (i.hasNext()) {
                cookieString += i.next();
                if (i.hasNext())
                    cookieString += "; ";
            }
            connection.setRequestProperty("Cookie", cookieString);
        }
        
        
        
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
%><%  
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    
    // Get the search manager
    CmsSearchManager searchManager = OpenCms.getSearchManager(); 
    String resourceUri = cms.getRequestContext().getUri();
    String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
%>
<jsp:useBean id="search" scope="request" class="org.opencms.search.CmsSearch">
    <jsp:setProperty name="search" property="matchesPerPage" param="matchesperpage"/>
    <jsp:setProperty name="search" property="displayPages" param="displaypages"/>
    <jsp:setProperty name="search" property="*"/>
    <% boolean userIsWorkplaceUser = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

    // Get the search manager
    //CmsSearchManager searchManager = OpenCms.getSearchManager(); 
    
        //
        // Set the index
        //

        // Try to retrieve the index name from file property
        String indexName = cms.property("search.index", "search");
        // If the index name was not set as a property, set default value
        if (indexName == null) {
            // default index names (these may not exist -> exception must be caught in SEARCH_RESULT_PAGE)
            //throw new JspException("No search index defined. Use the search.index property to define one.");
            indexName = "isblink_no_online";
        } 
        // If the user is logged in, use the offline search index
        if (userIsWorkplaceUser) {
            indexName = indexName.replace("_online", "_offline");
        }
        search.setIndex(indexName);
        //search.setQuery(URLDecoder.decode(search.getQuery(), "utf-8"));
    	search.init(cms.getCmsObject());
    %>
</jsp:useBean>

<cms:include property="template" element="header" />

<div>
    <h1><cms:property name="Title" /> for <em><%= search.getQuery() %></em></h1>
<%
// Username / passwords must be set as request attributes in the included file xxx-credentials.jsp
String usr = (String)pageContext.getAttribute("cp_username");
String pwd = (String)pageContext.getAttribute("cp_password");
// Hits elsewhere
String q = request.getParameter("query");
if (q != null && !q.isEmpty()) {
    out.println(getCompendiaPersonalSerp(usr, pwd, q));
}
    
    
    
    int resultno = 1;
    int pageno = 0;
    if (request.getParameter("searchPage") != null) {		
            pageno = Integer.parseInt(request.getParameter("searchPage")) - 1;
    }
    resultno = (pageno * search.getMatchesPerPage()) + 1;

    //String fields = search.getFields();
    String fields = "title content";
    if (fields == null) {
        fields = request.getParameter("fields");
    }

    List result = null;
    try {
        result = search.getSearchResult();
    }
    catch (java.lang.NullPointerException npe) {
        String errorMessage = loc.equalsIgnoreCase("no") ? 
            "<p>Det ser ut som at du ikke har søkt på noe(?). Bruk søkefeltet for å søke, eller kontakt oss hvis du mener noe har gått galt.</p>" :
            "<p>It seems you did't search for anything(?). Please use the search field to search, or contact us if you think an error occurred.</p>";
            
        out.println(errorMessage);
        /*
        if (!cms.getRequestContext().currentUser().isGuestUser()) {
            out.println("<h3>Script crashed!</h3>A null pointer was encountered while attempting to process the search results." +
                        " The cause may be an invalid or missing search index.<br>&nbsp;<br> Please notify the system administrator.</h3>");
            StackTraceElement[] npeStack = npe.getStackTrace();
            if (npeStack.length > 0) {
                out.println("<h4>Stack trace:</h4>"); //npe.printStackTrace(response.getWriter());
                out.println("<span style=\"display:block; width:auto; overflow:scroll; font-style:italic; color:red; border:1px dotted #555555; background-color:#DEDEDE; padding:5px;\">");
                out.println("java.lang.NullPointerException:<br>");
                for (int i = 0; i < npeStack.length; i++) {
                        out.println(npeStack[i].toString());
                }
                out.println("</span>");
            }
        }
        else {
            if (loc.equalsIgnoreCase("no")) {
                out.println("<h3>Beklager, en feil oppsto.</h3><p>Vennligst prøv igjen senere.</p>");
            } else {
                out.println("<h3>We're sorry, an error occured.</h3><p>Please try again at a later time.</p>");
            }
        }
        */
   }
	// DEBUG:
	/*
	out.println("<h4>Fields: " + fields + "</h4>");
	out.println("<h4>Resultno: " + resultno + "</h4>");
	out.println("<h4>Pageno: " + pageno + "</h4>");
	out.println("<h4>Result (List): " + result + "</h4>");
	*/
	
    if (result == null) {
    %>
    <%
        if (search.getLastException() != null) { 
            out.println("<h3>Error</h3>" + search.getLastException().toString());
        }
    } 
    else {
        ListIterator iterator = result.listIterator();
        // Result count is sometimes off by one ...
        int numHits = result.size() - 1; 
        // ... and sometimes not
        if (numHits < 0)
            numHits = 0;
        %>
        <div class="span1">
        <h2>Isblink: <%= numHits %><%= (loc.equalsIgnoreCase("no") ? 
        " treff" : (" hit" + (numHits > 1 ? "s" : "")) )%></h2>
        <%
        while (iterator.hasNext()) {
            CmsSearchResult entry = (CmsSearchResult)iterator.next();
            String entryPath = cms.link(cms.getRequestContext().removeSiteRoot(entry.getPath()));
            // Hide pages with title = "null"
            if (entry.getField(CmsSearchField.FIELD_TITLE) != null && !entry.getField(CmsSearchField.FIELD_TITLE).equalsIgnoreCase("null")) {
            %>
                <h3 class="searchHitTitle" style="padding:1em 0 0.2em 0; margin:0;">
                    <a href="<%= entryPath %>"><%= entry.getField(CmsSearchField.FIELD_TITLE) %></a>
                </h3>
                <div class="text">
                    <%= entry.getExcerpt() != null ? entry.getExcerpt() : "" %>
                </div>
                <div class="search-hit-path" style="font-size:0.75em; color:green;">
                    <%= "http://" + request.getServerName() + entryPath %>
                </div>
				
            <%
            }
            resultno++;            
        }
    }
%> 
        <div class="pagination" style="margin-top:2em;">
<%
        
	if (search.getPreviousUrl() != null) {
%>
            <input type="button" value="&lt;&lt; <%= (loc.equalsIgnoreCase("no") ? "forrige" : "previous") %>" 
                onclick="location.href='<%= cms.link(search.getPreviousUrl()) %>&fields=<%= fields %>';">
<%
	}
	Map pageLinks = search.getPageLinks();
	Iterator i =  pageLinks.keySet().iterator();
	while (i.hasNext()) {
            int pageNumber = ((Integer)i.next()).intValue();
            String pageLink = cms.link((String)pageLinks.get(new Integer(pageNumber)));       		
            out.print("&nbsp; &nbsp;");
            if (pageNumber != search.getSearchPage()) {
%>
                <a href="<%= pageLink %>&amp;fields=<%= fields %>"><%= pageNumber %></a>
<%
            } 
            else {
%>
                <span class="currentpage"><%= pageNumber %></span>
<%
            }
	}
	if (search.getNextUrl() != null) {
%>
            &nbsp; &nbsp;
            <input type="button" value="<%= (loc.equalsIgnoreCase("no") ? "neste" : "next") %> &gt;&gt;" 
                onclick="location.href='<%= cms.link(search.getNextUrl()) %>&amp;fields=<%= fields %>';">
<%
	} 
%>  
        </div>
        </div>
<%
// Search elsewhere

//String q = request.getParameter("query");
//if (q != null && !q.isEmpty()) {
    
//    out.println("<div class=\"span1\">");
//    out.println(getCompendiaPersonalSerp(q));
//    out.println("</div>");
    
    // First log in and get a session
    //String compendiaId = getCompendiaId("http://www.compendiapersonal.no/names.nsf?login&username=" + usr + "&password=" + pwd + "&redirectto=/kunder/npolar/ph.nsf");
    //out.println(compendiaId);
    
    /*
    //List<String> cookies = login(out);
    login(out);
    //List<String> cookies = getCookieIds("http://www.compendiapersonal.no/names.nsf?login&username=" + usr + "&password=" + pwd);
    //List<String> cookies = getCookieIds("http://www.compendiapersonal.no/names.nsf?login&username=" + usr + "&password=" + pwd + "&redirectto=/kunder/npolar/ph.nsf");
    Iterator<String> iCookies = cookieList.iterator();
    while (iCookies.hasNext()) {
        out.println(iCookies.next());
    }
    //*/
    
    
    /*
    try {
        HttpURLConnection connection = (HttpURLConnection)new URL("http://www.compendiapersonal.no/Kunder/npolar/ph.nsf/unique/C1257C5A0027DE4FC12573FA005188AC").openConnection();
        
        if (cookieList != null && !cookieList.isEmpty()) {
            String cookieString = "";
            iCookies = cookieList.iterator();
            while (iCookies.hasNext()) {
                cookieString += iCookies.next();
                if (iCookies.hasNext())
                    cookieString += "; ";
            }
            connection.setRequestProperty("Cookie", cookieString);
        }
        out.println("<br />Connecting to " + connection.getURL().toString());
        out.println("<br />Response code: " + connection.getResponseCode());
        
        StringBuffer buffer = new StringBuffer();
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String inputLine;
        while ((inputLine = reader.readLine()) != null) {
            buffer.append(inputLine);
        }
        reader.close();
        out.print(buffer.toString());
        
        
        out.println("<br />URL was " + connection.getURL().toString());
        
    } catch (Exception e) {
        // Unable to contact or read the DB service
        out.println("An error occured: " + e.getMessage());
    }
    //*/
    
    
    
    
    /*
    String url = "http://www.compendiapersonal.no/kunder/npolar/ph.nsf/search?readform&q=" + q;
    try {
        String content = getResponseContent(url, cookies);
        out.println("<!-- Chewing on " + content.getBytes().length + " bytes of content from " + url + " ... -->");
        
        final String START_TOKEN = "<div id=\"result\"";
        final String END_TOKEN = "<div id=\"bottom-navigation";
        
        // Remove everything before the start token
        //content = content.substring(content.indexOf(START_TOKEN));
        // Remove everything after the last table row (starting from "</table")
        //content = content.substring(0, content.indexOf(END_TOKEN));
        
        out.println(content);
    } catch (Exception e) {
        out.println("<!-- Error: " + e.getMessage() + " -->");
    }
    //*/
//}
cookieList.clear();
%>
</div>
<cms:include property="template" element="footer" />