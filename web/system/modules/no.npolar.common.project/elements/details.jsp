<%-- 
    Document   : details
    Description: Fetches and presents project details from an external service, using the given project ID.
    Created on : Sep 2, 2013, 11:38:28 PM
    Author     : flakstad
--%><%@page import="org.opencms.mail.CmsSimpleMail"%>
<%@page import="java.util.SortedMap,
                 java.util.Arrays,
                 java.util.Collections,
                 java.util.SortedSet,
                 java.util.TreeSet,
                 no.npolar.util.*,
                 no.npolar.data.api.*,
                 no.npolar.data.api.util.*,
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
                 org.markdown4j.Markdown4jProcessor,
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
public static String markdownToHtml(String s) {
    try { return new Markdown4jProcessor().process(s); } catch (Exception e) { return s + "\n<!-- Could not process this as markdown -->"; }
}

/** 
 * Tries to match a category or any of its parent categories against a list of possible matching categories. 
 * Used typically to retrieve the "top level" (parent) category of a given category.
 *
 * @param possibleMatches The list of possible matching categories (typically "top level" categories).
 * @param category The category to match against the list of possible matches (typically any category assigned to an event).
 * @param cmso An initialized CmsObject.
 * @param categoryReferencePath The category reference path - i.e. a path that is used to determine which categories are available.
 * 
 * @return The first category in the list of possible matches that matches the given category, or null if there is no match.
 */
public static CmsCategory matchCategoryOrParent(List<CmsCategory> possibleMatches, CmsCategory category, CmsObject cmso, String categoryReferencePath) throws CmsException {
    CmsCategoryService cs = CmsCategoryService.getInstance();
    String catPath = category.getPath();
    CmsCategory tempCat = null;
    while (catPath.contains("/") && !(catPath = catPath.substring(0, catPath.lastIndexOf("/"))).equals("")) {
        try {
            tempCat = cs.readCategory(cmso, catPath, categoryReferencePath);
            if (possibleMatches.contains(tempCat))
                return tempCat;
        } catch (Exception e) {
            return null;
        }
    }
    return null;
}

// Mappings: DB values <==> values to display on-screen
static HashMap<String, String> valueMappings = new HashMap<String, String>();
// Institution symbols
static HashMap<String, String> symbolMappings = new HashMap<String, String>();
final String[] symbols = { "&Dagger;", "&loz;", "&nabla;" };
static int symbolsGenerated = 0;


/**
 * Convenience class: Person
 */
public class Person {
    private String fname = null;
    private String lname = null;
    private String inst = null;
    private String uri = null;
    private String instSymbol = null;
    
    public Person() {  }
    
    public Person(String fname, String lname) {
        this.fname = fname;
        this.lname = lname;
    }
    public void setInstitution(String inst) { this.inst = inst; }
    public void setInstitutionSymbol(String instSymbol) { this.instSymbol = instSymbol; }
    public void setUri(String uri) { this.uri = uri; }
    public String getName() { return fname + " " + lname; }
    public String getFirstName() { return fname; }
    public String getLastName() { return lname; }
    public String getInstitution() { return inst; }
    public String getUri() { return uri; }
    public String toString() {
        String s = getName();
        //if (inst != null && !inst.isEmpty())
        //    s += " [" + inst + "]";
        if (inst != null && !inst.isEmpty()) {
            //s += "<sup style=\"vertical-align:top; position:relative; top:-3px;\">" + symbolMappings.get(inst) + "</sup>";
            //s += "<sup style=\"vertical-align:top; position:relative; top:2px; cursor:pointer;\">" 
            s += "<sup style=\"position:relative; top:2px; cursor:pointer;\">" 
                    + "<span data-tooltip=\"" + symbolMappings.get(instSymbol) + "\"> ["
                    + instSymbol 
                    + "]</span>"
                + "</sup>";
        }
        if (uri != null && !uri.isEmpty())
            s = "<a href=\"" + uri + "\">" + s + "</a>";
            
        return s;
    }
    public String toString(CmsAgent cms) {
        String s = getName();
        if (inst != null && !inst.isEmpty())
            s += " [" + inst + "]";
        if (uri != null && !uri.isEmpty())
            s = "<a href=\"" + cms.link(uri) + "\">" + s + "</a>";
            
        return s;
    }
}

/**
 * Convenience class: String or link
 */
public class OptLink {
    private String text = null;
    private String uri = null;
    
    public OptLink() {
    }
    public OptLink(String text) {
        this.text = text;
    }    
    public OptLink(String text, String uri) {
        this.text = text;
        this.uri = uri;
    }
    
    public void setUri(String uri) { this.uri = uri; }
    public String getUri() { return uri; }
    public String getText() { return text; }
    public String toString() {
        String s = text;
        if (uri != null && !uri.isEmpty())
            s = "<a href=\"" + uri + "\">" + s + "</a>";
        return s;
    }
    public String toString(CmsAgent cms) {
        String s = text;
        if (uri != null && !uri.isEmpty())
            s = "<a href=\"" + cms.link(uri) + "\">" + s + "</a>";
        return s;
    }
}

public List<SubProject> getSubProjectList(CmsAgent cms, I_CmsXmlContentContainer xmlContent) throws JspException {
    List<SubProject> sp = new ArrayList<SubProject>();
    if (xmlContent.hasMoreContent()) {
        I_CmsXmlContentContainer subProjectsContainer = cms.contentloop(xmlContent, "SubProject");
        if (subProjectsContainer == null)
            return sp;

        try {
            while (subProjectsContainer.hasMoreContent()) {
                try {
                    String u = cms.contentshow(subProjectsContainer, "URI");
                    String t = cms.contentshow(subProjectsContainer, "Title");
                    String d = cms.contentshow(subProjectsContainer, "Description");
                    String i = cms.contentshow(subProjectsContainer, "Image");
                    
                    String pid = null;
                    Project project = null;
                    if (u.contains("?pid=")) { // The URI is a link to a local project
                        pid = u.substring(u.indexOf("?pid=") + 5, u.length());
                        try {
                            // Read project from service
                            HashMap<String, String[]> psParams = new HashMap<String, String[]>();
                            psParams.put("q", new String[]{""});
                            psParams.put("format", new String[]{"json"});
                            psParams.put("filter-id", new String[]{pid});
                            project = new ProjectService(cms.getRequestContext().getLocale()).getProjectList(psParams).get(0);
                            // ToDo:
                            //Project project = new ProjectService(cms.getRequestContext().getLocale()).getProject(pid);
                        } catch (Exception e) {
                            // Whoopsie ...
                        }
                        
                    }

                    SubProject p = new SubProject(u);
                    
                    // Title
                    String title = "";
                    if (CmsAgent.elementExists(t)) {
                        title = t; // As defined in the parent/programme file in OpenCms
                    } else if (project != null) {
                        title = project.getTitle();
                    } else {
                        try {
                            title = cms.getCmsObject().readPropertyObject(u, "Title", false).getValue("");
                        } catch (Exception e) {}
                    }
                    p.setTitle(title);
                    
                    // Description
                    String descr = "";
                    if (CmsAgent.elementExists(d)) {
                        descr = d;
                    } else if (project != null) {
                        descr = project.getDescription();
                    } else {
                        try {
                            descr = cms.getCmsObject().readPropertyObject(u, "Description", false).getValue("");
                        } catch (Exception e) {}    
                    }
                    p.setDescr(descr);
                    
                    // Image 
                    String imageUri = "";
                    if (CmsAgent.elementExists(i)) {
                        imageUri = i;
                    } else {
                        try {
                            imageUri = cms.getCmsObject().readPropertyObject(u, "image.thumb", false).getValue("");
                        } catch (Exception e) {}
                    }
                    p.setImageUri(imageUri);
                    
                    sp.add(p);
                } catch (Exception e) {
                    throw new JspException("Error creating project instance: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            throw new JspException("Error processing XML container for sub-projects: " + e.getMessage());
        }
    }
    return sp;
}

public class SubProject {
    private String uri = null;
    private String title = null;
    private String descr = null;
    private String imageUri = null;
    
    public SubProject(String uri) {
        this.uri = uri;
    }
    
    public void setTitle(String title) { this.title = title; }
    public void setDescr(String descr) { this.title = title; }
    public void setImageUri(String imageUri) { this.imageUri = imageUri; }
    
    public String getUri() { return this.uri; }
    public String getTitle() { return this.title; }
    public String getDescr() { return this.descr; }
    public String getImageUri() { return this.imageUri; }
    
    public String getAsCard(CmsAgent cms) {
        CmsObject cmso = cms.getCmsObject();
        String s = "";
        s += "<div class=\"card\">";
            s += "<a class=\"featured-link\" href=\"" + cms.link(uri) + "\">";
                s += "<div class=\"autonomous\">";
                    s += "<h3 class=\"portal-box-heading overlay\" style=\"font-size:1.3em;\"><span>" + title + "</span></h3>";
                    s += "<img src=\"";
                    try {
                        /*CmsImageScaler imageOri = new CmsImageScaler(cmso, cmso.readResource(imageUri));
                        CmsImageScaler imageScaler = imageOri.getReScaler(new CmsImageScaler("w:320,t:4,q:100"));
                        String src = (String)CmsAgent.getTagAttributesAsMap(cms.img(imageUri, imageScaler, null, false)).get("src");
                        s += src;*/
                        s += getScaledImgSrc(imageUri, 320, cms);
                    } catch (Exception e) {
                        s += imageUri;
                    }
                    s += "\" alt=\"" + "\" />";
                s += "</div>";
            s += "</a>";
            s += "<div class=\"box-text\">";
                if (descr != null && !descr.isEmpty())
                    s += descr;
            s += "</div>";
        s += "</div>";
        return s;
    }
    
    
}

public String getScaledImgSrc(String imageUri, int scaledWidth, CmsAgent cms) throws CmsException {
    CmsObject cmso = cms.getCmsObject();
    CmsImageScaler imageOri = new CmsImageScaler(cmso, cmso.readResource(imageUri));
    CmsImageScaler imageScaler = imageOri.getReScaler(new CmsImageScaler("w:" + scaledWidth + ",t:4,q:100"));
    return (String)CmsAgent.getTagAttributesAsMap(cms.img(imageUri, imageScaler, null, false)).get("src");
}

/**
 * Converts a JSON array to a String array, swapping DB values with "nice" values.
 */
public String[] jsonArrayToStringArray(JSONArray a) {
    String[] sa = new String[a.length()];
    for (int i = 0; i < a.length(); i++) {
        try { sa[i] = swapJsonValueWithNiceValue(a.getString(i)); } catch (Exception e) { sa[i] = ""; }
    }
    return sa;
}

/**
 * Converts a comma-separated list (one string) to a list of strings, swapping DB values with "nice" values.
 */
public List<String> csvStringToList(String s, String delimiter) {
    if (delimiter == null)
        delimiter = ",";
    List<String> list = Arrays.asList(s.split(","));
    Iterator<String> iList = list.iterator();
    while (iList.hasNext()) {
        String li = iList.next();
        try { li = swapJsonValueWithNiceValue(li.trim()); } catch (Exception e) { li = ""; }
    }
    
    return list;
}

/**
 * Converts a list to a comma separated string.
 */
public String listToString(List list, boolean swapValues) {
    return listToString(list, swapValues, ", ");
}

/**
 * Converts a list to a string, each item in the list separated by the given separator.
 */
public String listToString(List list, boolean swapValues, String separator) {
    Iterator i = list.iterator();
    String s = "";
    while (i.hasNext()) {
        try { 
            //s += swapValues ? swapJsonValueWithNiceValue((String)i.next()) : i.next(); 
            s += swapValues ? swapJsonValueWithNiceValue(i.next().toString()) : i.next(); 
        } catch (Exception e) {
            /*try {
                s += swapValues ? swapJsonValueWithNiceValue( : i.next();
            } catch (Exception ee) {
                
            }*/
        }
        if (i.hasNext()) 
            s += separator;
    }
    return s;
}

/** 
 * Swap the DB value with the "nice" value.
 */
public String swapJsonValueWithNiceValue(String dbValue) {
    String s = valueMappings.get(dbValue);
    if (s != null && !s.isEmpty())
        return s;
    return dbValue;
}

/**
 * Gets the current symbol (used in affiliation lists).
 */
public String getCurrentInstSymbol() {
    String symbol = Integer.toString(symbolsGenerated);
    /*
    String symbol = "";
    try {
        int symbolIndex = (symbolsGenerated + symbols.length) % symbols.length;
        int repeat = 1 + symbolsGenerated / symbols.length;
        for (int j = 0; j < repeat; j++)
            symbol += symbols[symbolIndex];
        symbolsGenerated++;
    } catch (ArrayIndexOutOfBoundsException aioobe) {
        // whut WHUT???
    }
    */
    return symbol;
}

/**
 * Gets the next symbol (used in affiliation lists).
 */
public String getNextInstSymbol() {
    String symbol = Integer.toString(++symbolsGenerated);
    /*
    String symbol = "";
    try {
        int symbolIndex = (symbolsGenerated + symbols.length) % symbols.length;
        int repeat = 1 + symbolsGenerated / symbols.length;
        for (int j = 0; j < repeat; j++)
            symbol += symbols[symbolIndex];
        symbolsGenerated++;
    } catch (ArrayIndexOutOfBoundsException aioobe) {
        // whut WHUT???
    }
    */
    return symbol;
}

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
 * Gets an error message as normalized HTML.
 */
public String error(String msg) {
    String s = "<article class=\"main-content\">";
    s += "<h1>Error</h1>";
    s += "<div class=\"ingress\"><p class=\"error\">" + msg + "</p></div>";
    s += "</article>";
    
    return s;
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

public String getSectionClass(int size) {
    String[] classes = new String[] { "", "single", "double", "triple", "quadruple" };
    if (size <= 4)
        return classes[size];
    else {
        if (size % 4 == 0) return classes[4];
        if (size % 3 == 0) return classes[3];
        if (size % 2 == 0) return classes[2];
    }
    return classes[1];
}
%><%
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();
CmsLinkManager lm       = OpenCms.getLinkManager();
String projectFilePath  = null;

// Common page element handlers
final String PARAGRAPH_HANDLER = "/system/modules/no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final String PUB_LIST = "/system/modules/no.npolar.common.project/elements/project-publications-full-list.jsp";
final String DATASETS_LIST = "/system/modules/no.npolar.common.project/elements/project-datasets.jsp";
final String PROJECTS_FOLDER = loc.equalsIgnoreCase("no") ? "/no/prosjekter/" : "/en/projects/";
final int TYPE_ID_PROJECT = OpenCms.getResourceManager().getResourceType("np_project").getTypeId();

final boolean EDITABLE = false;
final boolean T_EDIT = false;
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Template ("outer" or "master" template)
final String T = cms.getTemplate();
final String[] T_ELEM = cms.getTemplateIncludeElements();

String pid = cms.getRequest().getParameter("pid");
if (pid == null || pid.isEmpty()) {
    // crash
    //throw new NullPointerException("A project ID is required in order to view a project's details.");
    // Important: Set the title before calling the template
    request.setAttribute("title", "Error");
    cms.include(T, T_ELEM[0], T_EDIT);
    out.println(error("A project ID is required in order to view a project's details."));
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
}

try {
    //out.println("<!-- request uri is " + requestFileUri + ", JSP is " + cms.info("opencms.uri") + " -->");
    //out.println("<!-- " + OpenCms.getSystemInfo().getOpenCmsContext() + " -->");
    CmsResource projectResource = cmso.readResourcesWithProperty(PROJECTS_FOLDER, "api-id", pid, CmsResourceFilter.DEFAULT_FILES.addRequireType(TYPE_ID_PROJECT)).get(0);
    projectFilePath = cmso.getSitePath(projectResource);
    
    
    // Ensure canonical URL for projects that have files in the CMS:
    // If the requested resource's URI is this JSP (e.g. /en/projects/details?pid=...)
    // AND a project file exists in the CMS, redirect to that project file
    if (requestFileUri.endsWith( cms.info("opencms.uri").replace(OpenCms.getSystemInfo().getOpenCmsContext(), "") )) {
        //String redirectTargetPath = detailPageUri + "?pid=" + projectId;// e.g. "/en/" to redirect to the localized english folder
        String redirAbsPath = request.getScheme() + "://" + request.getServerName() + projectFilePath;
        //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
        cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
        return;
    }
} catch (Exception ignore) {}

// Service details
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PORT = "80";
//final String SERVICE_DOMAIN_NAME = "apptest.data.npolar.no";
//final String SERVICE_PORT = "9000";
final String SERVICE_PATH = "/project/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;
// Construct the service URL to look up for this particular project
String serviceUrl = SERVICE_BASE_URL + pid + ".json";
String humanUrl = (SERVICE_BASE_URL + pid).replace("//api.", "//data.");

// Test service 
// ToDo: Use a servlet context variable instead of a helper file in the e-mail routine.
//       Also, the error message should be moved to workplace.properies or something
//       The whole "test the API availability" procedure should also be moved to a central location.
int responseCode = 0;
final String ERROR_MSG_NO_SERVICE = loc.equalsIgnoreCase("no") ?  
        ("<h1>Prosjektdetaljer</h1>"
            + "<h2>Vel, dette skulle ikke skje&nbsp;&hellip;</h2>"
            + "<p>Sideinnholdet som skulle vært her kan dessverre ikke vises akkurat nå, på grunn av en midlertidig feil.</p>"
            + "<p>Vi liker heller ikke dette, og håper å ha alt i orden igjen snart.</p>"
            + "<p>Prøv gjerne å laste inn siden på nytt om litt.</p>"
            + "<p style=\"font-style:italic;\">Skulle feilen vedvare, setter vi pris på det om du tar deg tid til å <a href=\"mailto:web@npolar.no\">sende oss en kort notis om dette</a>.")
        :
        ("<h1>Project details</h1>"
            + "<h2>Well this shouldn't happen&nbsp;&hellip;</h2>"
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
        request.setAttribute("title", "Error");
        cms.include(T, T_ELEM[0], T_EDIT);
        out.println("<div class=\"error\">" + ERROR_MSG_NO_SERVICE + "</div>");
        cms.include(T, T_ELEM[1], T_EDIT);
        
        
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
                        + "\n\nThis notification was generated because the data centre couldn't be reached, or didn't respond with \"200 OK\"."
                        + "\n\nGenerated by OpenCms: " + cms.info("opencms.uri") + " - with a timeout of " + errorNotificationTimeout/(1000*60*60) + " hour(s).");
                errorMail.send();
            }
        } catch (Exception e) { 
            out.println("\n<!-- \nError sending error notification: " + e.getMessage() + " \n-->");
        }
        
        return;
    }
}


// Request the .json feed from the service
String jsonFeed = null;
try {
    jsonFeed = httpResponseAsString(serviceUrl);
} catch (Exception e) {
    // Important: Set the title before calling the template
    request.setAttribute("title", "Error");
    
    cms.include(T, T_ELEM[0], T_EDIT);    
    //out.println("<article class=\"main-content\">");
    //out.println(error("An unexpected error occured while constructing the project details."));
    out.println("<div class=\"paragraph\">");
    if (loc.equalsIgnoreCase("no")) {
        out.println("<h1>Feil</h1>");
        out.println("<p>En feil oppsto ved uthenting av prosjektdetaljene. Vennligst prøv å oppdater siden, eller kom tilbake senere.</p><p>Skulle problemet vedvare, er det fint om du kan <a href=\"mailto:web@npolar.no\">gi oss beskjed</a>.</p>");
    } else {
        out.println("<h1>Error</h1>");
        out.println("<p>An error occured while fetching the projects details. Please try refreshing the page, or come back later.</p><p>Should you continue to see this error message over time, we would very much appreciate <a href=\"mailto:web@npolar.no\">a notification from you</a>.</p>");
    }
    out.println("</div>");
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
    //out.println("</article>");
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
}

// Don't print text (summary, abstract) fetched from the project entry? (Typically used only when overriding with content from OpenCms)
boolean suppressApiText = false;
String ocmsTitle = null;
String ocmsTitleAbbrev = null;
String ocmsDescr = null;
String ocmsLogo = null;
String ocmsImage = null;
String autoPubsStr = null;
boolean autoPubs = false;
String datasetsUri = null;

String moreUri = projectFilePath;//requestFolderUri + "" + pid + ".html";
if (cmso.existsResource(moreUri)) {
    // An OpenCms file exists for this project: check for special settings
    I_CmsXmlContentContainer container = cms.contentload("singleFile", moreUri, EDITABLE);
    while (container.hasMoreContent()) {
        ocmsTitle = cms.contentshow(container, "Title");
        ocmsTitleAbbrev = cms.contentshow(container, "AbbrevTitle");
        suppressApiText = Boolean.valueOf(cms.contentshow(container, "SuppressAPIText")).booleanValue();
        ocmsLogo = cms.contentshow(container, "Logo");
        if (!CmsAgent.elementExists(ocmsLogo))
            ocmsLogo = null;
        if (suppressApiText) {
            ocmsDescr = cms.contentshow(container, "Description");
        }
        
        //
        // Auto-publications
        //
        autoPubsStr = cms.contentshow(container, "AutoPubs");
        autoPubs    = Boolean.valueOf(autoPubsStr).booleanValue(); // Default is false
        datasetsUri = cms.contentshow(container, "DatasetsURI");
    }
}


try {
JSONObject p = new JSONObject(jsonFeed);

// JSON keys (and date format)
final String JSON_KEY_WORKSPACE     = "workspace";
final String JSON_KEY_WEBSITE_FLAG  = "website";
final String JSON_KEY_TITLE         = "title";
final String JSON_KEY_ABBREV_TITLE  = "acronym";
final String JSON_KEY_DESCRIPTION   = "summary";
final String JSON_KEY_ABSTRACT      = "abstract";
final String JSON_KEY_NPI_ID        = "np_project_number";
final String JSON_KEY_RIS_ID        = "ris_id";
final String JSON_KEY_KEYWORDS      = "keywords";
final String JSON_KEY_LOGO          = "logo_image_url";
final String JSON_KEY_FEATURED_IMAGE= "featured_image_url";
final String JSON_KEY_BEGIN         = "start_date";
final String JSON_KEY_END           = "end_date";
final String JSON_KEY_TYPE          = "type";
final String JSON_KEY_GEO_AREA      = "geo_area";
final String JSON_KEY_PLACENAMES    = "placenames";
final String JSON_KEY_PLACENAME     = "placename";
final String JSON_KEY_AREA          = "area";
final String JSON_KEY_WEBSITE       = "project_url";
final String JSON_KEY_PEOPLE        = "people";
final String JSON_KEY_LEADERS       = "project_leaders";
final String JSON_KEY_PERSON_FNAME  = "first_name";
final String JSON_KEY_PERSON_LNAME  = "last_name";
final String JSON_KEY_PERSON_URI    = "url";
final String JSON_KEY_PERSON_EMAIL  = "email";
final String JSON_KEY_PERSON_AFFIL  = "affiliation";
final String JSON_KEY_ROLE          = "role";
final String JSON_KEY_ORG           = "org";
final String JSON_KEY_NAME          = "name";
final String JSON_KEY_ORGANISATION  = "organisation";
final String JSON_KEY_ORGANISATIONS = "organisations";
final String JSON_KEY_PERSON_INST   = "institution";
final String JSON_KEY_PARTICIPANTS  = "project_participants";
final String JSON_KEY_PARTNER       = "contract_partners";
final String JSON_KEY_TOPICS        = "topics";
final String JSON_KEY_AFFIL_ICE     = "affiliated_ICE";
final String JSON_KEY_RES_PROG      = "research_programs";
final String JSON_KEY_RES_PROG_TITLE= "title";
final String JSON_KEY_RES_PROG_URI  = "href";
final String JSON_KEY_TRANSLATIONS  = "translations";

final String JSON_ENUM_VAL_PROJECT_LEADER = "projectLeader";

// Date formats
//final SimpleDateFormat DATE_FORMAT_JSON = new SimpleDateFormat("yyyy-dd-MM");
final SimpleDateFormat DATE_FORMAT_JSON = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
final SimpleDateFormat DATE_FORMAT_SCREEN = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM yyyy" : "d MMMM yyyy", locale);

final String LABEL_PLANNED = loc.equalsIgnoreCase("no") ? "Planlagt" : "Planned";
final String LABEL_ACTIVE = loc.equalsIgnoreCase("no") ? "Aktivt" : "Active";
final String LABEL_COMPLETED = loc.equalsIgnoreCase("no") ? "Fullført" : "Completed";
final String LABEL_TYPE = loc.equalsIgnoreCase("no") ? "Type" : "Type";
final String LABEL_TYPES = loc.equalsIgnoreCase("no") ? "Typer" : "Types";
final String LABEL_AREA = loc.equalsIgnoreCase("no") ? "Område" : "Area";
final String LABEL_AREAS = loc.equalsIgnoreCase("no") ? "Områder" : "Areas";
final String LABEL_TOPIC = loc.equalsIgnoreCase("no") ? "Emne" : "Topic";
final String LABEL_TOPICS = loc.equalsIgnoreCase("no") ? "Emner" : "Topics";
final String LABEL_PROGRAMME = loc.equalsIgnoreCase("no") ? "Program" : "Programme";
final String LABEL_PROGRAMMES = loc.equalsIgnoreCase("no") ? "Programmer" : "Programmes";
final String LABEL_LEADER = loc.equalsIgnoreCase("no") ? "Leder" : "Leader";
final String LABEL_LEADERS = loc.equalsIgnoreCase("no") ? "Ledere" : "Leaders";
final String LABEL_PROJECT_LEADER = loc.equalsIgnoreCase("no") ? "Prosjektleder" : "Project leader";
final String LABEL_PARTICIPANT = loc.equalsIgnoreCase("no") ? "Deltaker" : "Participant";
final String LABEL_PARTICIPANTS = loc.equalsIgnoreCase("no") ? "Deltakere" : "Participants";
final String LABEL_PARTNER = loc.equalsIgnoreCase("no") ? "Partner" : "Partner";
final String LABEL_PARTNERS = loc.equalsIgnoreCase("no") ? "Partnere" : "Partners";
final String LABEL_NO_DESCR = loc.equalsIgnoreCase("no") ? "Ingen beskrivelse tilgjengelig på nåværende tidspunkt." : "No description available at this time.";
// Topics
final String LABEL_ATMOSPHERE = loc.equalsIgnoreCase("no") ? "Atmosfære" : "Atmosphere";
final String LABEL_BIODIVERSITY = loc.equalsIgnoreCase("no") ? "Biologisk mangfold" : "Biodiversity";
final String LABEL_BIOLOGY = loc.equalsIgnoreCase("no") ? "Biologi" : "Biology";
final String LABEL_CHEMISTRY = loc.equalsIgnoreCase("no") ? "Kjemi" : "Chemistry";
final String LABEL_CLIMATE = loc.equalsIgnoreCase("no") ? "Klima" : "Climate";
final String LABEL_ECOLOGY = loc.equalsIgnoreCase("no") ? "Økologi" : "Ecology";
final String LABEL_ECOTOXICOLOGY = loc.equalsIgnoreCase("no") ? "Økotoksikologi" : "Ecotoxicology";
final String LABEL_GEOLOGY = loc.equalsIgnoreCase("no") ? "Geologi" : "Geology";
final String LABEL_GLACIERS = loc.equalsIgnoreCase("no") ? "Glasiologi" : "Glaciology";
final String LABEL_MARINE = loc.equalsIgnoreCase("no") ? "Marine" : "Marine";
final String LABEL_MARINE_ECOSYSTEMS = loc.equalsIgnoreCase("no") ? "Marine økosystemer" : "Marine ecosystems";
final String LABEL_MAPS = loc.equalsIgnoreCase("no") ? "Kart" : "Maps";
final String LABEL_OCEANOGRAPHY = loc.equalsIgnoreCase("no") ? "Oseanografi" : "Oceanography";
final String LABEL_OTHER = loc.equalsIgnoreCase("no") ? "Annet" : "Other";
final String LABEL_REMOTE_SENSING = loc.equalsIgnoreCase("no") ? "Fjernmåling" : "Remote sensing";
final String LABEL_SEA_ICE = loc.equalsIgnoreCase("no") ? "Havis" : "Sea ice";
final String LABEL_TERRESTRIAL = loc.equalsIgnoreCase("no") ? "Terrestrisk" : "Terrestrial";
final String LABEL_TOPOGRAPHY = loc.equalsIgnoreCase("no") ? "Topografi" : "Topography";
final String LABEL_VEGETATION = loc.equalsIgnoreCase("no") ? "Vegetasjon" : "Vegetation";
//final String LABEL_ENVIRONMENTAL_POLLUTANTS = loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Envoronmental pollutants";
// Areas
final String LABEL_ARCTIC = loc.equalsIgnoreCase("no") ? "Arktis" : "Arctic";
final String LABEL_ANTARCTIC = loc.equalsIgnoreCase("no") ? "Antarktis" : "Antarctic";
// Type
final String LABEL_MAPPING = loc.equalsIgnoreCase("no") ? "Kartlegging" : "Mapping";
final String LABEL_MODELLING = loc.equalsIgnoreCase("no") ? "Modellering" : "Modelling";
final String LABEL_MONITORING = loc.equalsIgnoreCase("no") ? "Overvåking" : "Monitoring";
final String LABEL_RESEARCH = loc.equalsIgnoreCase("no") ? "Forskning" : "Research";
// Some names
final String LABEL_FRAM_CENTRE_FLAGSHIP = loc.equalsIgnoreCase("no") ? "FRAM flaggskip" : "Fram Centre flagship";
final String LABEL_ICE = loc.equalsIgnoreCase("no") ? "ICE" : "ICE";
final String LABEL_NORKLIMA = loc.equalsIgnoreCase("no") ? "NORKLIMA" : "NORKLIMA";

// Misc
final int STATE_PLANNED = 0;
final int STATE_ACTIVE = 1;
final int STATE_COMPLETED = 2;
final String[] STATES = { LABEL_PLANNED, LABEL_ACTIVE, LABEL_COMPLETED };
final Date NOW = new Date();

//
// Mappings for DB values (used in the JSON) and "nice" values (used on-screen)
//
valueMappings.put("atmosphere", LABEL_ATMOSPHERE);
valueMappings.put("biodiversity", LABEL_BIODIVERSITY);
valueMappings.put("biology", LABEL_BIOLOGY);
valueMappings.put("chemistry", LABEL_CHEMISTRY);
valueMappings.put("climate", LABEL_CLIMATE);
valueMappings.put("ecology", LABEL_ECOLOGY);
valueMappings.put("ecotoxicology", LABEL_ECOTOXICOLOGY);
valueMappings.put("geology", LABEL_GEOLOGY);
valueMappings.put("glaciology", LABEL_GLACIERS);
valueMappings.put("marine", LABEL_MARINE);
valueMappings.put("marine ecosystems", LABEL_MARINE_ECOSYSTEMS);
valueMappings.put("maps", LABEL_MAPS);
valueMappings.put("oceanography", LABEL_OCEANOGRAPHY);
valueMappings.put("other", LABEL_OTHER);
valueMappings.put("remote-sensing", LABEL_REMOTE_SENSING);
valueMappings.put("seaice", LABEL_SEA_ICE);
valueMappings.put("terrestrial", LABEL_TERRESTRIAL);
valueMappings.put("topography", LABEL_TOPOGRAPHY);
valueMappings.put("vegetation", LABEL_VEGETATION);
//valueMappings.put("environmental pollutants", LABEL_ENVIRONMENTAL_POLLUTANTS);

valueMappings.put("arctic", LABEL_ARCTIC);
valueMappings.put("antarctic", LABEL_ANTARCTIC);

valueMappings.put("Monitoring", LABEL_MONITORING);
valueMappings.put("Research", LABEL_RESEARCH);
valueMappings.put("Modeling", LABEL_MODELLING);
valueMappings.put("Mapping", LABEL_MAPPING);

valueMappings.put("fram centre flagship", LABEL_FRAM_CENTRE_FLAGSHIP);
valueMappings.put("ice", LABEL_ICE);
valueMappings.put("norklima", LABEL_NORKLIMA);

valueMappings.put("projectLeader", LABEL_PROJECT_LEADER);

// This one is really not a DB value mapping, but hey let's be a bit lazy...
valueMappings.put("no", "nb");
// Done with DB value mappings

//
// Variables used for project details
//
String title            = "";
String titleAbbrev      = "";
//String area             = null;
boolean featured        = false;
String npiId            = "";
String risId            = "";
String keywords         = "";
String websiteTitle     = "";
String websiteUri       = "";
Date dateBegins         = null;
Date dateEnds           = null;
String timeDisplay      = "";
String programmeTitle   = "";
String programmeUri     = "";
String status           = "";
String personTitle      = "";
String personUri        = "";
String personFirstName  = "";
String personLastName   = "";
String participantTitle = "";
String participantUri   = "";
String logoUri          = "";
String imageUri         = "";
String imageAlt         = "";
String imageCaption     = "";
String imageSource      = "";
String imageType        = "";
String imageSize        = "";
String imageFloat       = "";
String description      = "";
String abstr            = "";
String type             = "";
String topics           = "";
//String programme        = null;
List<Person> leaders    = new ArrayList<Person>();
List<Person> participants = new ArrayList<Person>();
List<OptLink> programmes = new ArrayList<OptLink>();
List<SubProject> subProjects = new ArrayList<SubProject>();
List<OptLink> placenames = new ArrayList<OptLink>();
List<OptLink> partners  = new ArrayList<OptLink>();
Map<String, String>translations = new HashMap<String, String>();




//
// Read the rest of the details from the .json
//
try { title = p.getString(JSON_KEY_TITLE); } catch (Exception e) { title = "Unknown title"; }
try { titleAbbrev = p.getString(JSON_KEY_ABBREV_TITLE); } catch (Exception e) { }
try { npiId = p.getString(JSON_KEY_NPI_ID); } catch (Exception e) { }
try { risId = p.getString(JSON_KEY_RIS_ID); } catch (Exception e) { }
//try { keywords = p.getString(JSON_KEY_KEYWORDS); } catch (Exception e) { }
if (!suppressApiText) {
    try { description = p.getString(JSON_KEY_DESCRIPTION); } catch (Exception e) { }
    try { abstr = p.getString(JSON_KEY_ABSTRACT); } catch (Exception e) { }
}

//try { area = listToString(Arrays.asList(jsonArrayToStringArray(p.getJSONArray(JSON_KEY_GEO_AREA)))); } catch (Exception e) { }
try { keywords = listToString(Arrays.asList(jsonArrayToStringArray(p.getJSONArray(JSON_KEY_KEYWORDS))), false); } catch (Exception e) { }
//try { type = listToString(Arrays.asList(jsonArrayToStringArray(p.getJSONArray(JSON_KEY_TYPE))), true); } catch (Exception e) { }
try { type = listToString(csvStringToList(p.getString(JSON_KEY_TYPE), null), true); } catch (Exception e) { }
try { topics = listToString(Arrays.asList(jsonArrayToStringArray(p.getJSONArray(JSON_KEY_TOPICS))), true); } catch (Exception e) { }



try {
    dateBegins = DATE_FORMAT_JSON.parse(p.getString(JSON_KEY_BEGIN));
} catch (Exception e) {}

try {
    dateEnds = DATE_FORMAT_JSON.parse(p.getString(JSON_KEY_END));
} catch (Exception e) {}


try {
    JSONArray placenamesArr = p.getJSONArray(JSON_KEY_PLACENAMES);
    for (int i = 0; i < placenamesArr.length(); i++) {
        JSONObject placenameObj = placenamesArr.getJSONObject(i);
        String placename = "";
        String area = "";
        try { placename = placenameObj.getString(JSON_KEY_PLACENAME); } catch (Exception e) {  }
        try { area = placenameObj.getString(JSON_KEY_AREA); } catch (Exception e) {  }
        placenames.add(new OptLink("" + placename + (placename.isEmpty() ? "" : ", ") + area));
    }
} catch (Exception e) {
    
}

try {
    JSONArray peopleArr = p.getJSONArray(JSON_KEY_PEOPLE);
    for (int i = 0; i < peopleArr.length(); i++) {
        JSONObject personObj = peopleArr.getJSONObject(i);
        Person person = new Person(personObj.getString(JSON_KEY_PERSON_FNAME), personObj.getString(JSON_KEY_PERSON_LNAME));
        try { 
            //String inst = personObj.getJSONObject(JSON_KEY_PERSON_AFFIL).getString(JSON_KEY_ORG);
            String inst = personObj.getString(JSON_KEY_ORGANISATION);
            if (!inst.isEmpty()) {
                String symbol = "";
                if (!symbolMappings.containsValue(inst)) {
                    symbol = getNextInstSymbol();
                    symbolMappings.put(symbol, inst);
                } else {
                    symbol = getCurrentInstSymbol();
                }
                person.setInstitutionSymbol(symbol);
                person.setInstitution(inst);
                /*
                person.setInstitution(inst);
                if (symbolMappings.get(inst) == null) {
                    symbolMappings.put(inst, getNextInstSymbol());
                }
                */
            }
        } catch (Exception e) {  }
        try { person.setUri(personObj.getString(JSON_KEY_PERSON_URI)); } catch (Exception e) {  }
        String role = "";
        try { role = personObj.getString(JSON_KEY_ROLE); } catch (Exception e) {}
        if (role.equals(JSON_ENUM_VAL_PROJECT_LEADER))
            leaders.add(person);
        else 
            participants.add(person);
    }
} catch (Exception e) {}

try {
    JSONArray organisationsArr = p.getJSONArray(JSON_KEY_ORGANISATIONS);
    for (int i = 0; i < organisationsArr.length(); i++) {
        JSONObject organisationObj = organisationsArr.getJSONObject(i);
        String orgName = "";
        String orgRole = "";
        try { orgName = organisationObj.getString(JSON_KEY_NAME); } catch (Exception e) {  }
        try { orgRole = organisationObj.getString(JSON_KEY_ROLE); } catch (Exception e) {  }
        
        partners.add(new OptLink("" + orgName));// + (orgName.isEmpty() ? "" : ", ") + orgRole));
    }
} catch (Exception e) {}


// translations
if (!suppressApiText) {
    try {
        JSONObject translationsObj = p.getJSONObject(JSON_KEY_TRANSLATIONS).getJSONObject(swapJsonValueWithNiceValue(loc));
        try {
            description = translationsObj.getString(JSON_KEY_DESCRIPTION);
        } catch (Exception noValException) {}
        try {
            abstr = translationsObj.getString(JSON_KEY_ABSTRACT);
        } catch (Exception noValException) {}
    } catch (Exception e) {}
}

/*
try {
    JSONArray leadersArr = p.getJSONArray(JSON_KEY_LEADERS);
    for (int i = 0; i < leadersArr.length(); i++) {
        JSONObject leader = leadersArr.getJSONObject(i);
        Person person = new Person(leader.getString(JSON_KEY_PERSON_FNAME), leader.getString(JSON_KEY_PERSON_LNAME));
        try { 
            String inst = leader.getString(JSON_KEY_PERSON_INST);
            person.setInstitution(inst);
            if (symbolMappings.get(inst) == null) {
                symbolMappings.put(inst, getNextInstSymbol());
            }
        } catch (Exception e) {  }
        try { person.setUri(leader.getString(JSON_KEY_PERSON_URI)); } catch (Exception e) {  }
        leaders.add(person);
    }
} catch (Exception e) {}

try {
    JSONArray participantsArr = p.getJSONArray(JSON_KEY_PARTICIPANTS);
    for (int i = 0; i < participantsArr.length(); i++) {
        JSONObject participant = participantsArr.getJSONObject(i);
        Person person = new Person(participant.getString(JSON_KEY_PERSON_FNAME), participant.getString(JSON_KEY_PERSON_LNAME));
        try { 
            String inst = participant.getString(JSON_KEY_PERSON_INST);
            person.setInstitution(inst);
            if (symbolMappings.get(inst) == null) {
                symbolMappings.put(inst, getNextInstSymbol());
            }
        } catch (Exception e) {  }
        try { person.setUri(participant.getString(JSON_KEY_PERSON_URI)); } catch (Exception e) {  }
        participants.add(person);
    }
} catch (Exception e) {}
*/
try {
    JSONArray programmesArr = p.getJSONArray(JSON_KEY_RES_PROG);
    for (int i = 0; i < programmesArr.length(); i++) {
        JSONObject programme = programmesArr.getJSONObject(i);
        OptLink optLink = new OptLink(swapJsonValueWithNiceValue(programme.getString(JSON_KEY_RES_PROG_TITLE)));
        try { optLink.setUri(programme.getString(JSON_KEY_RES_PROG_URI)); } catch (Exception e) {  }
        programmes.add(optLink);
    }
} catch (Exception e) {}



// Remove duplicate organizations (both in "partners" and "affiliated institutions")
Iterator<String> iAffOrg = symbolMappings.keySet().iterator();
while (iAffOrg.hasNext()) {
    String _sym = iAffOrg.next();
    String _org = symbolMappings.get(_sym);
    
    Iterator<OptLink> iPartners = partners.iterator();
    while (iPartners.hasNext()) {
        OptLink _partner = iPartners.next();
        //out.println("<!-- duplicate evaluation: '" + _partner.getText() + "' vs. '" + _org.split(",")[0] + "' (" + (_partner.getText().startsWith(_org.split(",")[0])) + ") -->");
        if (_partner.getText().startsWith(_org.split(",")[0])) {
            iPartners.remove();
        }
    }
}
// Merge affiliate organizations with "partners" list
if (!symbolMappings.isEmpty()) {
    SortedSet<String> keys = new TreeSet<String>(symbolMappings.keySet());
    Iterator<String> iSymbolMappings = keys.iterator();
    int addAt = 0;
    while (iSymbolMappings.hasNext()) {
       String symbol = iSymbolMappings.next();
       String inst = symbolMappings.get(symbol);
       partners.add(addAt++, new OptLink("<strong>" + symbol + "</strong> " + inst));
    }
}

// -----------------------------------------------------------------------------
// Check for title overrides
//------------------------------------------------------------------------------
if (CmsAgent.elementExists(ocmsTitle)) {
    title = ocmsTitle;
}
if (CmsAgent.elementExists(ocmsTitleAbbrev)) {
    titleAbbrev = ocmsTitleAbbrev;
}


// -----------------------------------------------------------------------------
// Process markdown
//------------------------------------------------------------------------------
if (suppressApiText) {
    if (CmsAgent.elementExists(ocmsDescr)) {
        description = ocmsDescr;
    }
} else {
    //title = markdownToHtml(title);
    description = markdownToHtml(description);
    abstr = markdownToHtml(abstr);
}




// -----------------------------------------------------------------------------
// Print the project details
//------------------------------------------------------------------------------



// Template ("outer" or "master" template)
//String template             = cms.getTemplate();
//String[] elements           = cms.getTemplateIncludeElements();
// Important: Set the title before calling the template
request.setAttribute("title", title);
// Include upper part of main template
cms.include(T, T_ELEM[0], T_EDIT);

out.println("<!-- API URL: " + serviceUrl + " -->");
out.println("<!-- Project file URL: " + moreUri + " -->");

out.println("<article class=\"main-content\">");
out.println("<h1>" + title + (!titleAbbrev.isEmpty() ? " (" + titleAbbrev + ")" : "") + "</h1>");
if (description == null || description.isEmpty())
    description = "<em>" + LABEL_NO_DESCR + "</em>";

out.println("<div class=\"ingress\">" + description + "</div>");
//out.println("<div class=\"ingress\" style=\"margin-bottom:1em;\">" + description + "</div>");

//out.println("<div class=\"event-links nofloat\" style=\"padding-bottom:0.6em; margin:0 0 1rem 0; box-shadow:none; border:none;\">");
%>
<aside class="article-meta article-meta--padded clearfix">
<%

if (ocmsLogo != null) {
    out.println("<span class=\"media pull-right thumb\">"
                    + "<a href=\"" + ocmsLogo + "\">"
                        + "<img src=\"" + getScaledImgSrc(ocmsLogo, 320, cms) + "\" alt=\"" + (titleAbbrev.isEmpty() ? title : titleAbbrev) + "\" />"
                    + "</a>"
                + "</span>");
}

out.println("<div>");
if (dateBegins != null) {
    int state = STATE_ACTIVE;
    if (dateBegins.after(NOW))
        state = STATE_PLANNED;
    if (dateEnds != null && dateEnds.before(new Date()))
        state = STATE_COMPLETED;
    
    out.println("<strong>" + STATES[state] + ": </strong>" + DATE_FORMAT_SCREEN.format(dateBegins) + (dateEnds != null ? " &ndash; " + DATE_FORMAT_SCREEN.format(dateEnds) : "") + "<br />");
}

//if (area != null) {
if (!placenames.isEmpty()) {
    String placenamesLabel = placenames.size() > 1 ? LABEL_AREAS : LABEL_AREA;
    out.println("<strong>" + placenamesLabel + ": </strong>" + listToString(placenames, false) + "<br />");
}
if (type != null) {
    String typesLabel = type.split(",").length > 1 ? LABEL_TYPES : LABEL_TYPE;
    out.println("<strong>" + typesLabel +": </strong>" + type + "<br />");
}


if (topics != null) {
    String topicsLabel = topics.split(",").length > 1 ? LABEL_TOPICS : LABEL_TOPIC;
    out.println("<strong>" + topicsLabel + ": </strong>" + topics + "<br />");
}
if (!programmes.isEmpty()) {
    String programmesLabel = programmes.size() > 1 ? LABEL_PROGRAMMES : LABEL_PROGRAMME;
    out.print("<strong>" + programmesLabel + ": </strong>" + listToString(programmes, true) + "<br />");
}
if (!leaders.isEmpty()) {
    String leadersLabel = leaders.size() > 1 ? LABEL_LEADERS : LABEL_LEADER;
    out.print("<strong>" + leadersLabel + ": </strong>" + listToString(leaders, false) + "<br />");
}
/*
if (!participants.isEmpty()) {
    String participantsLabel = participants.size() > 1 ? LABEL_PARTICIPANTS : LABEL_PARTICIPANT;
    out.print("<strong>" + participantsLabel + ": </strong>" + listToString(participants, false) + "<br />");
}
if (!partners.isEmpty()) {
    String partnersLabel = partners.size() > 1 ? LABEL_PARTNERS : LABEL_PARTNER;
    out.print("<strong>" + partnersLabel + ": </strong>" + listToString(partners, false) + "<br />");
}
*/


// NOTE: Participants were removed when link to DB was added (both research ICE leader and web people agreed)
if (!participants.isEmpty()) {
    String participantsLabel = participants.size() > 1 ? LABEL_PARTICIPANTS : LABEL_PARTICIPANT;
    //out.print("<strong>" + participantsLabel + ": </strong>" + listToString(participants, false) + "<br />");
    /*
    // This was the latest version in use
    out.println("<ul style=\"list-style:none; padding:0; margin:0;\">");
    out.println("<li style=\"display:inline-block;\"><strong>" + participantsLabel + ": </strong></li>");
    Iterator<Person> iParticipants = participants.iterator();
    while (iParticipants.hasNext()) {
        String participantStr = iParticipants.next().toString();
        out.println("<li style=\"display:inline-block;\">" + participantStr + (iParticipants.hasNext() ? ", " : "") + "</li>");
    }
    out.println("</ul>");
    //*/
    /*
    out.print("<strong>" + participantsLabel + ": </strong>" + "<br />");
    out.println("<ul style=\"list-style:none; padding:0; margin:0;\">");
    Iterator<Person> iParticipants = participants.iterator();
    while (iParticipants.hasNext()) {
        String participantStr = iParticipants.next().toString();
        out.println("<li>" + participantStr + "</li>");
    }
    out.println("</ul>");
    //*/
}
// NOTE: Partners were removed when link to DB was added (both research ICE leader and web people agreed)
if (!partners.isEmpty()) {
    String partnersLabel = partners.size() > 1 ? LABEL_PARTNERS : LABEL_PARTNER;
    //out.print("<strong>" + partnersLabel + ": </strong><br />" + listToString(partners, false, "<br />"));
    /*
    out.println("<strong>" + partnersLabel + ": </strong>");
    out.println("<ul style=\"list-style:none; padding:0; margin:0;\">");
    Iterator<OptLink> iPartners = partners.iterator();
    while (iPartners.hasNext()) {
        String partnerStr = iPartners.next().toString();
        out.println("<li>" + partnerStr + "</li>");
    }
    out.println("</ul>");
    //*/
    /*
    // This was the latest version in use:
    out.println("<ul style=\"list-style:none; padding:0; margin:0;\">");
    out.println("<li style=\"display:inline-block;\"><strong>" + partnersLabel + ": </strong></li>");
    Iterator<OptLink> iPartners = partners.iterator();
    while (iPartners.hasNext()) {
        String partnerStr = iPartners.next().toString();
        out.println("<li style=\"display:inline-block;\">" + partnerStr + (iPartners.hasNext() ? ", " : "") +"</li>");
    }
    out.println("</ul>");
    //*/
}
/*
if (!symbolMappings.isEmpty()) {
    out.println("<div class=\"project-institution\" style=\"color:#999;\">");
    SortedSet<String> keys = new TreeSet<String>(symbolMappings.keySet());
    Iterator<String> iSymbolMappings = keys.iterator();
    while (iSymbolMappings.hasNext()) {
       String symbol = iSymbolMappings.next();
       String inst = symbolMappings.get(symbol);
       out.println("<strong>" + symbol + "</strong> " + inst + (iSymbolMappings.hasNext() ? "<br />" : ""));
    }
    out.println("</div>");
}
*/
out.println("</div>");
out.println("<a href=\"" + humanUrl + "\">" 
                + (loc.equalsIgnoreCase("no") ? "Se alle detaljer og metadata for prosjektet" : "View all project details and metadata") 
            + "</a>");
//out.println("</div>");
%>
</aside>
<%
//
// Sub-projects?
//

if (!suppressApiText) {
    if (!abstr.isEmpty()) {
        out.println("<div class=\"paragraph\">");
        String html = abstr;
        try { html = new Markdown4jProcessor().process(html); } catch (Exception e) { }
        out.println(html);
        out.println("</div>");
    }
}
//out.print(projectJson.toString(4));


    
if (autoPubs || CmsAgent.elementExists(datasetsUri)) {
    %>
    <div id="auto-pubs-datasets" class="async-content" style="margin-bottom: 1em;">
    <%
    Map params = new HashMap();
    params.put("locale", loc);
    
    if (autoPubs) {
        params.put("id", pid);
        
        out.println("<h2 class=\"toggler\">" + cms.labelUnicode("label.np.list.publications.heading") + "</h2>");
        out.println("<div class=\"toggleable\" id=\"publications-loader\"></div>");
        //out.println("<div id=\"publications-loader\"></div>");
    }
    if (CmsAgent.elementExists(datasetsUri)) {
        params.put("uri", datasetsUri);
        out.println("<h2 class=\"toggler\">" + cms.labelUnicode("label.np.list.datasets.heading") + "</h2>");
        out.println("<div class=\"toggleable\" id=\"datasets-loader\"></div>");
        //out.println("<div id=\"datasets-loader\"></div>");
    }
    

    %>
    <script type="text/javascript">
        $('#publications-loader').load('<%= cms.link(CmsRequestUtil.appendParameters(PUB_LIST, params, true)) %>', function( response, status, xhr ) {
            if ( status === "error" ) {
                var msg = "<%= cms.labelUnicode("label.np.list.publications.error") %>";//"Sorry, an error occurred while looking for publications: ";
                $( "#publications-loader" ).html( msg + " (" + xhr.status + " " + xhr.statusText + ")" );
            } else {
                //initToggleable( $('#project__publications') );
                //initToggleablesInside( $('#auto-pubs-datasets') );
            }
        });
        $('#datasets-loader').load('<%= cms.link(CmsRequestUtil.appendParameters(DATASETS_LIST, params, true)) %>', function( response, status, xhr ) {
            if ( status === "error" ) {
                var msg = "<%= cms.labelUnicode("label.np.list.datasets.error") %>";
                $( "#datasets-loader" ).html( msg + " (" + xhr.status + " " + xhr.statusText + ")" );
            }
        });
        //initToggleablesInside( $('#auto-pubs-datasets') );
    </script>
    </div>
    <%
}   // ToDo: Add <noscript> with link to full list of pubs (in the NPDC)


//
// Rich text, fetched from the CMS
//

if (cmso.existsResource(moreUri)) {
    I_CmsXmlContentContainer container = cms.contentload("singleFile", moreUri, EDITABLE);
    
    //
    // ToDo: Replace with service-fetched data
    //
    try {
        out.println("<!-- checking for sub-projects ... -->");
        subProjects = getSubProjectList(cms, container);
        out.println("<!-- " + subProjects.size() + " sub-projects found -->");
        if (!subProjects.isEmpty()) {
            List<SubProject> subProjectsFirst = new ArrayList<SubProject>();
            if (subProjects.size() > 4) {
                if (subProjects.size() % 5 == 0) {
                    subProjectsFirst.addAll(subProjects.subList(0, 2)); // Extract first 2
                } else if (subProjects.size() == 7 || subProjects.size() == 11) {
                    subProjectsFirst.addAll(subProjects.subList(0, 3)); // Extract first 3
                }
                
                subProjects.removeAll(subProjectsFirst); // Remove any sub-projects added as "first row"
                
            }
            Iterator<SubProject> iSubProjects = subProjects.iterator();
            
            out.println("<div class=\"portal toggleable collapsed\" style=\"width:100%; margin:-1rem 0 1.4em 0; float:none;\">");
            //out.println("<a name=\"subprojects\" id=\"subprojects\"></a>");
            out.println("<a class=\"toggletrigger\" href=\"javascript:void(0);\">" + (loc.equalsIgnoreCase("no") ? "Underprosjekter" : "Sub-projects") + "</a>");
            out.println("<div class=\"toggletarget\">");
            
            // The next two if-clauses can be rewritten DRY, but no time now ...
            
            // First row
            if (!subProjectsFirst.isEmpty()) {
                Iterator<SubProject> iSubProjectsFirst = subProjectsFirst.iterator();
                out.println("<section class=\"clearfix " + getSectionClass(subProjectsFirst.size()) + " layout-group overlay-headings\">");
                    //out.println("<h3 class=\"section-heading bluebar-dark\">" + "Underprosjekter" + "</h3>");
                    out.println("<div class=\"boxes clearfix\">");
                    while (iSubProjectsFirst.hasNext()) {
                        out.println("<div class=\"span1 featured-box\">");
                        out.println(iSubProjectsFirst.next().getAsCard(cms));
                        out.println("</div>");
                    }
                    out.println("</div>");
                out.println("</section>");
            }
            // Consecutive rows
            if (!subProjects.isEmpty()) {
                out.println("<section class=\"clearfix " + getSectionClass(subProjects.size()) + " layout-group overlay-headings\">");
                    //if (subProjectsFirst.isEmpty())
                    //    out.println("<h3 class=\"section-heading bluebar-dark\">" + "Underprosjekter" + "</h3>");
                    out.println("<div class=\"boxes clearfix\">");
                    while (iSubProjects.hasNext()) {
                        out.println("<div class=\"span1 featured-box\">");
                        out.println(iSubProjects.next().getAsCard(cms));
                        out.println("</div>");
                    }
                    out.println("</div>");
                out.println("</section>");
            }
            
            out.println("</div>");
            out.println("</div>");
        } else {
            out.println("<!-- no sub-projects -->");
        }
    } catch (Exception e) {
        out.println("<!-- error listing sub-projects: " + e.getMessage() + " -->");
    }    
    
    container = cms.contentload("singleFile", moreUri, EDITABLE);
    
    request.setAttribute("paragraphContainer", container);
    cms.include(PARAGRAPH_HANDLER);
    
    
    I_CmsXmlContentContainer coop = cms.contentloop(container, "Cooperation");
    if (coop.hasMoreResources()) {
        String coopTitle = cms.contentshow(coop, "Title");
        String coopText = cms.contentshow(coop, "Text");
        coopTitle = CmsAgent.elementExists(coopTitle) ? ("<h2>".concat(coopTitle).concat("</h2>")) : "";
        coopText = CmsAgent.elementExists(coopText) ? ("<p>".concat(coopText).concat("</p>")) : "";
        
        I_CmsXmlContentContainer logos = cms.contentloop(coop, "Logo");
        StringBuilder logosHtml = new StringBuilder();
        while (logos.hasMoreResources()) {
            String logoImageUri = cms.contentshow(logos, "ImageURI");
            String logoImageAlt = cms.contentshow(logos, "AltText");
            String logoTargetUri = cms.contentshow(logos, "TargetURI");
            if (CmsAgent.elementExists(logoImageUri)) {
            // Decide the scale width based on the logo dimensions (ratio)
            String[] imageDims = cmso.readPropertyObject(logoImageUri, "image.size", false).getValue("w:1,h:1").split(",");
            // If the width is considerably larger than the height, call this a "landscape" image
            boolean isLandscape = Double.valueOf(imageDims[0].substring(2)) / Double.valueOf(imageDims[1].substring(2)) > 1.4; 
            int logoWidth = isLandscape ? 140 : 90; // same as the css max-widths => sharp images
            String logoImageHtml = ImageUtil.getImage(cms, logoImageUri, logoImageAlt, ImageUtil.CROP_RATIO_NO_CROP, logoWidth, 100, ImageUtil.SIZE_M, 100, null);
            logoImageHtml = logoImageHtml.contains(" class=\"") ? 
                                logoImageHtml.replace(" class=\"", " class=\"image--".concat(isLandscape ? "h " : "v ")) 
                                :
                                logoImageHtml.replace("<img ", "<img class=\"image--".concat(isLandscape ? "h" : "v").concat("\" ")); 

            logosHtml.append("<li>");
            logosHtml.append("<a href=\"" + logoTargetUri + "\" data-tooltip=\"" + logoImageAlt + "\">");
            logosHtml.append(logoImageHtml);
            logosHtml.append("<span class=\"bots-only\">" + logoImageAlt + "</span>");
            logosHtml.append("</a>");
            logosHtml.append("</li>");
            } else {
                out.println("<!-- ERROR: logo image missing: " + logoImageUri + " -->");
            }
        }
        if (!coopTitle.isEmpty() || !coopText.isEmpty() || !logosHtml.toString().isEmpty()) {
        %>
            <aside class="partners">
                    <%= coopTitle %>
                    <%= coopText %>
        <%
        if (!logosHtml.toString().isEmpty()) {
        %>
                <ul class="list--h">
                    <%= logosHtml.toString() %>
                </ul>
        <%
        }
        %>
            </aside>
        <%
        }
    }
}

} catch (Exception e) {
    //out.println(error("An unexpected error occured while constructing the project details."));
    out.println("<div class=\"paragraph\">");
    if (loc.equalsIgnoreCase("no")) {
        out.println("<h1>Feil</h1>");
        out.println("<p>En feil oppsto ved uthenting av prosjektdetaljene. Vennligst prøv å oppdater siden, eller kom tilbake senere.</p><p>Skulle problemet vedvare, er det fint om du kan <a href=\"mailto:web@npolar.no\">gi oss beskjed</a>.</p>");
    } else {
        out.println("<h1>Error</h1>");
        out.println("<p>An error occured while fetching the projects details. Please try refreshing the page, or come back later.</p><p>Should you continue to see this error message over time, we would very much appreciate <a href=\"mailto:web@npolar.no\">a notification from you</a>.</p>");
    }
    out.println("</div>");
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
}

out.println("</article>");


// Include lower part of main template
cms.include(T, T_ELEM[1], T_EDIT);

// Reset static variables
valueMappings.clear();
symbolMappings.clear();
symbolsGenerated = 0;
%>