<%-- 
    Document   : person-service-provided
    Description: Page template for resource type "person". This is a modified 
                    version, customized to fit the Polar Institute website.
                    As of 2017-03-31, "person" files are used primarily (only?) 
                    on this site.
                    This template is also capable of providing a default page
                    view for person entries in the Data Centre. Default views 
                    for "pages that do not exist" in the CMS, although initially
                    implemented with employees in mind, is a generic concept 
                    that is explained more detailed in the docs for
                    no.npolar.util.init.DefaultRendererInit
    ToDo       : This script pulls raw JSON from the Data Centre. It should use 
                    no.npolar.data.api.PersonService instead, but the Person and
                    PersonService class have currently not yet been thoroughly 
                    tested.
    Created on : Oct 9, 2013, 12:20:51 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page import="no.npolar.data.api.Project" %>
<%@page import="no.npolar.data.api.ProjectService" %>
<%@page import="no.npolar.data.api.Publication" %>
<%@page import="no.npolar.data.api.util.APIUtil" %>
<%@page import="no.npolar.data.api.util.OptLink" %>
<%@page import="no.npolar.util.*" %>
<%@page import="java.io.*" %>
<%@page import="java.net.*" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="java.util.*" %>
<%@page import="javax.swing.tree.*" %>
<%@page import="org.opencms.file.CmsObject" %>
<%@page import="org.opencms.file.CmsResource" %>
<%@page import="org.opencms.file.CmsResourceFilter" %>
<%@page import="org.opencms.jsp.I_CmsXmlContentContainer" %>
<%@page import="org.opencms.loader.CmsImageScaler" %>
<%@page import="org.opencms.relations.CmsCategoryService" %>
<%@page import="org.opencms.relations.CmsCategory" %>
<%@page import="org.opencms.main.OpenCms" %>
<%@page import="org.opencms.main.CmsException" %>
<%@page import="org.opencms.util.CmsStringUtil" %>
<%@page import="org.opencms.util.CmsRequestUtil" %>
<%@page import="org.opencms.security.CmsRole" %>
<%@page import="org.opencms.json.*" %>
<%@page import="org.opencms.mail.CmsSimpleMail" %>
<%@page session="true" 
        contentType="text/html; charset=UTF-8" 
        pageEncoding="utf-8" 
        trimDirectiveWhitespaces="true" 
%>
<%!
/**
 * The URI to the root folders - one per language - of employees/people.
 */ 
public static final String[] PERSON_FOLDERS = { 
    "/no/ansatte/",
    "/en/people/" 
};

/**
 * Translations: [code form]--[human-friendly form]
 * 
 * Primarily for translating organizational names, e.g. 
 * [komm]--[Communications dept.]
 * 
 * The map is populated by this script, see further down.
 */
public static Map<String, String> mappings = new HashMap<String, String>();
                
/**
 * Creates a tree of (unique) categories, representing parent/child relations 
 * between the categories.
 * 
 * The tree is converted to a string, containing html code (nested unordered 
 * lists) that can be used directly.
 * 
 * NO? Because the string is built recursively, a static string, "s", is employed. (And this method returns "void", not "String".)
 * 
 * The linkUri argument is used when generating links. Each category will be a 
 * link to this URI, with its own category path as the "cat" parameter.
 * 
 * Usage:
 *  1. buildCategoryTreeString(...);
 *  2. String myHtmlCodeForNestedList = new String(s);
*/
public String buildCategoryTreeString(CmsAgent cms 
                                  , String linkUri
                                  , List orgTrees) 
                                        throws CmsException {
    
    // Initialize the tree that will represent the affiliation
    DefaultMutableTreeNode root = new DefaultMutableTreeNode("ROOT");
    DefaultTreeModel tree = new DefaultTreeModel(root);
    
    Iterator iOrgTrees = orgTrees.iterator();
    
    while (iOrgTrees.hasNext()) {
        // Get the orgTree path
        String orgTreePath = (String)iOrgTrees.next(); // e.g. "/komm/info/"
        // Get the category itself
        String orgUnit = "";
        
        // Split the category path into parts
        String[] categoryPathParts = CmsStringUtil.splitAsArray(orgTreePath, "/");
        
        // For each iteration of assigned categories, ROOT is the initial parent
        DefaultMutableTreeNode parent = root;
        
        for (int i = 0; i < categoryPathParts.length; i++) {
            orgUnit = categoryPathParts[i];
            if (orgUnit.isEmpty()) {
                continue;
            }
            // Construct the category path
            //orgTreePath += categoryPathParts[i] + "/"; // i=0: catPath = org/     i=1: catPath = org/np/     i=2: catPath = org/np/ice/     and so on
            //orgUnit = categoryPathParts[i]; // i=0: catPath = org/     i=1: catPath = org/np/     i=2: catPath = org/np/ice/     and so on
            int index = 0;
            try {
                DefaultMutableTreeNode node = null;
                
                if (findNode(tree, orgUnit) != null) {
                    // Node already exists in the tree, use it
                    node = findNode(tree, orgUnit);
                } else {
                    // Node does not exist in the tree, add it
                    node = new DefaultMutableTreeNode(orgUnit);
                    tree.insertNodeInto(node, parent, index);
                }
                index++;
                parent = node;
            } catch (Exception e) {
                continue; // If something crashes, just continue
            }
        }
    }
    
    if (tree.getChild(root, 0) != null) {
        return printTree(tree, root, linkUri, cms);
    }
    return null;
}

/**
 * Prints a tree: Returns the HTML for the given tree as (nested) unordered 
 * list(s), using recursion.
 * 
 * Used for the "organizational affiliation" tree output.
 * 
 * See buildCategoryTreeString(CmsAgent, String, List)
 */
public String printTree(DefaultTreeModel tree
                    , DefaultMutableTreeNode node
                    , String linkUri
                    , CmsAgent cms
                    ) {
    
    int numChildNodes = tree.getChildCount(node);
    String _s = "";
    try {
        int nodeDepth = tree.getPathToRoot(node).length;
        
        if (!node.isRoot()) {
            String orgUnit = (String)node.getUserObject();
            _s += "<ul" + (nodeDepth <= 2 ? " class=\"person-affiliation\"" : "") + "><li>" + 
                    "<a href=\"" + cms.link(linkUri) + "?q=&amp;limit=1000&amp;filter-orgtree=" + orgUnit + "\">" + getMapping(orgUnit) + "</a>";
        }
        for (int i = numChildNodes-1; i >= 0; i--) {
            _s += printTree(tree, (DefaultMutableTreeNode)tree.getChild(node, i), linkUri, cms);
        }
        if (!node.isRoot()) {
            _s += "</li></ul>";
        }
    } catch (Exception e) {
        throw new NullPointerException(e.getMessage());
    }
    
    return _s;
}

/**
 * Finds a node containing a given user object in the given tree. 
 * 
 * The first encountered matching node (using depth-first traversal) is returned, 
 * or null if no matching node is found.
 */
public DefaultMutableTreeNode findNode(DefaultTreeModel tree, Object userObject) {
    Enumeration treeNodes = ((DefaultMutableTreeNode)tree.getRoot()).depthFirstEnumeration();
    while (treeNodes.hasMoreElements()) {
        DefaultMutableTreeNode node = (DefaultMutableTreeNode)treeNodes.nextElement();
        if (node.getUserObject().equals(userObject))
            return node;
    }
    return null;
}

/**
 * Gets an error message as "normalized" HTML.
 */
public String error(String msg) {
    return error("Error", msg);
}
/**
 * Gets an error message as "normalized" HTML.
 */
public String error(String title, String msg) {
    String s = "<article class=\"main-content\">";
    s += "<h1>" + title + "</h1>";
    s += "<div class=\"ingress msg msg--alert\"><p class=\"msg__content\">" + msg + "</p></div>";
    s += "</article>";
    
    return s;
}

/**
 * Gets an exception's stack trace as a string.
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

/**
 * Gets a person's image URI, based on the given person ID.
 */
public String getImageUri(String id, CmsObject cmso) {
    // Expected file extensions, in order of priority
    String[] fileExt = { "jpg", "JPG", "jpeg", "JPEG", "png", "PNG", "gif", "GIF" };
    // The standard image folder for employees
    String imageName = "/images/people/".concat(id);
    for (String ext : fileExt) {
        String imageUri = imageName + "." + ext;
        if (cmso.existsResource(imageUri)) {
            return imageUri;
        }
    }
    return "";
}

/**
 * Gets a person's phone number, normalized, if possible.
 */
public String normalizePhoneNumber(String phoneNumber, CmsObject cmso) {
    Locale locale = cmso.getRequestContext().getLocale();
    String loc = locale.toString();
    if (!phoneNumber.isEmpty()) {
        if (phoneNumber.startsWith("+47")) {
            phoneNumber = phoneNumber.substring(3);
            if (!loc.equalsIgnoreCase("no")) {
                phoneNumber = "+47 " + phoneNumber;
            }
        }
    }
    return phoneNumber;
}

/** 
 * Swap the value retrieved from the service with the "nice" value, using the 
 * mappings defined in this script.
 */
public String getMapping(String serviceValue) {
    String s = mappings.get(serviceValue);
    if (s != null && !s.isEmpty()) {
        return s;
    }
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

/**
 * Converts the given orgTree string to a HTML string (unordered list). The input 
 * string form should be like this: "/komm/info/".
 */
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

/**
 * Converts a list of strings to one string containing an HTML unordered list.
 */
public String listToHtmlList(List list) {
    if (list.isEmpty())
        return "";
    
    String s = "";
    Iterator<String> i = list.iterator();    
    s += "<ul><li><a href=\"#\" rel=\"nofollow\">" + getMapping(i.next()) + "</a>";
    if (i.hasNext()) {
        i.remove();
        s += listToHtmlList(list);
    }
    s += "</li></ul>";
    return s;
}

/**
 * Takes a full, normal URL and converts it to a more human-friendly version.
 */
public String makeNiceWebsite(String url) {
    if (url.startsWith("http://")) {
        url = url.substring(7);
    }
    if (url.endsWith("/")) {
        url = url.substring(0, url.length()-1);
    }
    return url;
}

/**
 * Gets the URI for this person's page in the "other language".
 * 
 * Limited to a use-case of 2 languages.
 */
public String getPersonAlternateUri(String localeStr, String personId) {
    return getAlternatePersonFolder(localeStr).concat(personId);
}

/**
 * Gets the URI for this person's folder, in the language described by the given
 * locale.
 * 
 * Limited to a use-case of 2 languages (but easily expanded).
 */
public String getPersonFolder(String localeStr) {
    return localeStr.equals("no") ? getPersonFolders()[0] : getPersonFolders()[1];
}

/**
 * Gets the URI for this person's folder in the "other language".
 * 
 * Limited to a use-case of 2 languages.
 */
public String getAlternatePersonFolder(String localeStr) {
    return localeStr.equals("no") ? getPersonFolder("en") : getPersonFolder("no");
}
/**
 * Gets the URIs of all available person folders.
 */
public String[] getPersonFolders() {
    return PERSON_FOLDERS;
}
%><%
// Standard CMS action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
//String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();

final String ATTR_NAME_URI_ALT_LANG = "alternate_uri";
final String ATTR_NAME_ID_EXTERNAL = "external_id";
final String PERSON_INDEX_URI   = getPersonFolder(loc);// "/no/ansatte/" or "/en/people/"

// The resource type ID for "person"
final int TYPE_ID_PERSON = org.opencms.main.OpenCms.getResourceManager().getResourceType("person").getTypeId();

// Direct edit settings
final boolean EDITABLE = false;
final boolean T_EDIT = false;

// Flag: Logged in user?
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

// Main template (and elements; most often "head" and "foot")
final String T = cmso.readPropertyObject(PERSON_INDEX_URI, "template", true).getValue("");
final String[] T_ELEM = cmso.readPropertyObject(PERSON_INDEX_URI, "template-include-elements", true).getValue("head;foot").split(";");

// If requestFileUri == PERSON_INDEX_URI, we're dealing with

// Does this person have a "person" file in the VFS? (If not, we are just gonna 
// use the standard info fetched from the Data Centre.)
boolean personFileInVfs = cmso.existsResource(requestFileUri) && cmso.readResource(requestFileUri).getTypeId() == TYPE_ID_PERSON;




//
// ToDo:
// =====
// If no person file exists, AND the person is no longer employed, we should
// return a 404 not found.
//




// Make sure an ID exists - it is *required*
String pid = null;
try {
    // Check if a person ID has been set as request attribute - if yes, no 
    // regular VFS file exists; we'll base the page solely on the Data Centre 
    // entry and nothing else
    pid = (String)request.getAttribute(ATTR_NAME_ID_EXTERNAL);
    if (pid != null && !pid.isEmpty()) {
        // Set the alternate URI, so that we can switch language. (Since this is
        // not a regular VFS file, there is no sibling.)
        request.setAttribute(ATTR_NAME_URI_ALT_LANG, getPersonAlternateUri(loc, pid));
    }
} catch (Exception e) {}

// If the ID is null at this point, we're dealing with a regular VFS file
if (pid == null) {
    pid = CmsResource.getName(cms.getRequestContext().getFolderUri());
    pid = pid.substring(0, pid.length()-1); // Remove trailing slash
} 
if (pid == null || pid.isEmpty()) {
    // No ID: crash
    request.setAttribute("title", "Error");
    cms.include(T, T_ELEM[0], T_EDIT);
    out.println(error("An ID is required in order to view this page."));
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
}

// Scripts that provide the publications/projects lists. 
// These are included via javascript to prevent this page crashing if the Data 
// Centre does not respond properly and/or in time. (A frequent situation.)
final String PUB_LIST = "/system/modules/no.npolar.common.person/elements/person-publications-full-list.jsp";
final String PROJ_LIST = "/system/modules/no.npolar.common.person/elements/person-projects-full-list.jsp";

final String LABEL_NOT_FOUND_TITLE = loc.equalsIgnoreCase("no") ? 
        "Fant ikke denne personen" 
        : "Could not find this person";
final String LABEL_NOT_FOUND_MSG = loc.equalsIgnoreCase("no") ? 
        "Det finnes ingen person med denne ID-en (\"" + pid + "\") i vårt system." 
        : "There is no person with this ID (\"" + pid + "\") in our system.";


    
//
// Access the Data Centre and read key info
// 

// Service details
final String SERVICE_PROTOCOL = "https";
final String SERVICE_DOMAIN_NAME = "api.npolar.no";
final String SERVICE_PATH = "/person/";
final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + SERVICE_PATH;

// Test service 
// ToDo: The error message should be moved to workplace.properies or something
final String ERROR_MSG_NO_SERVICE = loc.equalsIgnoreCase("no") ? 
        ("<h1>Persondetaljer</h1><h2>Vel, dette skulle ikke skje&nbsp;&hellip;</h2>"
            + "<p>Sideinnholdet som skulle vært her kan dessverre ikke vises akkurat nå, på grunn av en midlertidig feil.</p>"
            + "<p>Vi liker heller ikke dette, og håper å ha alt i orden igjen snart.</p>"
            + "<p>Prøv gjerne å laste inn siden på nytt om litt.</p>"
            + "<p style=\"font-style:italic;\">Skulle feilen vedvare, setter vi pris på det om du tar deg tid til å <a href=\"mailto:web@npolar.no\">sende oss en kort notis om dette</a>.")
        :
        ("<h1>Person details</h1><h2>Well this shouldn't happen&nbsp;&hellip;</h2>"
            + "<p>The content that should appear here can't be displayed at the moment, due to a temporary error.</p>"
            + "<p>We hate it when this happens, and hope to have everything sorted out shortly.</p>"
            + "<p>Please try reloading this page in a little while.</p>"
            + "<p style=\"font-style:italic;\">If the error persist, we would appreciate it if you could take the time to <a href=\"mailto:web@npolar.no\">send us a short note about this</a>.</p>");
try {
    boolean isAvailable = APIUtil.testAvailability(SERVICE_BASE_URL.concat("?q="), new int[]{200}, 5000, 3);
    if (!isAvailable) {
        request.setAttribute("title", "Error");
        cms.include(T, T_ELEM[0], T_EDIT);
        out.println("<div class=\"error\">" + ERROR_MSG_NO_SERVICE + "</div>");
        cms.include(T, T_ELEM[1], T_EDIT);
        
        // Send error message
        try {
            SystemMessenger.sendStandardError(
                    SystemMessenger.DEFAULT_INTERVAL, 
                    "last_err_notification_persons", 
                    application, 
                    cms, 
                    "web@npolar.no", 
                    "no-reply@npolar.no", 
                    "Employees");
        } catch (Exception e) {
            out.println("\n<!-- \nError sending email notification about problems with this page: " + e.getMessage() + " \n-->");
        }
        return;
    }
} catch (Exception e) {}

// Construct the service URL to look up for this particular person
String serviceUrl = SERVICE_BASE_URL + pid + ".json";

// Request the JSON feed from the service and build the JSON object
// Should use no.npolar.data.api.PersonService instead, but it needs testing
String jsonFeed = null;
JSONObject p = null;
try {
    jsonFeed = APIUtil.httpResponseAsString(serviceUrl);
    p = new JSONObject(jsonFeed);
} catch (FileNotFoundException fnfe) {
    cms.setStatus(404);
    request.setAttribute("title", LABEL_NOT_FOUND_TITLE);
    // Remove the alternate URI for switching language.
    request.removeAttribute(ATTR_NAME_URI_ALT_LANG);
    cms.include(T, T_ELEM[0], T_EDIT);
    out.println(error(LABEL_NOT_FOUND_TITLE, LABEL_NOT_FOUND_MSG));
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
} catch (Exception e) {
    request.setAttribute("title", "Error");
    cms.include(T, T_ELEM[0], T_EDIT);
    //out.println("<article class=\"main-content\">");
    out.println(error("An unexpected error occured while constructing the page."));
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<p>Service URL: <a href=\"" + serviceUrl + "\">" + serviceUrl + "</a></p>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
}




// JSON keys (and date format)
final String JSON_KEY_ID_WEB        = "id";
final String JSON_KEY_JOB_TITLE     = "jobtitle";
//final String JSON_KEY_EMPLOYMENT    = "employment";
final String JSON_KEY_ON_LEAVE      = "on_leave";
final String JSON_KEY_CURR_EMPLOYED = "currently_employed";
final String JSON_KEY_WORKPLACE     = "workplace";
final String JSON_KEY_PHONE         = "phone";
final String JSON_KEY_MOBILE        = "mobile";
final String JSON_KEY_EMAIL         = "email";
//final String JSON_KEY_UPDATED       = "updated";
final String JSON_KEY_HON_PREFIX    = "honorific_prefix";
final String JSON_KEY_FNAME         = "first_name";
final String JSON_KEY_LNAME         = "last_name";
final String JSON_KEY_ORGTREE       = "orgtree";
final String JSON_KEY_LINKS         = "links";
final String JSON_KEY_LINK_HREF     = "href";
final String JSON_KEY_LINK_HREFLANG = "hreflang";
final String JSON_KEY_LINK_REL      = "rel";
final String JSON_KEY_LINK_TYPE     = "type";

// Date formats
//final SimpleDateFormat DATE_FORMAT_JSON = new SimpleDateFormat("yyyy-dd-MM");

// Labels
final String LABEL_AFFILIATION          = "<i class=\"icon-flow-tree\" aria-label=\"" + cms.labelUnicode("label.Person.Affiliation") + "\" title=\"" + cms.labelUnicode("label.Person.Affiliation") + "\"></i>";
final String LABEL_PHONE                = "<i class=\"icon-phone-1\" aria-label=\"" + cms.labelUnicode("label.Person.Phone") + "\" title=\"" + cms.labelUnicode("label.Person.Phone") + "\"></i>";
final String LABEL_CELLPHONE            = "<i class=\"icon-mobile-1\" aria-label=\"" + cms.labelUnicode("label.Person.Cellphone") + "\" title=\"" + cms.labelUnicode("label.Person.Cellphone") + "\"></i>";
final String LABEL_EMAIL                = "<i class=\"icon-mail\" aria-label=\"" + cms.labelUnicode("label.Person.Email") + "\" title=\"" + cms.labelUnicode("label.Person.Email") + "\"></i>";
final String LABEL_WORKPLACE            = "<i class=\"icon-home\" aria-label=\"" + cms.labelUnicode("label.Person.Workplace") + "\" title=\"" + cms.labelUnicode("label.Person.Workplace") + "\"></i>";
final String LABEL_CAREER               = cms.labelUnicode("label.Person.Career");
final String LABEL_ACTIVITIES           = cms.labelUnicode("label.Person.Activities");
final String LABEL_INTEREST_EXPERTISE   = cms.labelUnicode("label.Person.InterestsExpertise");
final String LABEL_ON_LEAVE             = cms.labelUnicode("label.Person.OnLeave");
final String LABEL_NO_LONGER_EMPLOYED   = cms.labelUnicode("label.for.person.nolongeremployed");

final String LABEL_ORG_COMM                 = loc.equalsIgnoreCase("no") ? "Kommunikasjon" : "Communications";
final String LABEL_ORG_COMM_INFO            = loc.equalsIgnoreCase("no") ? "Informasjon" : "Information";
final String LABEL_ORG_ADM                  = loc.equalsIgnoreCase("no") ? "Administrasjon" : "Administration";
final String LABEL_ORG_ADM_ECONOMICS        = loc.equalsIgnoreCase("no") ? "Økonomi" : "Economics";
final String LABEL_ORG_ADM_HR               = loc.equalsIgnoreCase("no") ? "Personal" : "Human resources";
final String LABEL_ORG_ADM_SENIOR           = loc.equalsIgnoreCase("no") ? "Seniorrådgivere" : "Senior advisers";
final String LABEL_ORG_ADM_ICT              = loc.equalsIgnoreCase("no") ? "IKT" : "ICT";
final String LABEL_ORG_LEADER               = loc.equalsIgnoreCase("no") ? "Ledergruppen" : "Management Group";
final String LABEL_ORG_RESEARCH             = loc.equalsIgnoreCase("no") ? "Forskning" : "Scientific research";
final String LABEL_ORG_RESEARCH_BIODIV      = loc.equalsIgnoreCase("no") ? "Biodiversitet" : "Biodiversity";
final String LABEL_ORG_RESEARCH_GEO         = loc.equalsIgnoreCase("no") ? "Geologi og geofysikk" : "Geology and geophysics";
final String LABEL_ORG_RESEARCH_MARINE_CRYO = loc.equalsIgnoreCase("no") ? "Hav og havis" : "Oceans and sea ice";
final String LABEL_ORG_RESEARCH_ICE         = loc.equalsIgnoreCase("no") ? "Senter for is, klima og økosystemer (ICE)" : "Centre for Ice, Climate and Ecosystems (ICE)";
final String LABEL_ORG_RESEARCH_ICE_FLUXES  = loc.equalsIgnoreCase("no") ? "ICE-havis" : "ICE Fluxes";
final String LABEL_ORG_RESEARCH_ICE_FIMBUL  = loc.equalsIgnoreCase("no") ? "ICE-Fimbulisen" : "ICE Fimbul Ice Shelf";
final String LABEL_ORG_RESEARCH_ICE_ECOSYS  = loc.equalsIgnoreCase("no") ? "ICE-økosystemer" : "ICE Ecosystems";
final String LABEL_ORG_RESEARCH_ECOTOX      = loc.equalsIgnoreCase("no") ? "Miljøgifter" : "Environmental pollutants";
final String LABEL_ORG_RESEARCH_SUPPORT     = loc.equalsIgnoreCase("no") ? "Støtte" : "Support";
final String LABEL_ORG_ENVMAP               = loc.equalsIgnoreCase("no") ? "Miljø- og kart" : "Environment and mapping";
final String LABEL_ORG_ENVMAP_DATA          = loc.equalsIgnoreCase("no") ? "Miljødata" : "Environmental data";
final String LABEL_ORG_ENVMAP_MANAGEMENT    = loc.equalsIgnoreCase("no") ? "Miljørådgivning" : "Environmental management";
final String LABEL_ORG_ENVMAP_MAP           = loc.equalsIgnoreCase("no") ? "Kart" : "Map";
final String LABEL_ORG_OL                   = loc.equalsIgnoreCase("no") ? "Operasjons- og logistikk" : "Operations and logistics";
final String LABEL_ORG_OL_ANTARCTIC         = loc.equalsIgnoreCase("no") ? "Antarktis" : "The Antarctic";
final String LABEL_ORG_OL_ARCTIC            = loc.equalsIgnoreCase("no") ? "Arktis" : "The Arctic";
//final String LABEL_ORG_OL_LYR               = loc.equalsIgnoreCase("no") ? "Støtte" : "Support"; // No longer used (?)
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
mappings.put("havis",       LABEL_ORG_RESEARCH_ICE_FLUXES);
mappings.put("fimbul",      LABEL_ORG_RESEARCH_ICE_FIMBUL);
mappings.put("okosystemer", LABEL_ORG_RESEARCH_ICE_ECOSYS);
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



// Variables used for employee details read from the service
String title        = "";
String id           = "";
String position     = "";
String workplace    = "";
//String employment   = "";
boolean currEmployed= true;
//Date lastUpdated    = null;
boolean onLeave     = false;
String autoPubsStr  = "";
boolean autoPubs    = true;
String autoPubsTypes= "";
String autoProjectsStr  = "";
boolean autoProjects= true;
String autoProjectTypes= "";
String phone        = "";
String mobile       = "";
String honPrefix    = "";
String email        = "";
String fname        = "";
String lname        = "";
String[] orgTrees   = null;
String imageUri     = "";
List<OptLink> links = new ArrayList<OptLink>();

// Variables used for employee details read from the CMS
String website      = null;
String descr        = null;
String career       = null;
String activities   = null;
String areas        = null;
//String references   = null;
I_CmsXmlContentContainer other = null;
String otherString  = "";

List<String> pubTypes = new ArrayList<String>();
pubTypes.add("peer-reviewed");
pubTypes.add("editorial");
pubTypes.add("review");




try {
    //
    // Read the details from the .json
    //
    try { id = p.getString(JSON_KEY_ID_WEB); } catch (Exception e) { }
    try { position = p.getJSONObject(JSON_KEY_JOB_TITLE).getString(loc); } catch (Exception e) { }
    try { workplace = p.getString(JSON_KEY_WORKPLACE); } catch (Exception e) { }
    //try { employment = p.getString(JSON_KEY_EMPLOYMENT); } catch (Exception e) { }
    try { currEmployed = p.getBoolean(JSON_KEY_CURR_EMPLOYED); } catch (Exception e) { }
    try { onLeave = p.getBoolean(JSON_KEY_ON_LEAVE); } catch (Exception e) { }
    try { phone = p.getString(JSON_KEY_PHONE); } catch (Exception e) { }
    try { mobile = p.getString(JSON_KEY_MOBILE); } catch (Exception e) { }
    try { email = p.getString(JSON_KEY_EMAIL); } catch (Exception e) { }
    try { honPrefix = p.getString(JSON_KEY_HON_PREFIX); } catch (Exception e) { }
    try { fname = p.getString(JSON_KEY_FNAME); } catch (Exception e) { }
    try { lname = p.getString(JSON_KEY_LNAME); } catch (Exception e) { }
    try { orgTrees = jsonArrayToStringArray(p.getJSONArray(JSON_KEY_ORGTREE)); } catch (Exception e) { }
    //try { lastUpdated = DATE_FORMAT_JSON.parse(p.getString(JSON_KEY_UPDATED)); } catch (Exception e) {}
    try { imageUri = getImageUri(id, cmso); } catch (Exception e) {}
    try { title = fname + " " + lname; } catch (Exception e) { title = "Unknown title"; }

    if (!personFileInVfs && !currEmployed) {
        // No person file, and not currently employed
        cms.setStatus(404);
        // Remove the alternate URI for switching language.
        request.removeAttribute(ATTR_NAME_URI_ALT_LANG);
        request.setAttribute("title", LABEL_NOT_FOUND_TITLE);
        cms.include(T, T_ELEM[0], T_EDIT);
        out.println(error(LABEL_NOT_FOUND_TITLE, LABEL_NOT_FOUND_MSG));
        cms.include(T, T_ELEM[1], T_EDIT);
        return; // IMPORTANT!
    }


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
            links.add(
                    new OptLink("" + linkHref)
            );
        }
    } catch (Exception ignore) {}

    if (personFileInVfs) {
        try {
            // Read additional content from the person file in the CMS
            I_CmsXmlContentContainer thisFile = cms.contentload("singleFile", requestFileUri, EDITABLE);
            while (thisFile.hasMoreResources()) {
                website     = cms.contentshow(thisFile, "PersonalWebsite");
                descr       = cms.contentshow(thisFile, "Description");
                career      = cms.contentshow(thisFile, "Career");
                activities  = cms.contentshow(thisFile, "Activities");
                areas       = cms.contentshow(thisFile, "InterestsExpertise");
                //references  = cms.contentshow(thisFile, "Bibliography");

                // Auto-publications
                autoPubsStr = cms.contentshow(thisFile, "AutoPubs");
                autoPubs    = Boolean.valueOf(CmsAgent.elementExists(autoPubsStr) ? autoPubsStr : "true").booleanValue(); // Default to "true"

                // Define which publication types to include (default is all)
                I_CmsXmlContentContainer pubOpts = cms.contentloop(thisFile, "PubOpts");
                if (pubOpts != null) {
                    if (pubOpts.hasMoreResources()) {
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "PeerReviewed")))
                            autoPubsTypes += Publication.Type.PEER_REVIEWED + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Editorial")))
                            autoPubsTypes += Publication.Type.EDITORIAL + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Review")))
                            autoPubsTypes += Publication.Type.REVIEW + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Correction")))
                            autoPubsTypes += Publication.Type.CORRECTION + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Book")))
                            autoPubsTypes += Publication.Type.BOOK + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "BookContrib")))
                            autoPubsTypes += Publication.Type.IN_BOOK + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Poster")))
                            autoPubsTypes += Publication.Type.POSTER + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Report")))
                            autoPubsTypes += Publication.Type.REPORT + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "ReportContrib")))
                            autoPubsTypes += Publication.Type.IN_REPORT + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Abstract")))
                            autoPubsTypes += Publication.Type.ABSTRACT + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "PhD")))
                            autoPubsTypes += Publication.Type.PHD + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Master")))
                            autoPubsTypes += Publication.Type.MASTER + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Map")))
                            autoPubsTypes += Publication.Type.MAP + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Proceedings")))
                            autoPubsTypes += Publication.Type.PROCEEDINGS + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Popular")))
                            autoPubsTypes += Publication.Type.POPULAR + "|";
                        if (Boolean.valueOf(cms.contentshow(pubOpts, "Other")))
                            autoPubsTypes += Publication.Type.OTHER + "|";
                    }
                }
                if (!autoPubsTypes.isEmpty()) 
                    autoPubsTypes = autoPubsTypes.substring(0, autoPubsTypes.length()-1); // Strip trailing "|"

                // Auto-projects
                autoProjectsStr = cms.contentshow(thisFile, "AutoProjects");
                autoProjects    = Boolean.valueOf(CmsAgent.elementExists(autoProjectsStr) ? autoProjectsStr : "true").booleanValue(); // Default to "true"

                // Define which projects to list (default is all)
                I_CmsXmlContentContainer projectOpts = cms.contentloop(thisFile, "ProjectOpts");
                if (projectOpts != null) {
                    if (projectOpts.hasMoreResources()) {
                        if (Boolean.valueOf(cms.contentshow(projectOpts, "Planned")))
                            autoProjectTypes += Project.Val.STATE_PLANNED + "|";
                        if (Boolean.valueOf(cms.contentshow(projectOpts, "Ongoing")))
                            autoProjectTypes += Project.Val.STATE_ONGOING + "|";
                        if (Boolean.valueOf(cms.contentshow(projectOpts, "Completed")))
                            autoProjectTypes += Project.Val.STATE_COMPLETED + "|";
                        if (Boolean.valueOf(cms.contentshow(projectOpts, "Cancelled")))
                            autoProjectTypes += Project.Val.STATE_CANCELLED + "|";
                    }
                } 
                if (!autoProjectTypes.isEmpty()) 
                    autoProjectTypes = autoProjectTypes.substring(0, autoProjectTypes.length()-1); // Strip trailing "|"


                //degree      = cms.contentshow(thisFile, "Degree");
                //nation      = cms.contentshow(thisFile, "Nationality");
                other       = cms.contentloop(thisFile, "Other");

                // Build the "other" string (if needed) 
                otherString = "";
                while (other.hasMoreResources()) {
                    String heading = cms.contentshow(other, "Heading");
                    String text = cms.contentshow(other, "Text");
                    if (CmsAgent.elementExists(heading))
                        otherString += "<h2>" + heading + "</h2>";
                    if (CmsAgent.elementExists(text))
                        otherString += text;
                }
            }
        } catch (Exception noSuchVfsResource) {
            // Log this?
        }
    }
} catch (Exception e) {
    request.setAttribute("title", "Error");
    cms.include(T, T_ELEM[0], T_EDIT);
    //out.println("<article class=\"main-content\">");
    out.println(
            error("An unexpected error occured while constructing the page content."
                    + " Please try again later")
    );
    try {
        /*
        CmsSimpleMail mail = new CmsSimpleMail();
        mail.setSubject("Critical error on person page");
        mail.setMsg("A critical error occured while constructing the page content for '" + requestFileUri + "'. Please take appropriate action.");
        mail.addTo("web@npolar.no"); 
        mail.setFrom("no-reply@npolar.no");
        mail.send();
        //*/
        SystemMail errorMail = new SystemMail();
        errorMail.setSubject("Critical error on person page");
        errorMail.setMessage("A critical error occured while constructing the page content for '" + requestFileUri + "'."
                + "\n\nPlease take appropriate action."
                + "\n\nThis email was generated by OpenCms/" + cms.info("opencms.uri") + " for the site at " + request.getServerName() + "."
        );
        errorMail.setToAddr("web@npolar.no");
        errorMail.send();
    } catch (Exception me) {}
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
    cms.include(T, T_ELEM[1], T_EDIT);
    return; // IMPORTANT!
}


////////////////////////////////////////////////////////////////////////////////
// 
// Main content section

// Important: Set the title before calling the template
request.setAttribute("title", title);
cms.include(T, T_ELEM[0], T_EDIT);
%>
<article class="main-content">
<div itemscope="" itemtype="http://schema.org/Person" class="person">
<%
out.println("<h1 itemprop=\"name\">" + (!honPrefix.isEmpty() ? ("<span itemprop=\"honorificPrefix\">" + honPrefix + "</span> ") : "") + title + "</h1>");

if (!position.isEmpty()) {
    out.println("<div class=\"detail\">" 
                + "<span itemprop=\"jobTitle\">" + position + "</span>" 
                + (onLeave ? (" (" + LABEL_ON_LEAVE.toLowerCase() + ")") : "")
            + "</div>");
}
if (!currEmployed) {
    %>
    <aside class="msg msg--alert">
        <p class="msg__content">
           <%= fname %> <%= LABEL_NO_LONGER_EMPLOYED %>
        </p>
    </aside>
    <%
}
%>
<div class="contact-info clearfix">
<%
if (!email.isEmpty() 
        || !phone.isEmpty()
        || !mobile.isEmpty()
        || !workplace.isEmpty()
        || orgTrees.length > 0) {

    if (!imageUri.isEmpty()) {
        // The image size for the profile image
        final int IMG_SIZE = Integer.valueOf(cmso.readPropertyObject(requestFileUri, "image.size", true).getValue("150")).intValue();
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
    
    if (!email.isEmpty()) {
        out.println("<div class=\"detail\" itemprop=\"email\">"
                    + "<span class=\"key\">" + LABEL_EMAIL + "</span>"
                    + "<span class=\"val\">" + cms.getJavascriptEmail(email, true, null) + "</span>"
                + "</div>");
    }
    if (!phone.isEmpty()) {
        out.println("<div class=\"detail\" itemprop=\"telephone\">"
                    + "<span class=\"key\">" + LABEL_PHONE + "</span>"
                    + "<span class=\"val\">" + normalizePhoneNumber(phone, cmso) + "</span>"
                + "</div>");
    }
    if (!mobile.isEmpty()) {
        out.println("<div class=\"detail\" itemprop=\"telephone\">"
                    + "<span class=\"key\">" + LABEL_CELLPHONE + "</span>"
                    + "<span class=\"val\">" + normalizePhoneNumber(mobile, cmso) + "</span>"
                + "</div>");
    }
    if (!workplace.isEmpty()) {
        out.println("<div class=\"detail\" itemprop=\"workLocation\">"
                    + "<span class=\"key\">" + LABEL_WORKPLACE + "</span>"
                    + "<span class=\"val\">" + workplace + "</span>"
                + "</div>");
    }
    if (orgTrees.length > 0) {
        out.println("<div class=\"detail\">"
                    + "<span class=\"key\">" + LABEL_AFFILIATION + "</span>"
                    + "<div class=\"val\">"
                        + buildCategoryTreeString(cms, PERSON_INDEX_URI, Arrays.asList(orgTrees))
                    + "</div>"
                + "</div>");
    }

    out.println("<span style=\"display:none;\" itemprop=\"affiliation\">" 
                + (loc.equalsIgnoreCase("no") ? "Norsk Polarinstitutt" : "Norwegian Polar Institute") 
            + "</span>");

    out.println("</div>");
}

if (CmsAgent.elementExists(website)) {
    out.println("<p>" + cms.label("label.Person.PersonalWebsite") + ": <a href=\"" + website + "\" rel=\"nofollow\">" + makeNiceWebsite(website) + "</a></p>");
}

if (CmsAgent.elementExists(descr)) {
    out.println(descr);
}
%>
</div>
<%
    
// Automagic publications/projects lists, pulled from the Data Centre.
//
// It is important that the lists are js-injected, otherwise any error could 
// potentially crash this whole page.

// Parameters to pass to the list generator JSPs when we inject them via js
Map params = new HashMap();
String emailId = email.substring(0, email.indexOf("@"));
params.put("email", emailId);
params.put("locale", loc);
params.put("pubtypes", autoPubsTypes);
params.put("projecttypes", autoProjectTypes);

// This .gif should ideally be a CSS animation, like this (which doesn't work):
// <span class=\"loader\" style=\"font-size:0.8em; height:1em; width:1em; margin:0; border-width:0.2em;\"></span>"
String loadingCue = " <img src=\"/system/modules/no.npolar.site.npweb/resources/style/loader.gif\""
        + " alt=\"\""
        + " style=\"display:inline-block; width:1em;\""
        + ">";

// Publicatons list (?)
if (autoPubs) {
    out.println("<div id=\"employee-pubs-full\">");
    out.println("<div id=\"pub-list-working\" class=\"toggler\" style=\"color:#666;\">"
                    + "<span style=\"color:#aaa;\">" // span is here for text color control (parent's color is for error message, should loading fail)
                        + cms.labelUnicode("label.np.publist.heading") 
                        + loadingCue
                    + "</span>"
                + "</div>");
    out.println("</div>");
    
    %>
    <script type="text/javascript">
        $('#employee-pubs-full').load('<%= cms.link(CmsRequestUtil.appendParameters(PUB_LIST, params, true)) %>', function( response, status, xhr ) {
            if ( status === "error" ) {
                var msg = "<%= cms.labelUnicode("label.np.publist.error") %>";//"Sorry, an error occurred while looking for publications: ";
                $( "#pub-list-working" ).html( msg + " (" + xhr.status + " " + xhr.statusText + ")" );
            } else {
                initToggleablesInside( $('#employee-pubs-full') );
            }
        });
    </script>
    <%
}

// Projects list (?)
if (autoProjects) {
    out.println("<div id=\"employee-proj-full\">");    
    out.println("<div id=\"proj-list-working\" class=\"toggler\" style=\"color:#666;\">"
                    + "<span style=\"color:#aaa;\">"
                        + cms.labelUnicode("label.np.projectlist.heading") 
                        + loadingCue
                    + "</span>"
                + "</div>");
    out.println("</div>");
    
    %>
    <script type="text/javascript">
        $('#employee-proj-full').load('<%= cms.link(CmsRequestUtil.appendParameters(PROJ_LIST, params, true)) %>', function( response, status, xhr ) {
            if ( status === "error" ) {
                var msg = "<%= cms.labelUnicode("label.np.projectlist.error") %>";//"Sorry, an error occurred while looking for projects: ";
                $( "#proj-list-working" ).html( msg + " (" + xhr.status + " " + xhr.statusText + ")" );
            } else {
                initToggleablesInside( $('#employee-proj-full') );
            }
        });
    </script>
    <%
}

// Output the remaining select content bits stored in the person file in our CMS
//
// Note: We disregard "References / Bibliography" because it is handled by the 
//       automagic lists.
if (CmsAgent.elementExists(career) 
        || CmsAgent.elementExists(activities)
        || CmsAgent.elementExists(areas)
        || !otherString.isEmpty()) {
    %>
    <div class="about">
    <%
    
    if (CmsAgent.elementExists(activities)) {
        out.println("<h2>" + LABEL_ACTIVITIES + "</h2>");
        out.println(activities);
    }
    if (CmsAgent.elementExists(career)) {
        out.println("<h2>" + LABEL_CAREER + "</h2>");
        out.println(career);
    }
    if (CmsAgent.elementExists(areas)) {
        out.println("<h2>" + LABEL_INTEREST_EXPERTISE + "</h2>");
        out.println(areas);
    }
    if (!otherString.isEmpty()) {
        out.println(otherString);
    }
    %>
    </div><!-- .about -->
    <%
}
%>
</div><!-- .person -->
</article><!-- .main-content -->
<%
out.println("<div id=\"rightside\" class=\"column small\">");
try {
    // Local menu for "personal pages". VERY rarely used, but a couple of 
    // employees have opted in.
    cms.include("/system/modules/no.npolar.site.npweb/elements/personal-menu.jsp");
} catch (Exception ignore) {}

out.println("</div><!-- #rightside -->");

cms.include(T, T_ELEM[1], T_EDIT);
%>