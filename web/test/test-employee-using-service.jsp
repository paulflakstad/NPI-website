<%-- 
    Document   : test-employee-using-service
    Created on : Oct 8, 2013, 3:37:45 PM
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

public static Map<String, String> mappings = new HashMap<String, String>();
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

public String getImageUri(String id, CmsObject cmso) {
    String[] fileExt = { "jpg", "JPG", "jpeg", "JPEG", "gif", "GIF", "png", "PNG" };
    String imageName = "/images/people/".concat(id);
    for (String ext : fileExt) {
        String imageUri = imageName + "." + ext;
        if (cmso.existsResource(imageUri))
            return imageUri;
    }
    return "";
}

public String normalizePhoneNumber(String phoneNumber, CmsObject cmso) {
    Locale locale = cmso.getRequestContext().getLocale();
    String loc = locale.toString();
    if (!phoneNumber.isEmpty()) {
        if (phoneNumber.startsWith("+47")) {
            phoneNumber = phoneNumber.substring(3);
            if (!loc.equalsIgnoreCase("no"))
                phoneNumber = "+47 " + phoneNumber;
        }
        
    }
    return phoneNumber;
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
 * Converts a JSON array to a String array.
 */
public String[] jsonArrayToStringArray(JSONArray a) {
    String[] sa = new String[a.length()];
    for (int i = 0; i < a.length(); i++) {
        try { sa[i] = a.getString(i); } catch (Exception e) { sa[i] = ""; }
    }
    return sa;
}

public String getOrgTree(String orgTree) {
    // Convert the service-provided string (e.g. "/komm/info/") to a list (e.g. [comm][info])
    List orgTreeParts = new ArrayList<String>(Arrays.asList(orgTree.split("/")));
    // There may be empty entries, we need to remove them.
    Iterator<String> i = orgTreeParts.iterator();
    while (i.hasNext()) {
        String orgTreePart = i.next();
        if (orgTreePart.isEmpty())
            i.remove();
    }
    String s = "";
    // Convert the list to HTML code (unordered list)
    if (!orgTreeParts.isEmpty()) {
        s = listToHtmlList(orgTreeParts);
        s = s.replaceFirst("<ul>", "<ul class=\"person-affiliation\">");
    }
    return s;
}

public String listToHtmlList(List list) {
    if (list.isEmpty())
        return "";
    
    String s = "";
    Iterator<String> i = list.iterator();    
    s += "<ul><li>" + getMapping(i.next());
    if (i.hasNext()) {
        i.remove();
        s += listToHtmlList(list);
    }
    s += "</li></ul>";
    return s;
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

// Common page element handlers
final String PARAGRAPH_HANDLER = "/system/modules/no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final boolean EDITABLE = false;
final boolean T_EDIT = false;
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Template ("outer" or "master" template)
final String T = cms.getTemplate();
final String[] T_ELEM = cms.getTemplateIncludeElements();

// The image size for the profile image
final int IMG_SIZE = Integer.valueOf(cmso.readPropertyObject(requestFileUri, "image.size", true).getValue("150")).intValue();

String pid = CmsResource.getName(cms.getRequestContext().getFolderUri());
pid = pid.substring(0, pid.length()-1); // Remove trailing slash
if (pid == null || pid.isEmpty()) {
    // crash
    //throw new NullPointerException("A project ID is required in order to view a project's details.");
    // Important: Set the title before calling the template
    request.setAttribute("title", "Error");
    cms.include(T, T_ELEM[0], T_EDIT);
    out.println(error("An ID is required in order to view this page."));
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
}

// Service details
final String SERVICE_PROTOCOL = "http";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PORT = "80";
final String SERVICE_PATH = "/person/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;
// Construct the service URL to look up for this particular project
String serviceUrl = SERVICE_BASE_URL + pid + ".json";

// Request the .json feed from the service
String jsonFeed = null;
try {
    jsonFeed = httpResponseAsString(serviceUrl);
} catch (Exception e) {
    // Important: Set the title before calling the template
    request.setAttribute("title", "Error");
    
    cms.include(T, T_ELEM[0], T_EDIT);
    //out.println("<article class=\"main-content\">");
    out.println(error("An unexpected error occured while constructing the project details."));
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


try {
JSONObject p = new JSONObject(jsonFeed);

// JSON keys (and date format)
final String JSON_KEY_ID            = "_id";
final String JSON_KEY_ID_WEB        = "id";
final String JSON_KEY_POSITION      = "position";
final String JSON_KEY_EMPLOYMENT    = "employment";
final String JSON_KEY_ON_LEAVE      = "on_leave";
final String JSON_KEY_CURR_EMPLOYED = "currently_employed";
final String JSON_KEY_WORKPLACE     = "workplace";
final String JSON_KEY_PHONE         = "phone";
final String JSON_KEY_MOBILE        = "mobile";
final String JSON_KEY_EMAIL         = "email";
final String JSON_KEY_UPDATED       = "updated";
final String JSON_KEY_HON_PREFIX    = "honorific_prefix";
final String JSON_KEY_FNAME         = "first_name";
final String JSON_KEY_LNAME         = "last_name";
final String JSON_KEY_TITLE         = "title";
final String JSON_KEY_ORGTREE       = "orgtree";
final String JSON_KEY_LINKS         = "links";
final String JSON_KEY_LINK_HREF     = "href";
final String JSON_KEY_LINK_HREFLANG = "hreflang";
final String JSON_KEY_LINK_REL      = "rel";
final String JSON_KEY_LINK_TYPE     = "type";

// Date formats
final SimpleDateFormat DATE_FORMAT_JSON = new SimpleDateFormat("yyyy-dd-MM");
final SimpleDateFormat DATE_FORMAT_SCREEN = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM yyyy" : "d MMMM yyyy", locale);


final String PERSON_INDEX_URI   = loc.equals("no") ? "/no/ansatte/" : "/en/people/";
final String ICON_FOLDER        = "/images/icons/";
final String ICON_EMAIL         = "person-email.png";
final String ICON_PHONE         = "person-phone.png";
final String ICON_WORKPLACE     = "person-workplace.png";
final String ICON_ORG           = "person-org.png";

// Labels
final String LABEL_AFFILIATION          = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_ORG)) +"\" alt=\"" + cms.labelUnicode("label.Person.Affiliation") + "\" />";
final String LABEL_PHONE                = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_PHONE)) +"\" alt=\"" + cms.labelUnicode("label.Person.Phone") + "\" />";
final String LABEL_CELLPHONE            = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_PHONE)) +"\" alt=\"" + cms.labelUnicode("label.Person.Cellphone") + "\" />";
final String LABEL_EMAIL                = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_EMAIL)) +"\" alt=\"" + cms.labelUnicode("label.Person.Email") + "\" />";
final String LABEL_WORKPLACE            = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_WORKPLACE)) +"\" alt=\"" + cms.labelUnicode("label.Person.Workplace") + "\" />";
final String LABEL_CAREER               = cms.labelUnicode("label.Person.Career");
final String LABEL_ACTIVITIES           = cms.labelUnicode("label.Person.Activities");
final String LABEL_INTEREST_EXPERTISE   = cms.labelUnicode("label.Person.InterestsExpertise");
final String LABEL_BIBLIOGRAPHY         = cms.labelUnicode("label.Person.Bibliography");
final String LABEL_EMPLOYMENT_TYPE      = cms.labelUnicode("label.Person.EmploymentType");
final String LABEL_ON_LEAVE             = cms.labelUnicode("label.Person.OnLeave");
final String LABEL_CURRENTLY_EMPLOYED   = cms.labelUnicode("lable.Person.CurrentlyEmployed");

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
final String LABEL_ORG_RESEARCH_ECOTOX      = loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Environmental pollutants";
final String LABEL_ORG_RESEARCH_SUPPORT     = loc.equalsIgnoreCase("no") ? "Støtte" : "Support";
final String LABEL_ORG_ENVMAP               = loc.equalsIgnoreCase("no") ? "Miljø- og kart" : "Environment and mapping";
final String LABEL_ORG_ENVMAP_DATA          = loc.equalsIgnoreCase("no") ? "Miljødata" : "Environmental data";
final String LABEL_ORG_ENVMAP_MANAGEMENT    = loc.equalsIgnoreCase("no") ? "Miljøforvaltning" : "Environmental management";
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


//
// Variables used for employee details
//
String title        = "";
String id           = "";
String idWeb        = "";
String position     = "";
String workplace    = "";
String employment   = "";
boolean currEmployed= true;
Date lastUpdated    = null;
boolean onLeave     = false;
String phone        = "";
String mobile       = "";
String honPrefix    = "";
String email        = "";
String fname        = "";
String lname        = "";
String[] orgTrees   = null;
String imageUri     = "";
List<OptLink> links = new ArrayList<OptLink>();




//
// Read the rest of the details from the .json
//
try { title = p.getString(JSON_KEY_TITLE); } catch (Exception e) { title = "Unknown title"; }
try { id = p.getString(JSON_KEY_ID_WEB); } catch (Exception e) { }
try { position = p.getJSONObject(JSON_KEY_POSITION).getString(loc); } catch (Exception e) { }
try { workplace = p.getString(JSON_KEY_WORKPLACE); } catch (Exception e) { }
try { employment = p.getString(JSON_KEY_EMPLOYMENT); } catch (Exception e) { }
try { currEmployed = p.getBoolean(JSON_KEY_CURR_EMPLOYED); } catch (Exception e) { }
try { onLeave = p.getBoolean(JSON_KEY_ON_LEAVE); } catch (Exception e) { }
try { phone = p.getString(JSON_KEY_PHONE); } catch (Exception e) { }
try { mobile = p.getString(JSON_KEY_MOBILE); } catch (Exception e) { }
try { email = p.getString(JSON_KEY_EMAIL); } catch (Exception e) { }
try { honPrefix = p.getString(JSON_KEY_HON_PREFIX); } catch (Exception e) { }
try { fname = p.getString(JSON_KEY_FNAME); } catch (Exception e) { }
try { lname = p.getString(JSON_KEY_LNAME); } catch (Exception e) { }
try { orgTrees = jsonArrayToStringArray(p.getJSONArray(JSON_KEY_ORGTREE)); } catch (Exception e) { }
try { lastUpdated = DATE_FORMAT_JSON.parse(p.getString(JSON_KEY_UPDATED)); } catch (Exception e) {}
try { imageUri = getImageUri(id, cmso); } catch (Exception e) {}



try {
    JSONArray linksArr = p.getJSONArray(JSON_KEY_LINKS);
    for (int i = 0; i < linksArr.length(); i++) {
        JSONObject linkObj = linksArr.getJSONObject(i);
        String linkHref = "";
        String linkHrefLang = "";
        String linkRel = "";
        String linkType = "";
        try { linkHref = linkObj.getString(JSON_KEY_LINK_HREF); } catch (Exception e) {  }
        try { linkHrefLang = linkObj.getString(JSON_KEY_LINK_HREFLANG); } catch (Exception e) {  }
        try { linkRel = linkObj.getString(JSON_KEY_LINK_REL); } catch (Exception e) {  }
        try { linkType = linkObj.getString(JSON_KEY_LINK_TYPE); } catch (Exception e) {  }
        links.add(new OptLink("" + linkHref));
    }
} catch (Exception e) {
    
}






// -----------------------------------------------------------------------------
// Print the details
//------------------------------------------------------------------------------


// Template ("outer" or "master" template)
//String template             = cms.getTemplate();
//String[] elements           = cms.getTemplateIncludeElements();
// Important: Set the title before calling the template
request.setAttribute("title", title);
// Include upper part of main template
cms.include(T, T_ELEM[0], T_EDIT);

out.println("<article class=\"main-content\">");
out.println("<div itemscope=\"\" itemtype=\"http://schema.org/Person\" class=\"person\">");
out.println("<h1 itemprop=\"name\">" + (!honPrefix.isEmpty() ? ("<span itemprop=\"honorificPrefix\">" + honPrefix + "</span> ") : "") + title + "</h1>");
if (!position.isEmpty()) {
    out.println("<div class=\"detail\">");
    out.print("<span itemprop=\"jobTitle\">" + position + "</span>");
    if (onLeave) 
        out.print(" (" + LABEL_ON_LEAVE.toLowerCase() + ")");
    out.println("</div>");
}


if (!email.isEmpty() 
        || !phone.isEmpty()
        || !mobile.isEmpty()
        || !workplace.isEmpty()) {
    
    out.println("<div class=\"contact-info\">");
    
    if (!imageUri.isEmpty()) {
        CmsImageScaler imageHandle = new CmsImageScaler(cmso, cmso.readResource(imageUri));
        if (imageHandle.getWidth() > IMG_SIZE) {
            CmsImageScaler rescaler = imageHandle.getReScaler(imageHandle);
            rescaler.setWidth(IMG_SIZE);
            rescaler.setType(3);
            rescaler.setQuality(100);
            imageUri = (String)CmsAgent.getTagAttributesAsMap(cms.img(imageUri, rescaler, null)).get("src");
        }
        out.println("<span class=\"media pull-right xs\">");
        out.println("<img itemprop=\"image\" alt=\"" + title + "\" src=\"" + imageUri + "\" />");
        out.println("</span>");
    }
    
    out.println("<div class=\"contact-info-text\">");
    if (!email.isEmpty())
        out.println("<div class=\"detail\" itemprop=\"email\"><span class=\"key\">" + LABEL_EMAIL + "</span><span class=\"val\">" + cms.getJavascriptEmail(email, true, null) + "</span></div>");
    if (!phone.isEmpty())
        out.println("<div class=\"detail\" itemprop=\"telephone\"><span class=\"key\">" + LABEL_PHONE + "</span><span class=\"val\">" + normalizePhoneNumber(phone, cmso) + "</span></div>");
    if (!mobile.isEmpty())
        out.println("<div class=\"detail\" itemprop=\"telephone\"><span class=\"key\">" + LABEL_CELLPHONE + "</span><span class=\"val\">" + normalizePhoneNumber(mobile, cmso) + "</span></div>");
    if (!workplace.isEmpty())
        out.println("<div class=\"detail\" itemprop=\"workLocation\"><span class=\"key\">" + LABEL_WORKPLACE + "</span><span class=\"val\">" + workplace + "</span></div>");

    if (orgTrees.length > 0) {
        out.println("<div class=\"detail\"><span class=\"key\">" + LABEL_AFFILIATION + "</span><span class=\"val\">"); 
        for (String orgTree : orgTrees) 
            out.println(getOrgTree(orgTree));
        out.println("</span></div>");
    }
    
    out.println("<span style=\"display:none;\" itemprop=\"affiliation\">" + (loc.equalsIgnoreCase("no") ? "Norsk Polarinstitutt" : "Norwegian Polar Institute") + "</span>");
    
    out.println("</div>");
    out.println("</div>");
}



//
// Rich text, fetched from the CMS
//
/*
String moreUri = "/no/_2013/prosjekt/combined-remote-and-in-situ-study-of-sea-ice-thickness-and-motion-in-the-fram-strait.html";
I_CmsXmlContentContainer container = cms.contentload("singleFile", moreUri, EDITABLE);
request.setAttribute("paragraphContainer", container);
cms.include(PARAGRAPH_HANDLER);
*/
} catch (Exception e) {
    out.println(error("An unexpected error occured while constructing the project details."));
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
}


out.println("</div>");
out.println("</article>");
// Reset static variables
mappings.clear();
// Include lower part of main template
cms.include(T, T_ELEM[1], T_EDIT);
%>